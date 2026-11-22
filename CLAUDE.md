# CLAUDE.md — Pip FF7

Rules for every agent working in this repo. Keep this file short.

The engine is Godot 4.7, scripted in GDScript. It is newer than most examples online, so check the 4.7 documentation before using a feature rather than trusting memory (Ziva's `search_docs` reads the running editor's own API).

## Engine rules
- Layout: `scenes/` (screens in `scenes/screens/`), `scripts/`, `assets/` (art by subject, e.g. `assets/screens/marsh/`, `assets/pip/`), `tools/` (scripts we run by hand, not used by the game). Builds go to `../builds/`, outside git (`docs/recipes/delivery.md`).
- Change project settings and input actions only in the Godot editor or with Ziva's `update_project_setting`. Never edit `project.godot` by hand.
- Game code reads the input actions (`move_left`, `move_right`, `move_up`, `move_down`), never raw keys or buttons, so the pad and keyboard stay equal.
- Typed GDScript: declare types (`var speed := 1.5`, `func f(x: int) -> void`).
- How a screen is built: `docs/recipes/screens-flow.md`. Godot and Ziva gotchas: `docs/recipes/godot.md`.

## Who works here
Mike works on this from two accounts, Mike and Mark (DECISIONS, 2026-11-20). Each account has its own Claude Project and agents, and their chats and memories are not shared. A yes from either account counts, and "Mike or Mark" anywhere in the docs means Mike. The repo and the board are the only things both accounts see, so a decision counts only once it is in `docs/DECISIONS.md`, and work counts only once it is on the board. Anything that matters goes there, never only into a chat or a memory.

The Planning agent (each account's claude.ai Project) also follows `docs/planning.md`.

## Read first
1. `docs/BRIEF.md`: what the game is and what the slice is.
2. The board (link in the README): what is active and who owns what.
3. The recipe in `docs/recipes/` for whatever you are about to touch.

## One home per fact
- Scope: `docs/BRIEF.md`. Changes only when Mike or Mark has said yes.
- Decisions: `docs/DECISIONS.md`. Append one dated line; never rewrite.
- How-to and gotchas: `docs/recipes/`. At the end of a session, run `/reflect` to turn the session's snags and wins into gotchas there.
- Status: the board, and nowhere else. Don't write status into any file.
If you are about to write a fact that already lives somewhere, link to it instead.

## The board
- Sections run in order: the milestones (M0 to M7), then a Side track, the Later sections (Creatures and world, Combat, Minigames, Look and polish, Tools), then the Parking lot. Each milestone's ◆ card holds its "Done when", which Mike can check by looking or playing, and the milestones it needs.
- One milestone is active at a time, marked (ACTIVE) in its section name. Cards exist only for the active milestone and the active side track. Work only on those cards.
- A card is one outcome. Its owner is its prefix: [Mike] [Mark] [Planning] [Code] [Cowork]. Say what it's blocked by in its description.
- Before starting a card, check nobody has claimed it, then comment `Claimed — <agent> (<person>)`. Never start without the claim: the other person's agents can't see your chat. When done, comment what you did and what you saw, then tick it.
- Blocked on a person: comment the question and change the card's prefix to [Mike] or [Mark].
- Work outside the slice: one line in the nearest Later section, with no ◆, "Done when" or order, and don't develop it. Unsorted ideas and small things the active milestone might want: one line in the Parking lot. Then carry on.
- One side track may run beside the active milestone: a named piece of work Mike pulls from a Later section, with its own ◆ and "Done when". It never gates a milestone or the slice. Pulling work in needs Mike's yes and a `DECISIONS.md` line. A Later section becomes a milestone only after the slice ships.
- A milestone (◆) card is ticked only when Mike or Mark has said they've seen its "Done when". Before it's ticked, run `/housekeeping`. Once it's ticked, move (ACTIVE) to the next milestone whose needs are all ticked, and create its cards.
- Sign every comment with the agent and the person it is working for, e.g. `— Code (Mark)`, `— Planning (Mike)`.

## Staying on course
- Asked for something outside the active milestone and the side track: say so once and ask whether to file it in a Later section, pull it into the side track, or swap the milestone. Then do what Mike chooses.
- Changing direction (engine, art style, scope, the slice) is its own step that needs Mike's yes: say what it invalidates, update the brief, log the decision and re-plan the board before any other work.

## Done means
You ran it, looked at the result, and said on the card what you saw. For game work that means running the scene (Ziva's `run_scene`, with inputs if it needs walking) and looking at the screenshot, not just checking the code parses. For anything a person has to judge by eye or by feel, the card goes to them instead of being ticked.

## Never
- Commit `.blend` files, raw Flow output or secrets.
- Generate Pip. He comes from the Blender rig. The one exception is a cinematic too complex to stage in-engine, which Flow may make (DECISIONS, 2026-11-21).
- Build ahead of the active milestone, or build tooling for later games.
