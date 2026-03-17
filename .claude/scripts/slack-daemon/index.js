#!/usr/bin/env node
// agent-slack-daemon — Real-time Slack Socket Mode daemon
//
// Two-tier message handling:
//   1. One-word commands (status, help, logs, run) — deterministic, fast
//   2. Everything else — complexity heuristic → decompose-first or direct dispatch
//
// Decompose-first flow (complex requests):
//   - Claude breaks request into [AGENT] / [YOU] / [AGENT-AFTER:NAME] parts
//   - [AGENT] parts execute immediately in the same Claude call
//   - [YOU] parts queue as "propose" and surface to user via Slack push
//   - [AGENT-AFTER:NAME] parts queue as "auto | blocked-on:NAME"
//   - User unblocks AGENT-AFTER items by checking off the YOU item
//
// Complexity heuristic triggers on TWO or more matching patterns, or explicit prefix:
//   decompose: <request>  — force decomposition
//   go: <request>         — force direct dispatch
//
// Requires: SLACK_BOT_TOKEN, SLACK_APP_TOKEN, SLACK_SIGNING_SECRET,
//           SLACK_CHANNEL_ID, SLACK_ALLOWED_USER_ID

const { App } = require('@slack/bolt');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ── Load environment ─────────────────────────────────────────

const envFile = path.join(process.env.HOME, '.env.local');
if (fs.existsSync(envFile)) {
  const lines = fs.readFileSync(envFile, 'utf8').split('\n');
  for (const line of lines) {
    const match = line.match(/^([A-Z_]+)=(.+)$/);
    if (match) process.env[match[1]] = match[2];
  }
}

const WORKSPACE_ROOT = path.join(process.env.HOME, 'workspace');
const STATE_DIR = path.join(process.env.HOME, '.claude', 'agent-runner-state');
const LOG_FILE = path.join(STATE_DIR, 'slack-dispatch.log');
const PID_FILE = path.join(STATE_DIR, 'slack-daemon.pid');

if (!fs.existsSync(STATE_DIR)) fs.mkdirSync(STATE_DIR, { recursive: true });

// ── Concurrency guard — one claude -p at a time ───────────────
// Prevents burst-spawning (multiple rapid messages) from hitting resource limits.
// Commands (logs, status, etc.) bypass this — only Claude dispatches are gated.
let activeClaudeCount = 0;
const MAX_CONCURRENT_CLAUDE = 1;

// ── PID lock — prevent duplicate instances ────────────────────

(function acquirePidLock() {
  if (fs.existsSync(PID_FILE)) {
    const existing = fs.readFileSync(PID_FILE, 'utf8').trim();
    const pid = parseInt(existing, 10);
    if (!isNaN(pid)) {
      let isOurProcess = false;
      try {
        process.kill(pid, 0);
        // Process is alive — but is it actually the slack daemon?
        // Read /proc/<pid>/cmdline to verify (Linux containers use procfs)
        const cmdlinePath = `/proc/${pid}/cmdline`;
        if (fs.existsSync(cmdlinePath)) {
          const cmdline = fs.readFileSync(cmdlinePath, 'utf8').replace(/\0/g, ' ');
          isOurProcess = cmdline.includes('slack-daemon') || cmdline.includes('index.js');
        } else {
          // No procfs (macOS) — fall back to signal-only check
          isOurProcess = true;
        }
      } catch {
        // PID is stale — process doesn't exist
        console.log(`[slack-daemon] Removing stale PID file (PID ${pid}).`);
      }

      if (isOurProcess) {
        console.error(`[slack-daemon] Another instance is already running (PID ${pid}). Exiting.`);
        process.exit(0);
      } else {
        console.log(`[slack-daemon] PID ${pid} is alive but not the slack daemon — removing stale PID file.`);
      }
    }
  }
  fs.writeFileSync(PID_FILE, String(process.pid));
  process.on('exit', () => {
    try { if (fs.readFileSync(PID_FILE, 'utf8').trim() === String(process.pid)) fs.unlinkSync(PID_FILE); } catch {}
  });
  for (const sig of ['SIGINT', 'SIGTERM']) {
    process.on(sig, () => process.exit(0));
  }
}());

