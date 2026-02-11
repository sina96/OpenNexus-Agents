---
description: Format files using available OpenCode formatters
agent: junior-coder
subtask: true
---

# Format Files

Format files using the formatters available in this repo: $ARGUMENTS

## Target Selection

If `$ARGUMENTS` is provided, use it to select files to format.

- Accept: file paths, directories, or glob patterns.
- For directories, format all files under them (skip `.git/`, `.opencode/`, `node_modules/`).

If no arguments are provided, identify changed code (staged + unstaged) via git:

- `git diff --name-only --cached`
- `git diff --name-only`

Deduplicate and ignore deleted/missing paths.

## Formatting Strategy

Prefer repo-native formatters as OpenCode would:

- Go: `gofmt -w <files>`
- Rust: `cargo fmt` (or `rustfmt <files>` when cargo is not available)
- Python: `ruff format <files>`
- JS/TS/JSON/MD/YAML/CSS/HTML: use `biome` when `biome.json(c)` exists; otherwise use `prettier` when available
- Shell: `shfmt -w <files>`
- C/C++/ObjC: `clang-format -i <files>`

If no formatter is available for a file type, leave it unchanged and report it.

## Output

Report:

- Which files were targeted
- Which formatter was used per group (and which were skipped)
- Any formatter errors (include key lines)
- `git diff --stat` after formatting
