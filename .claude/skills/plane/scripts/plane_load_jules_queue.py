#!/usr/bin/env python3
"""
Load Jules Queue items from Terrain.md into Plane as work items.

One-shot script for Phase 1.5A of Plane evaluation.
Creates items, assigns to modules, sets labels.

Usage:
    PLANE_API_KEY=... python3 plane_load_jules_queue.py              # dry-run
    PLANE_API_KEY=... python3 plane_load_jules_queue.py --apply       # create items
"""

import json
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))
from plane_api import api, project_url, PROJECT_ID, USER_ID

DRY_RUN = "--apply" not in sys.argv

# UUIDs from live workspace
STATES = {
    "backlog": "53fc9178-b151-4874-8bc7-e9bdb25b373d",
    "todo": "990cc942-7d13-4a16-be13-49321015ffb3",
    "in_progress": "7cbfb936-0113-49cc-9575-d33df25c5c4f",
    "done": "15a09622-a81f-4ad3-b748-b5d0701d10d3",
}

LABELS = {
    "[your-name]": "e5ccbcaf-5cf9-4b6b-87cc-84b3593ffd5c",
    "jules-auto": "f38bfd28-7570-4ca9-b79f-0f8d5882a161",
    "jules-interactive": "49bd956c-e6c9-4dba-a07f-6db82d32e3ca",
    "decision-needed": "c58bed1c-79af-4de5-9ae0-fed991afdef8",
    "deferred": "2ddde859-d926-4e04-87b9-f4a3eb543ceb",
}

MODULES = {
    "content": "dd14e51c-691d-4b6d-9cc0-19eddd8d394b",
    "infrastructure": "c268f3b5-d7a6-4110-8b19-51e5da0ecc2a",
    "flourishing": "d2ff1ba0-8591-43a5-b88f-90c4f46acdf7",
    "jules-public": "ed65fdbc-282c-4bb6-b5c9-347db8cde6dc",
    "rebrand": "26c433ce-069e-4f76-a5c6-4a154e595647",
    "collaboration": "c0b384b4-2aa9-4d09-9b14-f29164920f14",
}

