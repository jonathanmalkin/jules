#!/usr/bin/env bash
# Launch plane-mcp-server with API key from 1Password service account token.
# Used by .mcp.json to start the MCP server process.
# Server reads PLANE_API_KEY and PLANE_WORKSPACE_SLUG from env (not CLI flags).
set -euo pipefail

export PLANE_API_KEY=$(op item get "Plane API" --vault "Dev Secrets" --fields label="API Key" --reveal)
export PLANE_WORKSPACE_SLUG="open-door-learning"
exec uvx --from plane-mcp-server plane-mcp-server
