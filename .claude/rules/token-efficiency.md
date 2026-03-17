# Token Efficiency

## Bash Output Compression

When reporting bash command results, keep context lean:
- On clean exit (exit 0): report only the summary or final status line — not the full output.
- On failure (non-zero exit): show the full output so the error can be diagnosed.
- For verbose commands (deploy scripts, npm install, docker build, test suites): extract the relevant result rather than dumping the entire log.

Note: The compression hook (`.claude/hooks/bash-compress-hook.sh`) handles 5 common commands automatically. This guideline covers everything else.

## Subagent Model Selection

We're on Claude Max. The constraint is capability fit and rate limits, not dollars. Select the lightest model that handles the job well to preserve rate limit headroom:
- **Research, exploration, file search**: Use `model: "haiku"` — lightest, preserves Opus/Sonnet capacity
- **Text synthesis, summaries, content generation**: Use Sonnet — Haiku is too thin for quality synthesis
- **Code generation, complex analysis, planning**: Use Opus (default) only when needed
- When unsure, default to sonnet for anything involving writing, haiku for pure data gathering

## Read Efficiency

- Before reading a file >200 lines, use Grep to find the relevant section, then Read with offset/limit.
- Never re-read a file already in context. If you need to check if it changed, use `git diff HEAD -- <file>`.
- For research requiring 3+ file reads, delegate to an Explore subagent.
- Browser automation (Chrome MCP) should always run in subagents -- screenshots are base64 context bombs (~100KB each).

## Tool Selection

For code navigation (jump to definition, find references, hover for type info), prefer LSP over Grep/Glob when you have a file path and line number. Grep/Glob for discovery, LSP for navigation.

## Skill-Level Model Guidance

When a skill is invoked and delegates work to a Task subagent, use the lightest model that can handle it:

| Skill | Haiku-safe tasks | Opus-required tasks |
|-------|-----------------|---------------------|
| **wrap-up** | All phases (commit, checklist, memory updates) | — |
| **generate-image-openai** | Prompt relay to MCP server | — (OpenAI does the heavy lifting) |
| **pdf** | Read, merge, split, rotate | OCR, form filling, complex extraction |
| **docx** | Simple reads, text extraction | Document creation with formatting |
| **xlsx** | Simple reads, column operations | Complex transforms, formula generation |
| **pptx** | Simple reads, text extraction | Deck creation from scratch |
| **proactive-research** | Doc lookups, API reference checks | Synthesis across multiple sources |
| **good-morning** | Memory synthesis, monitor | Briefing generation (Opus — date math, synthesis quality) |
