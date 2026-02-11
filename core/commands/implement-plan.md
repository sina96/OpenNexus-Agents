---
description: Implement a saved plan from .opencode/plans/
agent: opencoder
---

# Implement Plan

You are implementing a saved plan from the local workspace.

## WHAT TO DO

1. **Locate plans directory**: Look for plan files under `.opencode/plans/`.
   - If `.opencode/plans/` does not exist, explain the expected structure and stop.

2. **Select a plan**:
   - If `$ARGUMENTS` is provided:
     - Treat it as a plan selector (filename, partial name, or keyword).
     - Find the best matching plan file in `.opencode/plans/`.
     - If multiple plausible matches exist, list them (with modified timestamps and checkbox progress if present) and ask the user to pick one.
   - If `$ARGUMENTS` is empty:
     - Select the most recently modified plan file in `.opencode/plans/`.

3. **Read the FULL plan**: Open the selected plan file and understand the goal, constraints, and acceptance criteria.

4. **Implement the plan**:
   - Execute tasks in order.
   - Make the smallest complete changes that satisfy the plan.
   - Run the most relevant verification commands (tests/lint/build) for the repo.
   - If the plan contains checkboxes, update the plan as you complete each item.

5. **When the plan is done**:
   - If all plan tasks are complete (e.g. all checkboxes checked, or all steps executed and verified), append a note to the plan file indicating implementation completion with a UTC timestamp.
   - Append the note at the end of the file under a heading (create it if missing):

```md
## Implementation Log

- Implemented: <UTC ISO timestamp>
```

Timestamp (UTC ISO) can be generated with:

- `!date -u +"%Y-%m-%dT%H:%M:%SZ"`

## OUTPUT FORMAT

If plan selection is ambiguous:

```
Available Plans

1. [plan-a.md] - Modified: <timestamp> - Progress: <done>/<total>
2. [plan-b.md] - Modified: <timestamp> - Progress: <done>/<total>

Which plan should I implement? (Enter number or exact filename)
```

When starting implementation:

```
Implementing Plan

Plan: <filename>
Path: <path>
```

When finished:

```
Implementation Complete

Plan: <filename>
Verification: <what you ran + result>
Plan log: appended completion entry
```

## CRITICAL

- Always read the full plan before changing code.
- Prefer safe defaults; do not introduce breaking changes unless the plan explicitly requires it.
- Only append the completion note when the plan is actually complete.
