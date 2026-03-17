# FAQ Categories

12 categories for classifying Claude Code questions. Used by `/scout reply` mode to match posts to [Your Name]'s expertise areas.

| Category | Keywords / Patterns | Example Questions |
|----------|-------------------|-------------------|
| **Cost** | pricing, token usage, billing, credits, API costs, expensive, cheaper | "How much does Claude Code cost per month?" |
| **Memory** | CLAUDE.md, project memory, auto-memory, context persistence, remembering | "How do I get Claude to remember things across sessions?" |
| **Errors** | error messages, crashes, failures, unexpected behavior, broken | "Getting 'context window exceeded' randomly" |
| **Workflows** | plan mode, git integration, commit patterns, session management | "What's your workflow for large refactors?" |
| **Setup** | installation, configuration, first-time setup, permissions, getting started | "Just installed Claude Code, what should I configure first?" |
| **Hooks** | PreToolUse, PostToolUse, custom hooks, bash hooks, automation | "How do hooks work? Can I run linting automatically?" |
| **CLAUDE.md** | structure, best practices, what to put in, organization, rules | "What should I put in my CLAUDE.md?" |
| **Agents** | subagents, agent delegation, multi-agent, parallel tasks | "How do I use subagents for parallel work?" |
| **Permissions** | tool permissions, file access, security model, allow/deny | "How do I auto-approve certain tools?" |
| **MCP** | MCP servers, tool integration, custom tools, server setup | "How do I add an MCP server to Claude Code?" |
| **IDE** | VS Code, Cursor, editor integration, IDE comparison | "Should I use Claude Code in terminal or VS Code?" |
| **Skills** | custom skills, skill triggers, slash commands, SKILL.md | "How do I create a custom slash command?" |

## Scoring Guidance

- **Direct FAQ match (Relevance 3):** Question maps cleanly to one category and [Your Name] has documented experience
- **Adjacent (Relevance 2):** Question touches a category but is more general or combines multiple topics
- **Tangential (Relevance 1):** Claude-related but not about Claude Code specifically
- **Off-topic (Relevance 0):** Not about Claude Code at all, pricing complaints, "Claude vs GPT" debates
