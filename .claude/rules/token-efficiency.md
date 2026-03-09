# Token Efficiency

## Bash Output Compression

When reporting bash command results, keep context lean:
- On clean exit (exit 0): report only the summary or final status line -- not the full output.
- On failure (non-zero exit): show the full output so the error can be diagnosed.
- For verbose commands (deploy scripts, npm install, docker build, test suites): extract the relevant result rather than dumping the entire log.

Note: The compression hook (`.claude/hooks/bash-compress-hook.sh`) handles 5 common commands automatically. This guideline covers everything else.

## Subagent Model Selection

Select the lightest model that handles the job well to preserve rate limit headroom:
- **Research, exploration, file search**: Use `model: "haiku"` -- lightest, preserves Opus/Sonnet capacity
- **Text synthesis, summaries, content generation**: Use Sonnet -- Haiku is too thin for quality synthesis
- **Code generation, complex analysis, planning**: Use Opus (default) only when needed
- When unsure, default to sonnet for anything involving writing, haiku for pure data gathering