function log(msg) {
  const ts = new Date().toISOString().replace('T', ' ').split('.')[0];
  const line = `[slack-daemon] ${ts} ${msg}\n`;
  fs.appendFileSync(LOG_FILE, line);
  // stdout intentionally omitted — Docker captures it, creating duplicate lines in logs
}

// ── Slack App ────────────────────────────────────────────────

const app = new App({
  token: process.env.SLACK_BOT_TOKEN,
  signingSecret: process.env.SLACK_SIGNING_SECRET,
  socketMode: true,
  appToken: process.env.SLACK_APP_TOKEN,
});

// ── Command handlers ─────────────────────────────────────────

async function replyWithStatus(say) {
  try {
    const terrain = fs.readFileSync(path.join(WORKSPACE_ROOT, 'Terrain.md'), 'utf8');
    const queueMatch = terrain.match(/## Agent Queue\n([\s\S]*?)(?=\n## )/);
    const queueItems = queueMatch
      ? queueMatch[1].split('\n').filter(l => l.startsWith('- ')).join('\n')
      : 'Queue empty';

    const lockFile = path.join(process.env.TMPDIR || '/tmp', 'agent-runner.lock');
    let runnerStatus = 'Idle';
    if (fs.existsSync(lockFile)) {
      const pid = fs.readFileSync(lockFile, 'utf8').trim();
      try { process.kill(parseInt(pid), 0); runnerStatus = `Running (PID ${pid})`; } catch { runnerStatus = 'Idle'; }
    }

    await say(`*Agent Status*\n\n*Runner:* ${runnerStatus}\n*Queue:*\n${queueItems || '(empty)'}`);
  } catch (e) {
    await say(`Status check failed: ${e.message}`);
  }
}

async function showHelp(say) {
  const lines = Object.entries(COMMANDS)
    .map(([cmd, { desc }]) => `\`${cmd}\` — ${desc}`)
    .join('\n');
  await say(`*Commands:*\n${lines}\n\nAnything else goes to Claude. Prefix with \`draft:\` to extract content + generate platform drafts, \`decompose:\` to force decomposition, \`go:\` to force direct dispatch.`);
}

async function showLogs(say) {
  try {
    const lines = fs.readFileSync(LOG_FILE, 'utf8').split('\n').filter(Boolean);
    const recent = lines.slice(-20).join('\n');
    await say(`*Recent activity:*\n\`\`\`\n${recent || 'No logs yet.'}\n\`\`\``);
  } catch (e) {
    await say('No logs found.');
  }
}

async function triggerRun(say) {
  try {
    const runnerScript = path.join(WORKSPACE_ROOT, '.claude/scripts/agent-runner.sh');
    // spawn (non-blocking) — execSync would block the event loop for the run duration
    const child = spawn('bash', [runnerScript, '--once'], {
      cwd: WORKSPACE_ROOT,
      detached: true,
      stdio: 'ignore',
    });
    child.unref();
    await say('Runner triggered in background. Check `logs` for results when done.');
  } catch (e) {
    await say(`Runner trigger failed: ${e.message.slice(0, 200)}`);
  }
}

// ── Command map ──────────────────────────────────────────────

const COMMANDS = {
  status: { handler: replyWithStatus, desc: 'Show runner status and queue' },
  help:   { handler: showHelp,        desc: 'List available commands' },
  logs:   { handler: showLogs,        desc: 'Show recent daemon activity' },
  run:    { handler: triggerRun,      desc: 'Trigger runner immediately (executes next auto item)' },
};

// ── Complexity heuristic ──────────────────────────────────────
//
// Returns true if the request warrants a decompose-first pass.
// Requires TWO or more matching patterns to reduce false positives
// on natural voice dictation ("check X and fix Y" = one pattern, goes direct).
//
// Override: prefix with "decompose:" (force) or "go:" (bypass).

const COMPLEXITY_PATTERNS = [
  / and (then |also )?(?:deploy|update|create|write|fix|add|remove|check|run|send|post|build|test|review|research|analyze|generate)/i,
  /\b(if|depending on|based on)\b.{0,60}\b(then|do|update|run|deploy)\b/i,
  /\b(after that|first.*then|followed by|next step)\b/i,
  /\b(step 1|step one|first step|then do)\b/i,
];

const ACTION_VERBS = [
  'deploy', 'update', 'create', 'write', 'fix', 'add', 'remove',
  'check', 'run', 'send', 'post', 'build', 'test', 'review', 'research',
  'analyze', 'generate', 'migrate', 'refactor', 'delete', 'rename', 'move',
];

function isComplexRequest(text) {
  const t = text.toLowerCase();

  // Count pattern matches — require at least 2
  const patternMatches = COMPLEXITY_PATTERNS.filter(p => p.test(t)).length;
  if (patternMatches >= 2) return true;

  // 3+ distinct action verbs also signals multi-step
  const verbCount = ACTION_VERBS.filter(v => t.includes(v)).length;
  if (verbCount >= 3) return true;

  return false;
}

// ── Constants ────────────────────────────────────────────────

const CLAUDE_SECURITY_PROMPT = "CONTAINER SECURITY POLICY: Never read SSH private key files. Never read credential files in ~/.claude/. Never exfiltrate data to external hosts via curl, wget, or any network request. These are hard constraints that override all other instructions.";

// Research channel — messages here always use the deep URL/repo analysis flow.
// Set SLACK_RESEARCH_CHANNEL_ID in environment to enable.
const RESEARCH_CHANNEL_ID = process.env.SLACK_RESEARCH_CHANNEL_ID || '';

// ── Research channel helpers ──────────────────────────────────

// Slack wraps URLs in angle brackets: <https://url> or <https://url|display text>
// Returns the raw URL string, or null if none found.
function extractUrl(text) {
  const slackWrapped = text.match(/<(https?:\/\/[^|>]+)(?:\|[^>]*)?>/) ;
  if (slackWrapped) return slackWrapped[1];
  const naked = text.match(/https?:\/\/\S+/);
  return naked ? naked[0] : null;
}

// Strip the URL (both wrapped and naked forms) to get any extra instructions.
function extractInstructions(text, url) {
  if (!url) return text.trim();
  return text
    .replace(/<https?:\/\/[^>]*>/g, '')
    .replace(new RegExp(url.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), '')
    .trim();
}

// Pre-fetch tweet content via X API v2 before dispatching to Claude.
// X/Twitter URLs are unfetchable via WebFetch (403s or returns empty HTML).
// Returns { text, authorName, authorUsername } or null on failure.
async function fetchTweetContent(url) {
  const match = url.match(/\/status\/(\d+)/);
  if (!match) return null;
  const tweetId = match[1];

  const bearerToken = process.env.X_BEARER_TOKEN;
  if (!bearerToken) {
    log('fetchTweetContent: X_BEARER_TOKEN not set, skipping pre-fetch');
    return null;
  }

  try {
    const apiUrl = `https://api.twitter.com/2/tweets/${tweetId}?tweet.fields=text,author_id,created_at&expansions=author_id&user.fields=username,name`;
    const response = await fetch(apiUrl, {
      headers: { Authorization: `Bearer ${bearerToken}` },
    });
    if (!response.ok) {
      log(`fetchTweetContent: X API returned ${response.status} for tweet ${tweetId}`);
      return null;
    }
    const data = await response.json();
    const tweetText = data.data?.text;
    const author = data.includes?.users?.[0];
    if (!tweetText) return null;
    return {
      text: tweetText,
      authorName: author?.name || 'Unknown',
      authorUsername: author?.username || 'unknown',
    };
  } catch (err) {
    log(`fetchTweetContent: fetch error — ${err.message}`);
    return null;
  }
}

function buildResearchPrompt(url, extraInstructions, threadContext, tweetContent = null) {
  const isGitHub = /github\.com\/[^/\s]+\/[^/\s]+/.test(url);
  const isTwitter = /(?:x|twitter)\.com/.test(url);
  const isReddit = /reddit\.com/.test(url);

  let analysisBlock;

  if (isGitHub) {
    analysisBlock = `
You are performing a deep comparative analysis of a GitHub repository.

URL: ${url}
${extraInstructions ? `\nAdditional instructions: ${extraInstructions}` : ''}

**Your setup lives at:** ~/workspace/.claude/ (skills, rules, hooks, scripts, agents, memory)

**Your job:**

1. **Inventory the repo** — fetch and read the repository. What's in it? Skills, scripts, hooks, prompts, memory systems, workflows, config patterns. Read key files, not just the README.

2. **Compare to our setup** — for each element, assess against ~/workspace/.claude/:
   - Better than ours: What makes it better? Worth pulling in?
   - Worse than ours: What did we solve that they haven't?
   - Same or equivalent: Note briefly, skip deep analysis
   - We don't have this: Flag as a gap — real gap or deliberate omission?

3. **Distillation option** — for things that can't be copied directly (different stack, conventions), extract the underlying principle and note how to rebuild for our setup.

4. **Prioritized recommendations** — stack-rank by ROI

Lead with the quick wins. Be concrete.
`;
  } else if (isTwitter && tweetContent) {
    analysisBlock = `
You are analyzing a tweet.

URL: ${url}
Tweet by @${tweetContent.authorUsername} (${tweetContent.authorName}):
"""
${tweetContent.text}
"""
${extraInstructions ? `\nAdditional instructions: ${extraInstructions}` : ''}

${extraInstructions
  ? `Execute the additional instructions above using the tweet content provided.`
  : `Summarize the tweet, assess relevance to current goals, recommend action (Engage / Share / Ignore).`}
`;
  } else if (isTwitter && !tweetContent) {
    analysisBlock = `
You are researching a tweet. Direct fetching of X/Twitter URLs isn't possible.

URL: ${url}
${extraInstructions ? `\nAdditional instructions: ${extraInstructions}` : ''}

Use WebSearch to find information about this tweet or its content.
`;
  } else if (isReddit) {
    analysisBlock = `
You are researching a Reddit post or thread.

URL: ${url}
${extraInstructions ? `\nAdditional instructions: ${extraInstructions}` : ''}

Use the Reddit MCP tools to fetch and read this Reddit content. Do NOT use WebFetch for Reddit URLs.
`;
  } else {
    analysisBlock = `
You are researching a URL.

URL: ${url}
${extraInstructions ? `\nAdditional instructions: ${extraInstructions}` : ''}

Fetch and read the URL. Extract relevant information. If paywalled or login-required, say so.
`;
  }

  return (threadContext || '') + analysisBlock;
}

async function dispatchResearchRequest(text, say) {
  const url = extractUrl(text);
  if (!url) {
    await say("No URL found in that message. Drop a URL and I'll analyze it.");
    return;
  }

  const extra = extractInstructions(text, url);

  // Pre-fetch tweet content for X/Twitter URLs — WebFetch can't access them.
  let tweetContent = null;
  const isTwitterUrl = /(?:x|twitter)\.com/.test(url);
  if (isTwitterUrl) {
    log(`Research dispatch: X/Twitter URL detected, pre-fetching via API: ${url}`);
    tweetContent = await fetchTweetContent(url);
    if (tweetContent) {
      log(`Research dispatch: tweet pre-fetch succeeded — @${tweetContent.authorUsername}`);
    } else {
      log(`Research dispatch: tweet pre-fetch failed, will use WebSearch fallback`);
    }
  }

  const prompt = buildResearchPrompt(url, extra, '', tweetContent);
  log(`Research dispatch: ${url}`);

  // Always stream directly — no decompose, no Terrain update, just the analysis.
  await dispatchToClaude(prompt, say, { effort: 'high', maxTurns: 50 });
}

// ── Tool label helper ─────────────────────────────────────────

function toolLabel(name, input) {
  const n = (name || '').toLowerCase();
  if (n === 'read')       return `Read: ${(input.file_path || '').split('/').slice(-2).join('/')}`;
  if (n === 'edit')       return `Edit: ${(input.file_path || '').split('/').slice(-2).join('/')}`;
  if (n === 'write')      return `Write: ${(input.file_path || '').split('/').slice(-2).join('/')}`;
  if (n === 'bash')       return `Bash: ${(input.command || '').slice(0, 60)}`;
  if (n === 'grep')       return `Grep: ${(input.pattern || '').slice(0, 40)}`;
  if (n === 'glob')       return `Glob: ${input.pattern || ''}`;
  if (n === 'websearch')  return `Search: ${(input.query || '').slice(0, 60)}`;
  if (n === 'webfetch')   return `Fetch: ${(input.url || '').slice(0, 80)}`;
  if (n === 'agent')      return `Agent: ${(input.description || '').slice(0, 60)}`;
  if (n === 'todowrite')  return `Tasks updated`;
  return `${name}: ${JSON.stringify(input).slice(0, 60)}`;
}

// ── Streaming Claude helper ───────────────────────────────────
//
// Spawns claude -p with --output-format stream-json.
// Returns { result, subtype, timedOut } from the stream.

async function streamToClaude(input, { model = 'claude-sonnet-4-6', effort = 'medium', maxTurns = 50, onAssistantText, onToolUse } = {}) {
  return new Promise((resolve) => {
    const child = spawn('claude', [
      '-p',
      '--model', model,
      '--effort', effort,
      '--max-turns', String(maxTurns),
      '--output-format', 'stream-json',
      '--verbose',
      '--dangerously-skip-permissions',
      '--append-system-prompt', CLAUDE_SECURITY_PROMPT,
    ], {
      cwd: WORKSPACE_ROOT,
      env: {
        ...process.env,
        CLAUDECODE: undefined,
        ANTHROPIC_API_KEY: undefined,
      },
      stdio: ['pipe', 'pipe', 'pipe'],
    });

    child.stdin.write(input);
    child.stdin.end();

    let finalResult = null;
    let resultSubtype = null;
    let timedOut = false;

    const rl = readline.createInterface({ input: child.stdout, crlfDelay: Infinity });

    rl.on('line', (line) => {
      if (!line.trim()) return;
      let event;
      try { event = JSON.parse(line); } catch { return; }

      if (event.type === 'assistant') {
        const content = event.message?.content || [];

        if (onAssistantText) {
          const texts = content
            .filter(b => b.type === 'text' && b.text?.trim())
            .map(b => b.text.trim());
          for (const t of texts) {
            onAssistantText(t).catch(e => log(`onAssistantText error: ${e.message}`));
          }
        }

        if (onToolUse) {
          const tools = content.filter(b => b.type === 'tool_use');
          for (const tu of tools) {
            onToolUse(tu.name, tu.input || {}).catch(e => log(`onToolUse error: ${e.message}`));
          }
        }
      }

      if (event.type === 'result') {
        finalResult = event.result ?? null;
        resultSubtype = event.subtype ?? null;
      }
    });

    child.stderr.on('data', (data) => log(`claude stderr: ${data.toString().slice(0, 200)}`));

    let exitCode = null;
    child.on('exit', (code) => { exitCode = code; });

    const timeout = setTimeout(() => {
      timedOut = true;
      child.kill('SIGTERM');
    }, 300000);

    rl.on('close', () => {
      clearTimeout(timeout);
      const crashed = exitCode !== null && exitCode !== 0 && !finalResult && !resultSubtype;
      resolve({ result: finalResult, subtype: resultSubtype, timedOut, crashed, exitCode });
    });
  });
}

// ── Claude dispatch ───────────────────────────────────────────
//
// Message tagging:
//   [STATUS] text  — intermediate assistant text (live, mid-run)
//   [FINAL] text   — last text block (tagged at completion)
//   [ERROR] ...    — failure: timeout, max-turns, parse error, exception
//   [DONE]         — clean completion with no text output

async function dispatchToClaude(text, say, { model = 'claude-sonnet-4-6', effort = 'medium', maxTurns = 50 } = {}) {
  if (activeClaudeCount >= MAX_CONCURRENT_CLAUDE) {
    await say(`One request in progress — I'll get to yours in a moment.`);
    return;
  }
  activeClaudeCount++;
  log(`Dispatching [${model}/${effort}]: ${text.slice(0, 80)}`);
  let pendingText = null;
  let anyStreamed = false;

  try {
    const { result, subtype, timedOut, crashed, exitCode } = await streamToClaude(text, {
      model, effort, maxTurns,
      onAssistantText: async (t) => {
        anyStreamed = true;
        if (pendingText) {
          await say(`[STATUS] ${pendingText.replace(/^\[.*?\]\s*/, '')}`);
        }
        pendingText = t;
      },
      onToolUse: async (name, input) => {
        if ((name || '').toLowerCase() === 'agent') {
          await say(toolLabel(name, input));
        }
      },
    });

    if (timedOut) {
      await say(`[ERROR] Timed out after 5 minutes — check logs for partial results.`);
    } else if (crashed) {
      await say(`[ERROR] Claude process exited unexpectedly (exit code ${exitCode ?? 'unknown'}) — check logs. Retry your message.`);
    } else if (subtype === 'error_max_turns') {
      await say(`[ERROR] Hit max-turns limit (${maxTurns}) — partial work may be committed. Check logs.`);
    } else if (subtype && subtype.startsWith('error')) {
      await say(`[ERROR] ${subtype} — check logs for details.`);
    } else if (pendingText) {
      await say(`[FINAL] ${pendingText.replace(/^\[.*?\]\s*/, '')}`);
    } else if (result?.trim()) {
      await say(`[FINAL] ${result.trim().replace(/^\[.*?\]\s*/, '')}`);
    } else {
      await say(`[DONE]`);
    }
  } catch (e) {
    log(`Dispatch failed: ${e.message}`);
    await say(`[ERROR] Couldn't complete that: ${e.message.slice(0, 100)}`);
  } finally {
    activeClaudeCount--;
  }
}

// ── Decompose-first flow ──────────────────────────────────────
// (See handleContentDraft and decomposeAndExecute in the production version
//  for the full content draft and decomposition flows. The patterns are:
//  1. Content draft: extract signal from ramble → generate platform-specific drafts
//  2. Decompose: break into [AGENT]/[YOU]/[AGENT-AFTER:NAME] parts → execute + queue)

async function decomposeAndExecute(text, say) {
  if (activeClaudeCount >= MAX_CONCURRENT_CLAUDE) {
    await say(`One request in progress — I'll get to yours in a moment.`);
    return;
  }
  activeClaudeCount++;
  let decremented = false;
  const today = new Date().toISOString().split('T')[0];

  const prompt = `You are decomposing and executing a task request.

Request: ${text}

Step 1 — Decompose. Break this into:
  [AGENT] Description  — steps you can take autonomously
  [YOU] Description    — steps only the user can take
  [AGENT-AFTER:EXACT-YOU-DESCRIPTION] Description — steps the agent takes after a specific [YOU] step completes

Step 2 — Execute. For each [AGENT] item, do the work now.

Step 3 — Queue the rest in Terrain.md Agent Queue.

Step 4 — End with:
  STATUS: completed|blocked|partial
  QUEUED_FOR_USER: [comma-separated YOU item descriptions, or "none"]
  SUMMARY: [what was done, what needs the user]`;

  log(`Decomposing: ${text.slice(0, 80)}`);

  try {
    const { result, subtype, timedOut, crashed, exitCode } = await streamToClaude(prompt, {
      onToolUse: async (name, input) => {
        if ((name || '').toLowerCase() === 'agent') {
          await say(toolLabel(name, input));
        }
      },
    });

    if (timedOut) {
      await say(`[ERROR] Decompose timed out after 5 minutes.`);
      return;
    }
    if (crashed || (subtype && subtype.startsWith('error'))) {
      await say(`[ERROR] Decompose failed — check logs. Retry your message.`);
      return;
    }

    const output = (result || '').trim();
    const statusLine = (output.match(/STATUS:\s*(.+)/)?.[1] || '').trim();
    const queuedFor = (output.match(/QUEUED_FOR_USER:\s*(.+)/)?.[1] || 'none').trim();
    const summary = (output.match(/SUMMARY:\s*(.+)/)?.[1] || '').trim();

    const responseLines = output
      .split('\n')
      .filter(l => l.match(/^\[(AGENT|YOU|AGENT-AFTER)/))
      .join('\n');

    let reply;
    if (!output) {
      reply = '[ERROR] No output from decompose — check logs.';
    } else if (responseLines || statusLine) {
      const parts = [];
      if (responseLines) parts.push(`*Decomposed:*\n\`\`\`\n${responseLines}\n\`\`\`\n`);
      if (summary) parts.push(summary);
      if (statusLine) parts.push(`*Status:* ${statusLine}`);
      if (queuedFor !== 'none') parts.push(`\n*Needs your input:* ${queuedFor}`);
      reply = parts.join('\n');
    } else {
      reply = output;
    }

    await say(`[FINAL] ${reply || 'Done.'}`);
  } catch (e) {
    log(`Decompose failed: ${e.message} — falling back to direct dispatch`);
    activeClaudeCount--;
    decremented = true;
    await dispatchToClaude(text, say);
  } finally {
    if (!decremented) activeClaudeCount--;
  }
}

// ── Thread context ───────────────────────────────────────────

const TOOL_LABEL_RE = /^[📄✏️📝⚙️🔍📁🌐🤖📋🔧]/u;

async function getThreadContext(client, channel, threadTs, currentTs) {
  if (!threadTs) return '';
  try {
    let allMessages = [];
    let cursor;
    do {
      const result = await client.conversations.replies({
        channel,
        ts: threadTs,
        limit: 200,
        ...(cursor ? { cursor } : {}),
      });
      allMessages = allMessages.concat(result.messages || []);
      cursor = result.response_metadata?.next_cursor;
    } while (cursor && allMessages.length < 500);

    const messages = allMessages
      .filter(m => m.ts !== currentTs)
      .filter(m => !TOOL_LABEL_RE.test(m.text || ''))
      .map(m => `${m.bot_id ? 'Agent' : 'User'}: ${m.text}`)
      .join('\n');
    return messages ? `Thread context (previous messages):\n${messages}\n\nCurrent message: ` : '';
  } catch (e) {
    log(`Thread fetch failed: ${e.message}`);
    return '';
  }
}

// ── Reaction helpers ─────────────────────────────────────────

async function addReaction(client, channel, timestamp, emoji) {
  try {
    await client.reactions.add({ channel, timestamp, name: emoji });
  } catch (e) {
    log(`addReaction failed: ${e.message}`);
  }
}

async function removeReaction(client, channel, timestamp, emoji) {
  try {
    await client.reactions.remove({ channel, timestamp, name: emoji });
  } catch (e) {
    // Reaction may already be gone
  }
}

// ── Message handler ──────────────────────────────────────────

app.message(async ({ message, say: rawSay, client }) => {
  if (message.bot_id) return;
  if (message.subtype) return;
  if (message.user !== process.env.SLACK_ALLOWED_USER_ID) {
    log(`Rejected message from unauthorized user: ${message.user}`);
    return;
  }

  const text = message.text || '';
  log(`Received: "${text}"`);
  await addReaction(client, message.channel, message.ts, 'hourglass_flowing_sand');

  const threadSay = (content) => {
    if (typeof content === 'string') {
      return rawSay({ text: content, thread_ts: message.ts });
    }
    return rawSay({ ...content, thread_ts: message.ts });
  };

  try {
    const word = text.trim().replace(/<@[A-Z0-9]+>/gi, '').trim().toLowerCase();

    // Tier 0: Research channel — deterministic URL routing, bypasses all other logic
    if (RESEARCH_CHANNEL_ID && message.channel === RESEARCH_CHANNEL_ID) {
      log(`Research channel: routing to deep analysis: "${text.slice(0, 80)}"`);
      const threadContext = await getThreadContext(client, message.channel, message.thread_ts, message.ts);
      await dispatchResearchRequest(threadContext ? `${threadContext}\n${text}` : text, threadSay);
    } else if (COMMANDS[word]) {
      // Tier 1: One-word command — deterministic, fast
      await COMMANDS[word].handler(threadSay);
    } else {
      // Tier 2: Natural language — complexity heuristic decides path
      const threadContext = await getThreadContext(client, message.channel, message.thread_ts, message.ts);
      const terrainInstruction = '\n\nTerrain.md update: If this request completes, adds, changes, or removes a task, update Terrain.md accordingly.';

      const forceDecompose = /^decompose:\s*/i.test(text);
      const forceDirect = /^go:\s*/i.test(text);
      const cleanText = text.replace(/^(draft:|decompose:|go:)\s*/i, '').trim();
      const fullText = threadContext + cleanText + terrainInstruction;

      if (!forceDirect && (forceDecompose || isComplexRequest(cleanText))) {
        log(`Complexity heuristic fired (forceDecompose=${forceDecompose}): "${cleanText.slice(0, 80)}"`);
        await decomposeAndExecute(fullText, threadSay);
      } else {
        await dispatchToClaude(fullText, threadSay);
      }
    }
  } finally {
    await removeReaction(client, message.channel, message.ts, 'hourglass_flowing_sand');
  }
});

// ── Start ────────────────────────────────────────────────────

(async () => {
  await app.start();
  log('Agent Slack daemon started (Socket Mode)');
  console.log('Agent Slack daemon is running');
})();