# Jules Queue items parsed from Terrain.md
# Format: (jq_id, title, description_html, module_or_none, labels, state, priority, start_date)
ITEMS = [
    # --- Content Pipeline ---
    ("JQ-2", "Update operational docs for [your-domain]",
     "<p>Update Terrain projects table, WorkProducts.md, Social-Strategy.md, Content-Queue.md, Published-URLs.md with site as canonical source.</p><p><strong>Est:</strong> 15m | <em>Queued 2026-03-15</em></p>",
     "content", ["jules-auto"], "todo", "low", None),

    ("JQ-3", "Monitor content-expand.sh quality",
     "<p>First run 2026-03-14 at 4 AM. Check draft quality after 1 week. If poor, pivot to wrap-up writing fuller drafts interactively.</p><p><em>Queued 2026-03-13, overdue</em></p>",
     "content", ["jules-auto"], "todo", "medium", None),

    ("JQ-4", "Move 6 published articles to 04-Published/",
     "<p>Articles with <code>published.md</code> still in <code>01-Drafts/</code>: AI-Decision-Making, Morning-Briefing, Personality, What-I-Actually-Do, Slot-Machine-Brain, Value-Stack-Ascent.</p><p><strong>Est:</strong> 10m | <em>Queued 2026-03-21</em></p>",
     "content", ["jules-auto"], "todo", "low", None),

    ("JQ-5", "Write infrastructure migration article X/Reddit variants",
     "<p>v5 published on [your-domain] + LinkedIn. Adverbs resolved (kept both). \"What I Learned\" structural rewrite done. Remaining: draft X thread + Reddit variants.</p><p><strong>Est:</strong> 20m | <em>Queued 2026-03-23</em></p>",
     "content", ["jules-auto"], "todo", "medium", None),

    ("JQ-6", "Content pipeline quality audit",
     "<p>Review entire content pipeline (drafts, seeds, research reports, engagement data). Rank by: tangible code samples, specific guidance from real use, pressure-tested findings. Propose one-article-per-week publishing order. Kill low-quality backlog items.</p><p><strong>Est:</strong> 60m | <em>Queued 2026-03-23</em></p>",
     "content", ["jules-auto"], "todo", "high", None),

    ("JQ-7", "Compile article approval list for site migration",
     "<p>List all articles marked \"published\" with titles, URLs, and engagement data. Flag kink articles for exclusion. [Your Name] approves which ones migrate to [your-domain]. Pre-step for bulk migration.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-23</em></p>",
     "content", ["jules-auto"], "todo", "medium", None),

    ("JQ-8", "Review + approve 3 Phase 8 drafts",
     "<p>[Your Name] reads \"My AI Agrees With Everything\", \"Thinking Toolkit\", \"Multi-Agent Systems\". Move approved to <code>02-Pending-Review/</code>. Article 1 has placeholder URLs to verify.</p><p><strong>Est:</strong> 20m | <em>Queued 2026-03-23</em></p>",
     "content", ["[your-name]"], "todo", "medium", None),

    ("JQ-9", 'Article 4: "27 Plugins, Zero Survived"',
     "<p>Full plugin lifecycle from the System Evolution Tracker. Story 1.</p><p><strong>Est:</strong> 45m | <strong>Blocked on:</strong> Approve content strategy direction | <em>Queued 2026-03-22</em></p>",
     "content", ["jules-auto"], "backlog", "medium", None),

    ("JQ-10", "Create Content-Strategy-2026.md",
     "<p>Formalize approved approach: principles, platform roles, cadence, quality bar, content structure template. Source from plan file.</p><p><strong>Est:</strong> 20m | <em>Queued 2026-03-22</em></p>",
     "content", ["jules-auto"], "todo", "medium", None),

    ("JQ-11", "Rewrite Content Sprint plan (quality-first)",
     "<p>Replace \"flush 8 articles\" framing with \"one killer piece every 1-2 weeks\" approach. Add content quality checklist. Adjust <code>Grand-Plan/1-Content-Sprint.md</code>.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-22</em></p>",
     "content", ["jules-auto"], "todo", "medium", None),

    # --- Infrastructure ---
    ("JQ-12", "Fix stale domain refs in scripts",
     "<p><code>quiz-health-monitor.sh</code> checks <code>quiz.[previous-domain]</code>, <code>validate-utm-tags.sh</code> validates <code>[previous-domain]</code> URLs. Both need [your-app].app.</p><p><strong>Est:</strong> 15m | <em>Queued 2026-03-21</em></p>",
     "infrastructure", ["jules-auto"], "todo", "low", None),

    ("JQ-13", "Pre-migration PoC: Cloud task push + quota test",
     "<p>Run proof-of-concept Cloud task: test direct-to-main push, quota limits, push conflict behavior, runtime ceiling. Required before any migration work.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-23</em></p>",
     "infrastructure", ["jules-interactive"], "todo", "medium", None),

    ("JQ-14", "Integrate claude-code-safety-net v0.8.2",
     "<p>Evaluate and install. Whitelist .claude/ paths, Downloads, /tmp.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-25</em></p>",
     "infrastructure", ["jules-auto"], "todo", "medium", None),

    ("JQ-15", "Populate Plane MCP tools catalog",
     "<p>Catalog 95 MCP tools in <code>references/mcp-tools.md</code>. Test tier-gated features (epics, initiatives, milestones). Low priority.</p><p><strong>Est:</strong> 15m | <em>Queued 2026-03-26</em></p>",
     "infrastructure", ["jules-auto"], "backlog", "low", None),

    ("JQ-16", "Monitor routing pipeline compliance",
     "<p>Watch first 5 real Advisory/Scope requests in new sessions. Check: numbered tags present, skill invocations firing, write-first on thin input. Cross-session research pickup (Test 10) also needs validation.</p><p>Spec: <code>Documents/Field-Notes/Plans/2026-03-24-Request-Routing-System-Spec.md</code> | <em>Queued 2026-03-24</em></p>",
     "infrastructure", ["jules-interactive"], "todo", "medium", None),

    ("JQ-17", "Add simplification + plugin phases to Infrastructure Sprint",
     "<p>Phase 4.5: simplification/alternatives audit. Phase 5: reusable skills/agents plugin architecture research. Update <code>Grand-Plan/2-Infrastructure.md</code>.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-22</em></p>",
     "infrastructure", ["jules-auto"], "todo", "medium", None),

    ("JQ-18", "Self-healing infrastructure (Phase 6)",
     "<p>Three-layer architecture: job-wrapper.sh → job-watchdog.sh → trigger-healing.sh. Plan: <code>2026-03-21-Self-Healing-Container-Jobs.md</code>. Tasks P6-6A through P6-6E.</p><p><strong>Est:</strong> 120m | <em>Queued 2026-03-22</em></p>",
     "infrastructure", ["jules-auto"], "todo", "high", None),

    ("JQ-19", "Feedback loop sensors (Phase 10)",
     "<p>Session signals, improvement tracking IDs, decision card IDs, plan registry, docs freshness, skill usage. Tasks P10-10A through P10-10F.</p><p><strong>Est:</strong> 4h | <em>Queued 2026-03-23</em></p>",
     "infrastructure", ["jules-auto"], "todo", "high", None),

    ("JQ-20", "Feedback loop actuators (Phase 11)",
     "<p>Self-improvement pipeline, cross-session patterns, personal development loop, skill audit, skill health, smoke tests. Tasks P11-11A through P11-11F.</p><p><strong>Est:</strong> 9h | <strong>Blocked on:</strong> Phase 10 sensors producing 1-2 weeks of data | <em>Queued 2026-03-23</em></p>",
     "infrastructure", ["jules-auto"], "backlog", "medium", None),

    ("JQ-21", "LLM Council pattern (Phase 14)",
     "<p>Cold advisory review → rebuttal round → council mode. Start with P14-14A (cold advisory review, est:45m). Inspired by Grok 4.20 multi-agent debate. Plan: <code>~/.claude/plans/linked-brewing-pancake.md</code>.</p><p><strong>Est:</strong> 2h15m | <em>Queued 2026-03-24</em></p>",
     "infrastructure", ["jules-auto"], "todo", "medium", None),

    ("JQ-22", "Grand System Assessment Phase 2: dispatch P2-2A through P2-2D",
     "<p>Health checks batch. Auto-dispatchable. Plan: <code>Grand-Plan/2-Infrastructure.md</code>.</p><p><strong>Est:</strong> 2.5h | <em>Approved 2026-03-23</em></p>",
     "infrastructure", ["jules-auto"], "todo", "medium", None),

    ("JQ-23", "On-demand hooks pattern",
     "<p>Build <code>/careful</code> (tightens bash safety guard) and <code>/focus &lt;dir&gt;</code> (restricts edits to specified directory) as proof-of-concept skills with on-demand hooks. Pattern from Thariq's skills article.</p><p><strong>Est:</strong> 1-2h | <em>Queued 2026-03-21</em></p>",
     "infrastructure", ["jules-interactive"], "backlog", "low", None),

    ("JQ-24", "Playgrounds visual iteration",
     "<p>Investigate Thariq's playground pattern (self-contained HTML files for visual iteration). Try concept-map or design-playground template. Check if available as installable CC plugin.</p><p><strong>Est:</strong> 1-2h | <em>Queued 2026-03-21</em></p>",
     "infrastructure", ["jules-interactive"], "backlog", "low", None),

    ("JQ-25", "CLAUDE_PLUGIN_DATA investigation",
     "<p>Test <code>${CLAUDE_PLUGIN_DATA}</code> for persistent skill storage. Candidates: scout-techniques, reply-bot, content pipeline.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-21</em></p>",
     "infrastructure", ["jules-interactive"], "backlog", "low", None),

    ("JQ-26", "Subagent state files pattern",
     "<p>Have long-running subagents write intermediate state to files for recoverability. Dispatch system already does this; gap is ad-hoc interactive subagent work. Low priority.</p><p><em>Queued 2026-03-21</em></p>",
     "infrastructure", ["jules-interactive"], "backlog", "low", None),

    # --- Rebrand ---
    ("JQ-27", "Scan social bios for stale domain refs",
     "<p>Check @[your-handle] (X), @builtwithjules (X), Reddit, [your-domain], LinkedIn for [previous-domain] or old branding. Google Search Console and Proton Mail already handled.</p><p><strong>Est:</strong> 15m | <em>Queued 2026-03-23</em></p>",
     "rebrand", ["jules-auto"], "todo", "low", None),

    ("JQ-28", "Quiz policy pages brand swap",
     "<p>React components (<code>PrivacyPolicy.tsx</code>, <code>TermsOfService.tsx</code>, <code>EducationDisclaimer.tsx</code>) still say \"[Previous Brand].\" Swap to \"Kink Archetypes\" / <code>[your-app].app</code> / <code>legal@[your-app].app</code>. Markdown versions done.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-23, approved 2026-03-23</em></p>",
     "rebrand", ["jules-auto"], "todo", "medium", None),

    # --- Jules Public ---
    ("JQ-29", "Auto-enrich System Evolution [R] entries",
     "<p>First pass: use git blame/commit messages to fill in rationale for ~10 thin [R]-tagged entries in System-Evolution.md. [Your Name] reviews interesting ones later.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-23</em></p>",
     "jules-public", ["jules-auto"], "todo", "low", None),

    ("JQ-30", "Advisory Toolkit Plugin: research publishable skill packaging",
     "<p>Package the thinking toolkit (mental models, lenses, operations, advisory framework) as a publishable Claude Code skill or plugin. Brand/name TBD. Overlaps with Jules Public sprint J-A tracks.</p><p><strong>Est:</strong> 45m | <em>Queued 2026-03-23</em></p>",
     "jules-public", ["jules-auto"], "backlog", "medium", None),

    ("JQ-31", "Implement voice architecture: Option B",
     "<p>Set up Claude Project + file organization guide for voice sessions.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-23</em></p>",
     "jules-public", ["jules-auto"], "todo", "medium", None),

    ("JQ-32", "Goal Decomposition: pilot",
     "<p>Run <code>/decompose \"be a recognized voice in the AI builder community\"</code> (Altitude 1, Q2 Purpose goal). First real-world test.</p><p><em>Queued 2026-03-18, approved 2026-03-23</em></p>",
     "jules-public", ["jules-auto"], "todo", "medium", None),

    # --- Flourishing ---
    ("JQ-33", "Housing evaluation: research options",
     "<p>Three tracks: mobile home/trailer (cost savings), elsewhere in [your-city] (different neighborhoods), Silicon Valley move (meetup/speaking opportunities). Lease expires Sept 2026.</p><p><strong>Est:</strong> 2h | <em>Queued 2026-03-25</em></p>",
     "flourishing", ["[your-name]"], "todo", "high", None),

    ("JQ-34", "Speaker submissions: AgentCon + AI Tinkerers SF",
     "<p>Advisory session. [Your Name] writes ideas first, Jules provides ideas, iterate Q&amp;A. AgentCon Sessionize deadline <strong>Mar 31</strong>. AI Tinkerers SF demo proposal for Apr 11. AI Engineer World's Fair by Apr 12.</p><p><em>Updated 2026-03-26</em></p>",
     "flourishing", ["jules-interactive"], "todo", "urgent", "2026-03-27"),

    ("JQ-35", "Flourishing F1-1: open questions session",
     "<p>Gates Phase 2 of Flourishing sprint. Interactive thinking work.</p><p><em>Queued 2026-03-23</em></p>",
     "flourishing", ["jules-interactive"], "todo", "medium", None),

    # --- Collaboration ---
    ("JQ-36", "Project Collaboration System: scope session",
     "<p>Research complete. Ready for interactive <code>/scope</code> session. Report: <code>Field-Notes/2026-03-21-Collaboration-System-Research.md</code>.</p><p><em>Queued 2026-03-21, approved for scoping 2026-03-23</em></p>",
     "collaboration", ["jules-interactive"], "todo", "medium", None),

    # --- No module (cross-cutting / research / insurance) ---
    ("JQ-37", '"Auto" automated experimentation research (Karpathy)',
     "<p>Research Karpathy's \"Auto\" concept: AI-driven A/B testing loop. Goal: apply to quiz results page and other conversion points. Identify exact framework/name, open-source implementations, scope needed.</p><p><strong>Est:</strong> 60m | <strong>Blocked on:</strong> Before quiz improvements resume | <em>Queued 2026-03-22</em></p>",
     None, ["jules-auto", "deferred"], "backlog", "low", None),

    ("JQ-38", "SDLC autonomous dev lifecycle research",
     "<p>Landscape research complete (2026-03-22). Before building: deep read 18-agent autonomous workflow, scope <code>/ship</code> skill, add adversarial mode to <code>/codex-review</code>, draft spec steering doc template.</p><p><strong>Est:</strong> 3-4h | <strong>Blocked on:</strong> Before new product dev begins | <em>Queued 2026-03-22</em></p>",
     None, ["jules-auto", "deferred"], "backlog", "low", None),

    ("JQ-39", "Sign corrected insurance application + send to Hannah",
     "<p>PDF at <code>Insurance/.../Chubb-Application-Corrected-2026-03-26.pdf</code>. Attachments at <code>Attachments-PDF/</code>.</p><p><em>Queued 2026-03-26</em></p>",
     None, ["[your-name]"], "todo", "urgent", None),

    ("JQ-40", "Run 5-agent insurance validation prompt",
     "<p>Technical accuracy, factual consistency, app-to-attachment alignment, business identity, sensitive data scan.</p><p><strong>Est:</strong> 15m | <em>Queued 2026-03-26</em></p>",
     None, ["jules-auto"], "todo", "high", None),

    ("JQ-41", "Direct insurance applications to specialty carriers",
     "<p>Panel consensus: target Coalition + Lloyd's syndicates via Ashlin Hadden wholesale. Hartford/Hiscox standard will decline (adult content). Hiscox ClearTech possible for consulting carve-out.</p><p><em>Updated 2026-03-26</em></p>",
     None, ["[your-name]"], "todo", "high", None),

    ("JQ-42", "Engage Founder Shield",
     "<p>After Hannah's carrier list. Cross-reference to avoid duplicate submissions.</p><p><strong>Blocked on:</strong> Hannah carrier list | <em>Queued 2026-03-23</em></p>",
     None, ["[your-name]"], "backlog", "medium", None),

    # --- Visualization (Infrastructure) ---
    ("JQ-43", "Fix Excalidraw export pipeline (P12-12A)",
     "<p>Labels don't bind to containers, arrows missing. Three attempts failed. Need to reverse-engineer from a known-good .excalidraw file or use coleam00 Playwright renderer.</p><p><strong>Est:</strong> 2h | <em>Queued 2026-03-23</em></p>",
     "infrastructure", ["jules-interactive"], "todo", "medium", None),

    ("JQ-44", "Fix D2 render script path (P12-12C)",
     "<p><code>.claude/scripts/render-d2.sh:22</code> hardcodes wrong d2 path.</p><p><strong>Est:</strong> 5m | <em>Queued 2026-03-23</em></p>",
     "infrastructure", ["jules-auto"], "todo", "low", None),

    ("JQ-45", "Fix architecture diagram inaccuracies (P12-12E)",
     "<p>[Your Name] flagged issues with D2 diagram. Need specifics. Source: <code>Documents/diagrams/jules-architecture.d2</code>.</p><p><strong>Est:</strong> 30m | <em>Queued 2026-03-23</em></p>",
     "infrastructure", ["jules-interactive"], "todo", "medium", None),
]


