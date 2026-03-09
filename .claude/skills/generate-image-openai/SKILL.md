---
name: generate-image-openai
description: Use when the user wants to generate, create, or make images using OpenAI/DALL-E/GPT image models. Triggers on requests like "generate an image", "create a picture", "make me an illustration", or any image creation task.
---

# OpenAI Image Generation

Generate images using OpenAI's GPT image models via the `generate_image` MCP tool. Images are saved directly to disk as PNG files.

## Usage

Call the `generate_image` tool (provided by the `openai-images` MCP server) with:

| Parameter | Required | Default | Options |
|-----------|----------|---------|---------|
| `prompt` | Yes | - | Text description of the image to generate |
| `output_dir` | No | current working directory | Path to save the image |
| `filename` | No | auto-generated from prompt | Custom filename (no extension) |
| `model` | No | `gpt-image-1.5` | `gpt-image-1.5` (fast), `gpt-image-1` (quality) |
| `size` | No | `auto` | `1024x1024`, `1536x1024`, `1024x1536`, `auto` |
| `quality` | No | `low` | `low`, `medium`, `high`, `auto` |

## Output

The tool saves a PNG file to disk and returns:
- File path where the image was saved
- File size in KB
- Model, quality, and dimensions used
- Revised prompt (if the model modified the input)

No scripts or subagents needed — the server handles file I/O directly.

## Models

- **gpt-image-1.5** (default) — Fast generation, good for iteration and drafts
- **gpt-image-1** — Higher quality output, use for final/polished images

## Prompt Tips

- Be specific about style: "watercolor", "photorealistic", "vector logo", "cyberpunk"
- Specify composition: "overhead shot", "close-up", "centered on white background"
- Include lighting/mood: "warm amber lighting", "moody cinematic", "bright and clean"
- For text/logos: explicitly state the text content and typography style

Iterate by adjusting the prompt and regenerating — no separate refine step.

## Setup

- MCP server: `~/.claude/mcp-servers/openai-images/server.js`
- API key: Set `OPENAI_API_KEY` in `~/.claude/.env`
- Registration: `claude mcp add` (user scope, stored in `~/.claude.json`)
