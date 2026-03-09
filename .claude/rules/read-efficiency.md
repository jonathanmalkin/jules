# Read Efficiency

- Before reading a file >200 lines, use Grep to find the relevant section, then Read with offset/limit.
- Never re-read a file already in context. If you need to check if it changed, use `git diff HEAD -- <file>`.
- For research requiring 3+ file reads, delegate to an Explore subagent.
- Browser automation (Chrome MCP) should always run in subagents -- screenshots are base64 context bombs (~100KB each).
