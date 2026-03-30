# Email HTML Best Practices

Email clients strip most modern CSS. Follow these rules when generating HTML emails directly (not via `build-digest-email.sh`).

- **No CSS gradients** — `linear-gradient()` is stripped by Gmail, Outlook, and most clients
- **Use table layout** — nested `<table role="presentation">` for structure, not `<div>`
- **Solid `background-color` on `<td>`** — the only reliable way to show colored bars/blocks
- **Inline styles only** — no `<style>` blocks, no classes
- **No `max-width` on inner elements** — use `width` on `<td>` instead
- **Progress/score bars** — use two adjacent `<td>` cells with percentage widths and solid background colors
- **`&nbsp;`** in empty cells — prevents email clients from collapsing zero-height cells
- **`line-height: 0; font-size: 0;`** on decorative cells — prevents unwanted spacing

## Note on `build-digest-email.sh`

The branded template in `build-digest-email.sh` includes a `<style>` block. This is intentional and Gmail-safe because the styles target standard elements (`h2`, `h3`, `ul`, `li`, `table`, etc.) within the template's container `<td>`. Gmail preserves `<style>` blocks that don't use classes or IDs.

The constraints above apply only when you're writing raw HTML directly, bypassing the markdown pipeline.
