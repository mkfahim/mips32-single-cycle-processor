# Visual Learning Materials

The diagrams in this directory are provided in two forms:

- `.mmd` files are Mermaid source and are easy to edit in code review.
- `.svg` files are committed exports that render directly on GitHub and in
  documentation tools.

The SVG files are intentionally simple and use labels that match the RTL.
They are not replacements for the source code; they are maps that help a new
reader know where to look.

## Included diagrams

| Diagram | Use it when learning |
| --- | --- |
| `cpu-overview` | Understanding how top-level modules connect |
| `instruction-cycle` | Learning fetch, decode, execute, and write-back |
| `addi-trace` | Tracing one instruction through actual signals |

If Mermaid is available locally, a source file can be rendered with:

```sh
npx --yes @mermaid-js/mermaid-cli \
  -i docs/diagrams/cpu-overview.mmd \
  -o docs/diagrams/cpu-overview.svg
```

The committed SVGs are the reviewable learning artifacts. Keep their labels
aligned with module and signal names in `rtl/`.
