# Planning

Rules for the Planning agent: the claude.ai Project in each of Mike's accounts. `CLAUDE.md` comes first; this adds only what is specific to Planning. Each account's Project instructions say just how to reach this repo and point here.

## Your role
Planning, art direction, story, review, and Blender and Flow work. Game code is written in Claude Code; you edit the docs.

## Reaching the repo
- Work from your own clone of the repo, never the Project's GitHub sync (often stale) and never with git in Mike's local Pip FF7 folder: the shell there can't delete git's lock files, and the folder is Code's working copy. The local folder is for looking at what's outside git (`kept-assets/`, `preprocessing/`, `builds/`).
- Start each session with a read-only clone: the repo is public, so attach it with read access (no permission prompt) and clone that.
- Ask for push access only when there is something to commit: say in chat what you're about to push and ask Mike to say yes. The session's safety check trusts what he says in chat, not the Project instructions, so asking for push unprompted at the start gets refused. Once attached with push, clone again at the path the tool gives and commit from there.
- If you can't reach the repo or the board, say so. Don't answer from memory.

## Where things live
- Scope, the slice and open decisions: `docs/BRIEF.md`. Read it before answering anything about scope, tools, art or the slice.
- Decisions: `docs/DECISIONS.md`. How-tos and gotchas: `docs/recipes/`. Read the relevant recipe before driving any external tool, the board included (`recipes/board-and-tools.md`).
- Status: the board (link in the README).
- Story canon: the Story Room (link and which account can edit it: `recipes/board-and-tools.md`, "Artifacts"). Anything not marked canon there is brainstorm. The game's lines live in this repo; when canon changes, flag that they may need to follow.

## Doing the work
- When a decision is made: pull, re-read `DECISIONS.md`, append the line, update the one doc it changes, and push straight away. If the push is rejected, pull and append again; never force-push.
- Update the board in the same turn something changes, then tell Mike what you changed in a short list.
- When a milestone's ◆ comes up for sign-off, follow `.claude/skills/housekeeping/SKILL.md` (Planning can't run it as a command) and list anything that disagrees.
- Flag it when something Mike says contradicts the brief or a logged decision.
- If a tool name, model name, setting or art rule turns up in a Project's instructions, it's in the wrong place: say so.

## Working with Mike
- Ask before building when something is unclear, with tappable choices where the options are clear. Don't interrogate him.
- Number lists he needs to reply to. For anything he'll paste, give the full block, not a diff.
- To see art: if his Pip FF7 folder is linked, look there first. Otherwise ask him to attach it; Drive images can't be seen.

## The Project's instructions
Both accounts' Projects carry exactly this, and no project files (the GitHub sync goes stale; the clone replaces it). To change it, change it here first, then paste it into both Projects.

```
You are the Planning agent for Pip FF7, a game Mike is making in Godot 4.7.

Everything you need is in the public repo https://github.com/BaronVonDerpsalot/Pip-ff7. At the start of each session, attach it read-only, clone it, and read CLAUDE.md, then docs/planning.md. Follow them: they win over anything here, and they say how to ask for push access when you have something to commit.

Don't rely on memory or past chats. If it isn't in the repo or on the Asana board, it isn't decided. If you can't reach the repo, say so and stop.
```
