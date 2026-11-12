# CLAUDE.md — Pip 2

Rules for every agent working in this repo. Keep this file short. Engine-specific rules are added once the first screen runs.

The engine is Godot 4.7, scripted in GDScript. It is newer than most examples online, so check the 4.7 documentation before using a feature rather than trusting memory.

## Read first
1. `docs/BRIEF.md`: what the game is and what the slice is.
2. The board (link in the README): what is active and who owns what.
3. The recipe in `docs/recipes/` for whatever you are about to touch.

## One home per fact
- Scope: `docs/BRIEF.md`. Changes only with Mike's say-so.
- Decisions: `docs/DECISIONS.md`. Append one dated line; never rewrite.
- How-to and gotchas: `docs/recipes/`.
- Status: the board, and nowhere else. Don't write status into any file.
If you are about to write a fact that already lives somewhere, link to it instead.

## The board
- Work only on cards in the active milestone. Don't create cards for later milestones.
- Before starting a card, comment `Claimed — <you>`. When done, comment what you did and what you saw, then tick it.
- New idea or work the active milestone doesn't need: one line in the Parking lot, then carry on.
- Blocked on Mike: comment the question and change the card's prefix to [Mike].
- Sign every comment (— Code, — Cowork, — Planning). All agents post through Mike's account.

## Done means
You ran it, looked at the result, and said on the card what you saw. For anything Mike has to judge by eye or by feel, the card goes to him instead of being ticked.

## Never
- Commit `.blend` files, raw Flow output or secrets.
- Generate Pip. He comes from the Blender rig.
- Build ahead of the active milestone, or build tooling for later games.
