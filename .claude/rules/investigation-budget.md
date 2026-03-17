# Investigation Budget

## The Stopping Rule

When investigating a question, define the decision point upfront. Once the question is answered, stop investigating and present options. Don't keep digging into *why* unless understanding the mechanism is required to choose between solutions.

**Test:** "Do I need to understand the internals to pick the right approach, or can I present options now?" If you can present options, present them.

## Anti-Patterns

### Binary Reverse-Engineering
Never use `strings`, `hexdump`, or similar tools on compiled binaries (including the Claude Code binary) as a research method. Minified JS in compiled binaries does not give reliable semantic understanding. Results look informative but are misleading.

**Instead:** Test behavior directly, check official docs, search community solutions (GitHub issues, forums), or use WebSearch/WebFetch.

### Investigation → Implementation Without Approval
When a plan has multiple approaches (A, B, C), the investigation phase answers "which is feasible?" The answer triggers a Decision Card, not implementation. Don't build approach A while researching approach B.

### Massive-Output Commands
Before running a command, estimate its output size. `strings` on a 90MB binary, `cat` on a 10K-line file, unfiltered `grep` on a large codebase — these bloat context for minimal signal. If the output will be large, either:
1. Delegate to a subagent (context stays isolated)
2. Pipe through tight filters in the same command
3. Write output to a temp file and read specific sections

### Duplicating Delegated Research
If you launched a background agent to research X, don't manually research X while waiting. Either wait for the agent, or work on something unrelated.
