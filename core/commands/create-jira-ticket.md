---
description: Create a Jira-style ticket from user requirements with scope and issues
agent: requirement-manager
subtask: false
---

# Create Jira Ticket

Create a comprehensive Jira-style ticket from user requirements: $ARGUMENTS

## Your Task

1. **Understand the requirements**:
   - Parse the user's description of scope and issues from `$ARGUMENTS`
   - Identify the core problem, desired outcome, and any constraints
   - If requirements are unclear or incomplete, ask clarifying questions

2. **Explore the codebase for context** (read-only):
   - Use @subagent/deep-explorer if you need to understand existing architecture, patterns, or related code
   - Identify relevant files, modules, or components that will be affected
   - Note any existing similar features or patterns to reference

3. **Create a comprehensive Jira-style ticket** with:
   - **Title**: Clear, concise summary (50-80 chars)
   - **Description**: Detailed explanation of the problem and proposed solution
   - **Acceptance Criteria**: Specific, testable conditions for completion (use checkboxes)
   - **Technical Notes**: Implementation hints, affected components, dependencies, risks
   - **Related Files**: List of files/modules that will likely be modified
   - **Estimated Complexity**: T-shirt size (XS/S/M/L/XL) with brief justification

4. **Present the ticket to the user**:
   - Show the complete ticket in a clear, readable format
   - Highlight any assumptions you made
   - Note any areas where you need more information

5. **Ask for approval to save**:
   - Ask: "Would you like me to save this ticket to `.opencode/docs/jira-tickets/<ticket-name>.md`?"
   - Suggest a filename based on the ticket title (lowercase-with-hyphens format)
   - Wait for explicit user approval before saving

6. **Save the ticket** (only after user approval):
   - Create `.opencode/docs/jira-tickets/` directory if it doesn't exist
   - Save the ticket with proper markdown formatting
   - Include metadata in frontmatter (created date, status, complexity)
   - Confirm the save location to the user

## Ticket Format

```markdown
---
title: <ticket title>
created: <UTC ISO timestamp>
status: draft
complexity: <XS|S|M|L|XL>
---

# <Ticket Title>

## Description

<Detailed explanation of the problem and proposed solution>

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes

- Implementation approach: <brief description>
- Affected components: <list>
- Dependencies: <any blockers or prerequisites>
- Risks: <potential issues or concerns>

## Related Files

- `path/to/file1.ts`
- `path/to/file2.ts`

## Complexity Justification

<Why this ticket is sized as XS/S/M/L/XL>
```

## Output Format

When presenting the ticket:

```
Jira Ticket Draft

Title: <title>
Complexity: <size>

<full ticket content>

---

Assumptions:
- <list any assumptions made>

Would you like me to save this ticket to `.opencode/docs/jira-tickets/<suggested-filename>.md`?
```

## Guidelines

- Be specific and actionable in acceptance criteria
- Include technical context that helps implementers
- Flag risks and dependencies early
- Use clear, professional language
- Reference existing patterns and conventions in the codebase
- Don't save anything until the user explicitly approves

## Complexity Sizing Guide

- **XS**: Trivial change, single file, < 1 hour
- **S**: Small feature or fix, 2-3 files, < 4 hours
- **M**: Medium feature, multiple files, 1-2 days
- **L**: Large feature, cross-cutting changes, 3-5 days
- **XL**: Major feature or refactor, > 1 week
