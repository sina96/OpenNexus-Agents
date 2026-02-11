---
description: Orchestrate multiple agents for complex tasks
agent: opennexus
---

# Orchestrate

Orchestrate multiple specialized agents for this complex task: $ARGUMENTS

## Your Task

1. Analyze task complexity and break it into concrete subtasks
2. Pick the best specialist agent(s) for each subtask
3. Create an execution plan with dependencies
4. Parallelize independent subtasks
5. Synthesize results into a single coherent answer

## Specialists Available

- deep-explorer: read-only repo discovery
- designer: UI/UX and frontend polish
- doc-updater: update docs to match code and workflows
- task-manager: sequencing, risks, acceptance criteria
- researcher: external docs + GitHub examples
- refactor-cleaner: dead code/dup cleanup
- reviewer: correctness/security review
- tester: run lint/test/build
- junior-coder: small, low-risk edits
- senior-coder: complex refactors/multi-file implementation
- context-manager: summarize and prune context
- requirement-manager: requirements/tickets

## Execution Plan Format

Phase 1: Plan
- Agent: task-manager (if needed)
- Output: short plan with phases and owners

Phase 2: Work (parallel where possible)
- Agent A: <agent>
- Agent B: <agent>

Phase 3: Verify
- Agent: tester

Phase 4: Review + Docs
- Agent: reviewer
- Agent: doc-updater (if docs drift)

Phase 5: Synthesize
- Provide final result, key decisions, and next steps

Coordination rules:

- Plan before execution
- Minimize handoffs/context
- Clear ownership per artifact
- Prefer smallest viable parallelization
