---
name: generate-image-openai
description: Use when the user wants to generate, create, or make images using OpenAI/DALL-E/GPT image models. Triggers on requests like "generate an image", "create a picture", "make me an illustration", or any image creation task.
---

# OpenAI Image Generation

Generate images using OpenAI's GPT image models via `.claude/scripts/generate-image.sh`. Images are saved directly to disk as PNG files.

## Usage

Run the script via Bash tool:

```bash
.claude/scripts/generate-image.sh "<prompt>" [output_dir] [filename] [model] [quality] [size]
```

| Parameter | Position | Default | Options |
|-----------|----------|---------|---------|
| `prompt` | 1 (required) | - | Text description of the image to generate |
| `output_dir` | 2 | current directory | Path to save the image |
| `filename` | 3 | auto-generated from prompt | Custom filename (no extension) |
| `model` | 4 | `gpt-image-1.5` | `gpt-image-1.5` (fast), `gpt-image-1` (quality) |
| `quality` | 5 | `low` | `low`, `medium`, `high`, `auto` |
| `size` | 6 | `auto` | `1024x1024`, `1536x1024`, `1024x1536`, `auto` |

## Output

The script saves a PNG file to disk and prints:
- File path where the image was saved
- File size in KB
- Model, quality, and dimensions used
- Revised prompt (if the model modified the input)

## Models

- **gpt-image-1.5** (default) -- Fast generation, good for iteration and drafts
- **gpt-image-1** -- Higher quality output, use for final/polished images

## Prompt Tips

- Be specific about style: "watercolor", "photorealistic", "vector logo", "cyberpunk"
- Specify composition: "overhead shot", "close-up", "centered on white background"
- Include lighting/mood: "warm amber lighting", "moody cinematic", "bright and clean"
- For text/logos: explicitly state the text content and typography style

Iterate by adjusting the prompt and regenerating -- no separate refine step.
