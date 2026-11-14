# Pip FF7

A short game for Christine starring Pip, on FF7-style painted screens. Built in Godot 4.7.

- What the game is and what the slice is: [docs/BRIEF.md](docs/BRIEF.md)
- Decisions: [docs/DECISIONS.md](docs/DECISIONS.md)
- How each pipeline works, and gotchas: [docs/recipes/](docs/recipes/). Making builds and the itch.io link: [docs/recipes/delivery.md](docs/recipes/delivery.md)
- Rules for agents: [CLAUDE.md](CLAUDE.md)
- Status and what's next: the Asana board "Pip FF7", https://app.asana.com/1/42223663012559/project/1220489972903806

Status lives only on the board.

## Setup
1. Install **Godot 4.7.2** (the standard build, not .NET): https://godotengine.org/download/archive/ (4.7.2-stable).
2. Clone this repo and open `project.godot` in Godot. The first open imports the art, which takes a minute.
3. Press **F5**. Pip starts on the marsh screen. Move with the left stick, d-pad, arrows or WASD. L3 or Shift toggles running; a gentle push of the stick, or holding C, creeps. F shows the walk area.

For AI agents (optional): install **Ziva** in Godot from https://ziva.sh, sign in to Ziva in its dock (the free plan is enough), then connect it to Claude Code from Ziva's settings ("Ziva as an MCP server"). Its addon folder stays out of git, so each person installs it themselves. Open Claude Code sessions in this repo folder so `CLAUDE.md` and the project's skills load: `/reflect` at the end of a session, `/housekeeping` when a milestone closes.

Brief test from Mark
