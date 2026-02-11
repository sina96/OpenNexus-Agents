---
description: Remove dead code and consolidate duplicates
agent: refactor-cleaner
subtask: true
---

# Refactor Clean

Analyze and clean up the codebase: $ARGUMENTS

## Your Task

1. Detect dead code using repo-appropriate analysis
2. Identify duplicates and consolidation opportunities
3. Safely remove unused code (with brief rationale)
4. Verify behavior via the fastest reasonable checks (tests/lint/build)

## Detection Phase

Prefer native tooling for the repo. If this is a JS/TS project and these tools are available, consider:

```bash
# Find unused exports
npx knip

# Find unused dependencies
npx depcheck

# Find unused TypeScript exports
npx ts-prune
```

Also check for:

- Unused imports/variables
- Unused functions (no callers)
- Unused exports (be careful: external consumers)
- Commented-out code blocks
- Unreachable branches
- Unused CSS classes

## Removal Order (Safe)

1. Unused imports
2. Private helpers with no callers
3. Types/interfaces only referenced locally
4. Exported APIs only when you can prove no external usage
5. Entire files only when you can prove they are unused

## Consolidation

Look for:

- Copy-pasted logic with small variations
- Repeated constants/magic strings
- Similar functions that differ by options

Consolidate via:

- Extracting shared utilities
- Introducing small shared helpers instead of large abstractions
- Centralizing constants/config

## Verification

Run the fastest reasonable verification for this repo (tests/lint/build). Choose commands based on what the project supports.

## Report Format

Dead Code Analysis
==================

Removed:
- <file>: <symbol> (<why safe>)

Consolidated:
- <before> -> <after>

Remaining (manual review needed):
- <file>: <note>

Verification:
- Tests: <not run | passing | failing> (<command>)
- Lint: <not run | passing | failing> (<command>)
- Build: <not run | passing | failing> (<command>)

CAUTION: Prefer correctness over aggressiveness. If external usage is unclear, leave it and note it.
