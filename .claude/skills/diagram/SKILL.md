---
name: diagram
description: Generate diagrams from descriptions with visual iteration. Use when the user says "diagram", "draw a diagram", "make a flowchart", "architecture diagram", "sequence diagram", "workflow diagram", "system map", or wants a visual representation of architecture, flows, or processes. Supports Mermaid (.mmd) and D2 (.d2). Do NOT use for raster image generation (use generate-image-openai for that).
---

# Diagram Generation

Generate architecture, workflow, sequence, and flow diagrams. Both formats use topology-based syntax (Jules describes structure, layout engine positions everything). Render, inspect, and iterate 2-3 times before delivering.

## Critical: Iteration Loop

Every diagram goes through a render-inspect-refine cycle:

1. **Generate** the source file (.mmd or .d2)
2. **Render** to PNG (see render scripts below)
3. **View** the PNG with the Read tool (it displays images)
4. **Evaluate** — check for: overlapping labels, unreadable text, missing connections, awkward flow direction, cramped spacing
5. **Refine** the source and repeat from step 2
6. **Deliver** after 2-3 passes (or when it looks good)

## Format Selection

| Use case | Format | Why |
|----------|--------|-----|
| Flowcharts, sequence diagrams, simple workflows, Gantt charts | **Mermaid** (.mmd) | Claude knows the syntax cold. Quick to write. |
| Architecture diagrams (10+ nodes), complex system maps, grouped components | **D2** (.d2) | Handles scale better. Groups, icons, styling. Polished output. |

**Default to Mermaid** for most things. Use D2 when the diagram has many nodes, needs grouping/nesting, or the Mermaid output gets cramped.

## Render Scripts

```bash
# Mermaid -> PNG (via mermaid.ink API)
bash .claude/scripts/render-mermaid.sh <input.mmd> [output.png]

# D2 -> PNG (via D2 CLI + resvg-js)
bash .claude/scripts/render-d2.sh <input.d2> [output.png]

# Both: if output omitted, uses input path with .png extension
```

## Mermaid (.mmd)

### Syntax Quick Reference

```mermaid
%% Flowchart
graph TD
    A[Start] --> B{Decision}
    B -->|Yes| C[Action]
    B -->|No| D[Other Action]

%% Sequence
sequenceDiagram
    Client->>Server: Request
    Server-->>Client: Response

%% State
stateDiagram-v2
    [*] --> Active
    Active --> Inactive
```

### Tips
- Keep node labels short (wrap long text with `<br/>`)
- Use subgraphs for grouping: `subgraph Name ... end`
- Direction: `TD` (top-down), `LR` (left-right), `BT`, `RL`
- Style nodes: `style A fill:#f9f,stroke:#333`
- Breaks down visually at ~15+ nodes. Switch to D2.

## D2 (.d2)

D2 is topology-based like Mermaid but scales to larger diagrams. Jules describes connections, D2's layout engine positions everything.

### Syntax Quick Reference

```d2
# Simple connections
server -> database
server -> auth
auth -> database -> cache

# Labels on connections
server -> database: queries
server -> auth: validates

# Grouping with containers
backend: {
  server
  auth
  database
}
frontend: {
  web
  mobile
}
frontend.web -> backend.server

# Shapes and styles
database.shape: cylinder
cache.shape: cloud
server.style.fill: "#dae8fc"

# Direction
direction: right
```

### Tips
- Containers (groups) are defined with `name: { ... }`
- Shapes: `rectangle` (default), `cylinder`, `cloud`, `diamond`, `oval`, `hexagon`, `queue`, `page`
- Connections: `->` (directed), `--` (undirected), `<->` (bidirectional)
- Labels: `a -> b: label text`
- Direction: `direction: right` or `direction: down` (default)
- Icons: `icon: https://...` on any shape
- D2 syntax is less common in Claude's training data than Mermaid. If a syntax error occurs, simplify and try again.

## File Organization

- **Save diagrams alongside the documents they support.** No dedicated diagrams folder.
- Naming: `YYYY-MM-DD-Brief-Description.mmd` or `.d2`
- Keep the rendered `.png` next to the source file for easy sharing.
- If the user specifies a location, use that.

## Output

After delivering the final iteration, tell the user:
1. Where the files were saved (source + .png)
2. That they can edit the source in VS Code
3. How many iteration passes were done

## Examples

**User:** "diagram the quiz app architecture"
- Large system with multiple components -> D2 (containers for grouping)
- Save .d2 and .png alongside the project

**User:** "flowchart for the content pipeline"
- Linear flow -> Mermaid with render loop
- Save .mmd and .png in `Documents/Content-Pipeline/`

**User:** "sequence diagram for the deploy process"
- Sequence diagram -> always Mermaid (Mermaid excels at these)
- Render, inspect, refine, deliver
