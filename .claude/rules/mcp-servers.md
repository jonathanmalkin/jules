---
paths:
  - "**/mcp-servers/**"
  - "**/.config/mcp.json"
---

# MCP Servers

Custom MCP servers live in `~/.claude/mcp-servers/` -- Claude Code auto-discovers servers in this directory. Each subdirectory should be a symlink to the actual project repo (e.g., `openai-images` -> `~/your-workspace/Code/openai-images/`). Global MCP config is at `~/.config/mcp.json`.
