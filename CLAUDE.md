# CLAUDE.md — Pip 2

Rules for every agent working in this repo. Keep this file short. Engine-specific rules are added once the first screen runs.

The engine is Godot 4.7, scripted in GDScript. It is newer than most examples online, so check the 4.7 documentation before using a feature rather than trusting memory.

## Who works here
Mike and Mark both work on this, each with their own Claude Project and agents. Their chats and memories are not shared. The repo and the board are the only things everyone sees, so a decision counts only once it is in `docs/DECISIONS.md`, and work counts only once it is on the board.

## Read first
1. `docs/BRIEF.md`: what the game is and what the slice is.
2. The board (link in the README): what is active and who owns what.
3. The recipe in `docs/recipes/` for whatever you are about to touch.

## One home per fact
- Scope: `docs/BRIEF.md`. Changes only when both Mike and Mark have said yes.
- Decisions: `docs/DECISIONS.md`. Append one dated line; never rewrite.
- How-to and gotchas: `docs/recipes/`.
- Status: the board, and nowhere else. Don't write status into any file.
If you are about to write a fact that already lives somewhere, link to it instead.

## The board
- Work only on cards in the active milestone. Don't create cards for later milestones.
- A card's owner is its prefix: [Mike] [Mark] [Planning] [Code] [Cowork].
- Before starting a card, check nobody has claimed it, then comment `Claimed — <agent> (<person>)`. Never start without the claim: the other person's agents can't see your chat. When done, comment what you did and what you saw, then tick it.
- New idea or work the active milestone doesn't need: one line in the Parking lot, then carry on.
- Blocked on a person: comment the question and change the card's prefix to [Mike] or [Mark].
- A milestone (◆) card is ticked only when both Mike and Mark have said they've seen its "Done when".
- Sign every comment with the agent and the person it is working for, e.g. `— Code (Mark)`, `— Planning (Mike)`.

## Done means
You ran it, looked at the result, and said on the card what you saw. For anything a person has to judge by eye or by feel, the card goes to them instead of being ticked.

## Never
- Commit `.blend` files, raw Flow output or secrets.
- Generate Pip. He comes from the Blender rig.
- Build ahead of the active milestone, or build tooling for later games.
