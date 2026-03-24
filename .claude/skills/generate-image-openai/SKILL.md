---
name: generate-image-openai
description: Use when the user wants to generate, create, or make images using OpenAI/DALL-E/GPT image models. Triggers on requests like "generate an image", "create a picture", "make me an illustration", or any image creation task.
---

# OpenAI Image Generation — Iterative Workflow

Two-phase workflow: fast drafts for iteration, high-quality final render on approval.

**Cost per successful session:** ~$0.21 (3 draft iterations + 1 final render)

---

## Phase 1: Clarify Before Generating

Before touching the script, ask targeted questions to nail the prompt. Typical clarifiers:

- **Subject/scene:** What's in the image? Who or what is the focus?
- **Style:** Photorealistic, illustration, watercolor, vector, cinematic, cartoon?
- **Composition:** Wide shot, close-up, overhead, centered?
- **Mood/lighting:** Warm/cool, dramatic/bright, moody/clean?
- **Background:** Specific setting or transparent/solid color?
- **Text content:** Any words/labels to include?
- **Aspect ratio:** Square (1:1), landscape (3:2), portrait (2:3)?

Don't over-ask — 2-3 targeted questions if the prompt is ambiguous. Clear prompts skip directly to generation.

---

## Phase 2: Draft Iterations

**Model:** `gpt-image-1-mini` at `high` quality — fast (~10s), good quality, cheap ($0.052/image)

```bash
.claude/scripts/generate-image.sh "<prompt>" [output_dir] [filename]
# Uses defaults: model=gpt-image-1-mini, quality=high, size=auto
```

After each generation:
1. Read the saved PNG with the Read tool to view it
2. Assess against the user's intent — composition, style, accuracy
3. Note what's working and what needs refinement
4. Adjust the prompt and regenerate (target 2-3 iterations max)

If the draft is clearly far off (wrong style, wrong subject), surface that before burning more iterations — a prompt restart is cheaper than 3 bad drafts.

---

## Phase 3: Present for Approval

After 2-3 draft iterations, present to [Your Name]:
- Display the best draft
- Note what changed across iterations
- Identify any remaining gaps

**Two outcomes:**
- **Approved** → proceed to Phase 4 (final render)
- **Major changes needed** → restart from Phase 1 with new direction

---

## Phase 4: Final Render

On approval, generate the high-quality final:

```bash
.claude/scripts/generate-image.sh "<refined-prompt>" [output_dir] [filename] gpt-image-1 high
```

**Model options for final:**

| Model | Cost | Best for |
|-------|------|----------|
| `gpt-image-1` high | ~$0.167 | Highest OpenAI quality, transparent PNG support |
| `gpt-image-1-mini` high | $0.052 | When draft quality is already sufficient |

**Note:** Google `imagen-4.0-ultra` ($0.060) delivers better quality per dollar for final renders and supports 4K output — but requires a separate script (not yet implemented). OpenAI `gpt-image-1` is the current final-render default.

---

## Script Reference

```bash
.claude/scripts/generate-image.sh "<prompt>" [output_dir] [filename] [model] [quality] [size]
```

| Parameter | Default | Options |
|-----------|---------|---------|
| `prompt` | required | Text description |
| `output_dir` | current dir | Any path |
| `filename` | auto from prompt | Custom (no extension) |
| `model` | `gpt-image-1-mini` | `gpt-image-1-mini`, `gpt-image-1` |
| `quality` | `high` | `low`, `medium`, `high`, `auto` |
| `size` | `auto` | `1024x1024`, `1536x1024`, `1024x1536`, `auto` |

---

## Prompt Tips

- Style: "watercolor", "photorealistic", "vector logo", "cyberpunk", "flat illustration"
- Composition: "overhead shot", "close-up portrait", "centered on white background"
- Lighting: "warm amber lighting", "moody cinematic", "soft diffused light"
- Text: explicitly state the text content and typography style
- Negative space: "minimal", "clean background", "product on white"