def main():
    mode = "DRY RUN" if DRY_RUN else "LIVE"
    print(f"[load-jq] Jules Queue → Plane | Mode: {mode}")
    print(f"[load-jq] {len(ITEMS)} items to create\n")

    # Skip JQ-1 — already created via MCP
    items_to_create = ITEMS  # JQ-1 already created manually, starts at JQ-2

    created = []
    module_queue = {}  # module_id -> [issue_ids]

    for jq_id, title, desc, module, label_names, state, priority, start_date in items_to_create:
        full_title = f"{title} [{jq_id}]"
        label_ids = [LABELS[l] for l in label_names if l in LABELS]
        state_id = STATES.get(state, STATES["todo"])

        payload = {
            "name": full_title,
            "description_html": desc,
            "state": state_id,
            "labels": label_ids,
            "assignees": [USER_ID],
            "priority": priority,
        }
        if start_date:
            payload["start_date"] = start_date

        if DRY_RUN:
            print(f"  [dry-run] CREATE: {full_title[:70]}")
            if module:
                print(f"            → module: {module}")
            continue

        print(f"  CREATE: {full_title[:70]}")
        resp = api("POST", project_url("/issues/"), payload)
        issue_id = resp.get("id")

        if issue_id:
            created.append((jq_id, issue_id))
            if module and module in MODULES:
                module_id = MODULES[module]
                module_queue.setdefault(module_id, []).append(issue_id)
            seq = resp.get("sequence_id", "?")
            print(f"    → GP-{seq}")
        else:
            print(f"    ERROR: {json.dumps(resp)[:200]}")

    # Batch add to modules
    if not DRY_RUN and module_queue:
        print(f"\n[load-jq] Adding to modules...")
        for mod_id, issue_ids in module_queue.items():
            mod_name = [k for k, v in MODULES.items() if v == mod_id][0]
            print(f"  {mod_name}: {len(issue_ids)} items")
            # Plane module-issues endpoint accepts batch
            resp = api("POST", project_url(f"/modules/{mod_id}/module-issues/"),
                       {"issues": issue_ids})
            if "error" in resp:
                print(f"    ERROR: {json.dumps(resp)[:200]}")

    total = len(created) if not DRY_RUN else len(items_to_create)
    print(f"\n[load-jq] {'Would create' if DRY_RUN else 'Created'} {total} items")
    if not DRY_RUN:
        print(f"[load-jq] Module assignments: {sum(len(v) for v in module_queue.values())}")


if __name__ == "__main__":
    main()
