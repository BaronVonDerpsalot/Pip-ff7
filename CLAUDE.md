# CLAUDE.md — Pip FF7

Rules for every agent working in this repo. Keep this file short.

The engine is Godot 4.7, scripted in GDScript. It is newer than most examples online, so check the 4.7 documentation before using a feature rather than trusting memory (Ziva's `search_docs` reads the running editor's own API).

## Engine rules
- Layout: `scenes/` (screens in `scenes/screens/`), `scripts/`, `assets/` (art by subject, e.g. `assets/screens/marsh/`, `assets/pip/`), `tools/` (scripts we run by hand, not used by the game). Builds go to `../builds/`, outside git (`docs/recipes/delivery.md`).
- Next to the repo, outside git: `../kept-assets/`, `../builds/`, `../preprocessing/` and `../segment-env/`. What each holds and how it's used is in the recipe that names it. Bring into `assets/` only what the game needs.
- Change project settings and input actions only in the Godot editor or with Ziva's `update_project_setting`. Never edit `project.godot` by hand.
- Game code reads the input actions (`move_left`, `move_right`, `move_up`, `move_down`), never raw keys or buttons, so the pad and keyboard stay equal.
- Typed GDScript: declare types (`var speed := 1.5`, `func f(x: int) -> void`).
- How a screen is built: `docs/recipes/screens-flow.md`. Godot and Ziva gotchas: `docs/recipes/godot.md`.

## Who works here
Mike works on this from two Claude accounts (DECISIONS, 2026-11-20). Each account has its own Claude Project and agents, and their chats and memories are not shared. A yes from either account is Mike's yes. Older comments and log lines that say Mark mean Mike. The repo and the board are the only things both accounts see, so a decision counts only once it is in `docs/DECISIONS.md`, and work counts only once it is on the board. Anything that matters goes there, never only into a chat or a memory.

The Planning agent (each account's claude.ai Project) also follows `docs/planning.md`.

## Read first
1. `docs/BRIEF.md`: what the game is and what the slice is.
2. The board (link in the README): what is active and who owns what.
3. The recipe in `docs/recipes/` for whatever you are about to touch.

## One home per fact
- Scope: `docs/BRIEF.md`. Changes only when Mike has said yes.
- Decisions: `docs/DECISIONS.md`. Append one dated line; never rewrite.
- How-to and gotchas: `docs/recipes/`. At the end of a session, run `/reflect` to turn the session's snags and wins into gotchas there.
- Status: the board, and nowhere else. Don't write status into any file.
If you are about to write a fact that already lives somewhere, link to it instead.

## The board
- Sections run in order: the milestones (M0 to M7), then a Side track, the Later sections (Creatures and world, Combat, Minigames, Look and polish, Tools), then the Parking lot. Each milestone's ◆ card holds its "Done when", which Mike can check by looking or playing, and the milestones it needs.
- One milestone is active at a time, marked (ACTIVE) in its section name. Cards exist only for the active milestone and the active side track. Work only on those cards.
- A card is one outcome. Its owner is its prefix: [Mike] [Planning] [Code] [Cowork]. Say what it's blocked by in its description.
- Before starting a card, check nobody has claimed it, then comment `Claimed — <agent>`. Never start without the claim: the other account's agents can't see your chat. When done, comment what you did and what you saw, then tick it.
- Blocked on a person: comment the question and change the card's prefix to [Mike].
- Work outside the slice: one line in the nearest Later section, with no ◆, "Done when" or order, and don't develop it. Unsorted ideas and small things the active milestone might want: one line in the Parking lot. Then carry on.
- One side track may run beside the active milestone: a named piece of work Mike pulls from a Later section, with its own ◆ and "Done when". It never gates a milestone or the slice. Pulling work in needs Mike's yes and a `DECISIONS.md` line. A Later section becomes a milestone only after the slice ships.
- A milestone (◆) card is ticked only when Mike has said he's seen its "Done when". Before it's ticked, run `/housekeeping`. Once it's ticked, move (ACTIVE) to the next milestone whose needs are all ticked, and create its cards.
- Sign every comment with the agent, e.g. `— Code`, `— Planning`. No account name: commits carry a `Claude-Session:` link, which opens only from the account that made them.

## Staying on course
- Asked for something outside the active milestone and the side track: say so once and ask whether to file it in a Later section, pull it into the side track, or swap the milestone. Then do what Mike chooses.
- Changing direction (engine, art style, scope, the slice) is its own step that needs Mike's yes: say what it invalidates, update the brief, log the decision and re-plan the board before any other work.

## Done means
You ran it, looked at the result, and said on the card what you saw. For game work that means running the scene (Ziva's `run_scene`, with inputs if it needs walking) and looking at the screenshot, not just checking the code parses. For anything a person has to judge by eye or by feel, the card goes to them instead of being ticked.

## Commits
- Pull before you start. Commit and push when a card's work is done, before ticking it.
- One outcome per commit, and the message says the outcome. A DECISIONS line goes in with the doc it changes, never with unrelated work.
- Stage files by name after checking `git status`. Never `git add -A` or `git add .`.
- Nothing is left uncommitted at the end of a session: commit it, or say on the card what's left and why.

## Never
- Commit `.blend` files, raw Flow output or secrets.
- Generate Pip. He comes from the Blender rig. The one exception is a cinematic too complex to stage in-engine, which Flow, or ComfyUI with a Pip LoRA, may make (DECISIONS, 2026-11-21 and 2026-11-24).
- Build ahead of the active milestone, or build tooling for later games.
