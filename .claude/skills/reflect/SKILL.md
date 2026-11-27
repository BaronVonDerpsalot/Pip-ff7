---
name: reflect
description: End-of-session review for Pip FF7. Looks back over this session for what went wrong, what cost time and what worked unexpectedly well, turns each into a dated gotcha, proposes where it belongs in docs/recipes/, prunes gotchas the session proved stale, flags docs the session showed to be out of date, and writes only what Mike approves. Use when the user says /reflect, "reflect", "what did we learn", "wrap up the session", or asks to capture gotchas or lessons.
---

# Reflect

Turn this session's problems and wins into guidance the next agent will actually read. Gotchas are **guidance, not rules**: each one records a situation and what helped there, so a later agent can judge whether it still applies.

## 1. Gather
Go back over the whole session (not just the last few turns) and list:
- **Snags**: a tool that failed or refused, a wrong assumption, an approach that had to be redone, a side effect you had to clean up, something that only worked on the second try.
- **Time sinks**: anything that took several attempts or a detour.
- **Wins**: a trick or approach that worked better than expected and should be reused.

Only include what actually happened and was confirmed (you saw the error, the fix, the result). No speculation, no "might be worth checking". Before writing "X can't do Y", check that it really can't: tools may be deferred (search for them) or have options you haven't loaded.

## 2. Filter
Drop anything that is:
- a one-off typo or slip with no lesson in it;
- already written in a recipe, `CLAUDE.md` or `DECISIONS.md` (link to it instead if it needs reinforcing);
- a decision rather than a gotcha (a decision goes to `DECISIONS.md`, and only with a yes from Mike);
- status ("M1 is done"), which belongs on the board.

## 3. Write each one in this shape
> **<Short title>** (<date>, <milestone>): <what happened, in one sentence>. <What to do instead, as "when X, try Y">. <Why, if it isn't obvious>.

Example:
> **Edited images keep their old import** (2026-11-13, M1): an image overwritten outside the editor kept showing its old version in game. When you change an image file from a script, rename it or give the Godot window focus so it reimports.

Rules for wording:
- "When X, try Y", never "always" or "never". Keep the situation in the entry so a later reader can see whether theirs matches.
- Plain words. Name the tool, file or screen involved.
- One gotcha, one fact. Split anything with "and also".

## 4. Place
Each gotcha goes in the **Gotchas** section of the recipe for the area it's about (one home per fact):
| About | File |
| --- | --- |
| Flow, screens, cut-outs | `docs/recipes/screens-flow.md` |
| Layering, depth occlusion, hide-Pip shapes | `docs/recipes/screens-layering.md` |
| Shader motion on a screen | `docs/recipes/screens-shader-motion.md` |
| MimicPC and ComfyUI themselves | `docs/recipes/comfyui.md` |
| The style browser and style tests | `docs/recipes/style-browser.md` |
| Builds and delivery | `docs/recipes/delivery.md` |
| Pip's Blender render | `docs/recipes/pip-blender.md` |
| Pip's rig | `docs/recipes/pip-rig.md` |
| Godot, Ziva, the editor, scenes, scripts | `docs/recipes/godot.md` |
| The Asana board, the repo, tools around them | `docs/recipes/board-and-tools.md` |

Create the file if it doesn't exist yet: a `# Recipe: <area>` heading, one line saying what it covers, then `## Gotchas`. If an area doesn't fit, propose a new recipe rather than a catch-all file.

## 5. Prune
Read the Gotchas sections you're about to add to. For any existing entry that this session showed to be wrong, outdated or superseded, propose removing or rewriting it, with the reason. A stale gotcha is worse than none.

## 6. Drift
List anything this session showed to be out of step, and only what the session actually touched (a full sweep is `/housekeeping`'s job):
- a doc that says one thing while the build does another (brief, decisions, a recipe, `CLAUDE.md`, the README);
- a "later" or "once X happens" in a doc whose moment has now come;
- the same fact, file or asset now living in two places;
- something made by hand this session that someone will need to remake.

For each, propose the fix. Anything that changes scope or a decision needs a yes from Mike and goes to `DECISIONS.md`.

## 7. Ask, then write
Show the user one list, grouped by file:
- **Add**: each new gotcha, worded as it would be written.
- **Change or remove**: each existing one, with why.
- **Wins** worth keeping, placed the same way.
- **Drift fixes**, each with what it changes.

Ask which to keep. Write only the approved ones, exactly as approved. Commit what was written as its own commit and push, as `CLAUDE.md` "Commits" says. If the board is in use, leave a one-line comment on the session's card naming the files you changed, signed `— <agent>`.
