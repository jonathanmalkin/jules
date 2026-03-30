# Plane MCP Server Tools

MCP server: `plane-mcp-server` (from `makeplane/plane-mcp-server` PyPI package)

Tools are available as `mcp__plane__<tool_name>` in Claude Code sessions.

## Tool Catalog

> Populate after MCP server smoke test. Run `list_projects` to verify connection,
> then catalog available tools.

## Tier-Gated Features

The following may require Enterprise/paid tier. Test against live API:
- Epics (`list_epics`, `create_epic`, etc.)
- Initiatives (`list_initiatives`, etc.)
- Milestones (`list_milestones`, etc.)

If these return 404/403, remove from SKILL.md MCP-Handled Operations list.

## Known Limitations

- MCP server is Mac-only (interactive Claude Code sessions)
- Container sessions (Slack, cron) don't have MCP tools. Use gap scripts directly.
- Auth is injected at server start via `op run`. No live refresh.
