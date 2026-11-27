---
name: housekeeping
description: Whole-project check-up for Pip FF7, run when a milestone closes (before its ◆ card is ticked) or when asked. Checks that agent rules load, that docs match the build, that promised-later items are handled, that each fact has one home, that hand-made files can be rebuilt, that a fresh clone sets up, clears leftovers, and parks what the next milestone will need. Proposes fixes and makes only the approved ones. Use for /housekeeping, "tidy the project", "project check-up", or at the end of a milestone.
---

# Housekeeping

A slow look across the whole project, between milestones. `/reflect` looks back at one session; this looks at everything. Propose, then change only what Mike approves.

Read first: `CLAUDE.md`, `README.md`, `docs/BRIEF.md`, `docs/DECISIONS.md`, every file in `docs/recipes/`, the board (active and next milestone, Parking lot), and a file listing of the repo and of the workspace folder around it.

## The checklist
Go through every item. For each, note **OK** or **a finding** with the evidence (file and line, or what you ran).

1. **Rules load.** Where do sessions start? If not inside the repo, does the workspace folder have a pointer `CLAUDE.md`? Are the repo's skills (`.claude/skills/`) committed and not ignored?
2. **Docs match the build.** Compare the brief's slice, `DECISIONS.md`, each recipe and `CLAUDE.md` with what's actually in the repo (scenes, scripts, settings, assets). Note every place they disagree. Check project settings with Ziva's `get_project_info` and `get_input_map`, not by memory.
3. **Promises come due.** Search the docs for "later", "once", "after the", "decided by", "written during". Any whose milestone has now passed?
4. **Open decisions.** Is each open decision in the brief still open? Did a closed milestone decide one without it moving to `DECISIONS.md`?
5. **One home per fact.** Is any fact, file, asset or name in two places (a doc repeating another, assets both in `kept-assets/` and the repo, status written into a file)? Is the project called the same thing everywhere?
6. **Rebuildable.** Is anything in the repo that was made by hand or by a one-off script, which someone will need to make again (generated resources, cut-outs, packed sheets)? Is there a tool or recipe step for it?
7. **Fresh clone.** Following only the README, could Mike clone, open and run the game on another machine? Anything missing from git that the game needs (ignored files, addons, absolute paths)? Check `.gitignore` and `git status`.
8. **Leftovers.** Throwaway folders, test scenes, backups, files marked to delete, unused assets, empty folders. List them; only remove with a yes (prefer the Recycle Bin over permanent deletion).
9. **Board hygiene.** Are the section labels right ((DONE) / (ACTIVE))? Any open cards in a closed milestone? Does every finished card have a comment saying what was done and seen?
10. **Look ahead.** Read the next milestone's "Done when". What will it need that is cheap to prepare or decide now and expensive later (tooling, storage like Git LFS, an open decision, an asset)? Put each as one line in the Parking lot, or as a question for Mike. Don't start the work.
11. **Gotchas still true.** Skim each recipe's Gotchas. Any that the build or later work has made wrong or pointless?
12. **Accounts in step.** You can see only the account you run in, so ask Mike for the other. Go through `recipes/board-and-tools.md`, "Each account needs", for both accounts. Does each Project's instructions match the block in `docs/planning.md` exactly? Ask Mike to paste what each account's Project memory holds (or confirm it's off): anything that is really a decision, rule or gotcha goes into the repo with his yes, and the rest he deletes. Has anything people added to an artifact in the "Artifacts" table since the last housekeeping (story canon, style picks) been copied into the repo? (Artifacts needn't open in both accounts.)

## Report
Show one list grouped as **Fix now** (small, clearly right), **Needs a yes** (scope, decisions, deletions, anything visible on the board), and **Park** (for later milestones). Each item: what's wrong, the evidence, the proposed change.

Then make only what's approved. Re-run anything you changed (a scene, a tool) and look at the result. Commit the approved fixes as their own commit. Leave one comment on the closing milestone's ◆ card listing what changed, signed `— <agent>`.
