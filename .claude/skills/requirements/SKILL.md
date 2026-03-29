---
name: requirements
description: Gather and document requirements before implementing a feature, change, or fix. Updates REQUIREMENTS.md through a structured discovery process. Use before any implementation begins.
disable-model-invocation: true
---

Use this skill when the user wants to add a feature, change behaviour, or fix a problem — before any implementation begins.

## Goal

Reach a shared, concrete understanding of what needs to change and why, then update REQUIREMENTS.md to reflect it. Do not write or propose any code until the user explicitly confirms the requirements are correct.

## Process

### 1. Read current state
Read `REQUIREMENTS.md` so you understand what is already specified.

### 2. Ask the opening question
Ask the user one open-ended question focused on the *problem*, not the solution:

> "What's the problem you're trying to solve, or what do you want users to be able to do that they can't do today?"

Wait for their answer before asking anything else.

### 3. Probe with focused follow-ups
Based on their answer, ask targeted follow-up questions — one at a time — to fill gaps. Useful angles:

- **Who / when**: Who experiences this? What triggers it? (e.g. a specific client, a use case, a failure they hit)
- **What success looks like**: How will you know it's working?
- **Boundaries**: Is there anything this should explicitly *not* do?
- **Edge cases**: What should happen when things go wrong or the input is unusual?
- **Constraints**: Any performance, compatibility, or platform limits to respect?

Not every angle applies — skip questions that are already obvious from context or prior answers. Stop probing when you have enough to write a clear requirement.

### 4. Reflect back
Summarise your understanding in plain language (2–5 sentences). Ask: "Does this capture it, or is anything off?"

Iterate if needed. Do not proceed until the user confirms.

### 5. Propose REQUIREMENTS.md changes
Show the specific additions, edits, or removals you'd make to `REQUIREMENTS.md`. Present as a diff or clearly marked before/after sections.

Ask: "Happy for me to apply this?"

### 6. Apply and confirm
Once the user approves, update `REQUIREMENTS.md`. Then confirm it's done and ask if they're ready to move to implementation.

## Rules

- Never jump to implementation during this skill — if you find yourself thinking about code, redirect to requirements.
- Ask one question at a time. Never fire a list of questions.
- Keep it conversational. This is a hobby project — lightweight and efficient beats thorough and exhausting.
- If the user already has a clear, complete idea, it's fine to move through the steps quickly.
