# Story Room build notes

The Story Room is the series story bible: a claude.ai artifact (link in `docs/recipes/board-and-tools.md`, "Artifacts") with its own database, used from Mike's phone. It is a separate tool from the game. These notes are how it was built and how its code is laid out, so either account's Claude can pick up work on it. They are history and reference: the dates and "built" or "not built yet" lines describe the app as each note was written, not the game's status, which lives on the board.

Read in this order:
1. `build-plan.md`: the feature plan, the rules every feature follows (only Mike sets canon, stable ids, Christine's spoiler-free view, phone-first), code landmarks and how to test.
2. `visual-specs-plan.md`: the agreement with the game project on visual specs, world lore, NPC hooks and the asset manifest.
3. `claims.md`, `specs.md`, `hooks-shots.md`, `shot-routes.md`: what was built from that agreement.
4. `handover.md`: the hand-over pack for working on the story from the other account, and the return-file format.
5. `twin.md`: how the other account runs its own copy of the app from a pack and sends changes back, and how the import works.

Where Story Room material lives in the repo:
- Build notes: here.
- Story exports (briefs, full story, handover packs): `docs/story/`.
- Return files from the other account: `docs/story/returns/`.

The page's own source is `tools/story_room/index.html`.
