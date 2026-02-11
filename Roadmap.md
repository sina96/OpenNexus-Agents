---
description: Roadmap for the OpenCode agents registry repository
---

# Roadmap

This document captures planned work for keeping this OpenCode agents registry useful, current, and easy to integrate.

## Vision

- Maintain a high-signal, dependable set of agent definitions that install cleanly and evolve with OpenCode.
- Make updates discoverable (what changed, why it matters) and easy for the community to propose.
- Expand integrations so these agents can run well across common developer setups.

## Near term (Next)

- [ ] Continuous sharpening passes on agent definitions (clarity, consistency, fewer footguns).
- [ ] Add an agent update-check mechanism (detect local vs registry versions; show changelog and upgrade steps).
- [ ] Publish a lightweight release/changelog flow (tagged releases; concise notes).
- [ ] Create a GitHub Project board to track roadmap items and current priorities.
- [ ] Set up a community intake loop: collect notes/requests, triage weekly, and turn into small actionable tasks.

## Mid term

- [ ] Claude Code integration: document setup, expected behavior, and any compatibility shims.
- [ ] "Compatibility matrix" doc: OpenCode versions vs agent pack versions; known-breaking changes.
- [ ] Improve installer UX: better validation/errors, dry-run mode, and clearer non-interactive output.

## Long term

- [ ] Antigravity integration: define scope, API surface, and minimal viable adapter.
- [ ] Explore packaging this repo as an OpenCode plugin (install/updates via plugin mechanism; versioned distribution).
- [ ] Automated quality gates for agents (frontmatter validation, lint rules for common mistakes, CI checks).

## Community / Process

- [ ] Maintain a short "decision log" for notable changes (why an agent was adjusted; breaking behavior notes).
- [ ] Regular cadence: monthly sweep for stale agents and dependency drift.
- [ ] "Good first issue" labeling and templates for agent tweaks vs new agents vs docs.

## Nice-to-haves

- [ ] Optional telemetry-free diagnostics (help users debug install issues without sharing secrets).
- [ ] Example configurations for popular stacks (JS/TS, Python, Go) showing agent + skill combos.
- [ ] A small cookbook of proven prompts/workflows per agent.

## How to contribute

- Open an issue with: goal, why it matters, expected behavior, and any links/screenshots.
- If proposing a new roadmap item: include an MVP scope and what "done" looks like.
- If you have community notes: paste them into an issue; maintainers will triage and convert them into tasks on the Project board.
- PRs welcome: keep changes focused, update docs when behavior changes, and avoid bundling unrelated edits.
