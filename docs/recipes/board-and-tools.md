# Recipe: the board and the tools around it

Working with the Asana board and the browsers agents use to reach it. How the board is run is in `CLAUDE.md`.

## Each account needs
Mike works from two Claude accounts on one PC. Anything set up per account has to be set up in both, or agents in one account hit a wall the other doesn't. `/housekeeping` checks this list.
- **The Pip FF7 Project** on claude.ai, with the instructions in `docs/planning.md` ("The Project's instructions") pasted exactly, and no project files.
- **Project memory** off, or swept at each housekeeping (anything real moves into the repo, the rest is deleted).
- **Connectors:** Asana (the board) and GitHub (Planning's clone). Others are optional and nothing in the project relies on them.
- **Claude in Chrome** signed in to that account, for `/occlusion` (MimicPC) and as the board's fallback.
- **Claude Code** in the desktop app signed in, with sessions opened in `Pip-ff7/`.
- **Access to every artifact below.**

Shared by both accounts already, because they live on the PC rather than the account: `~/.claude` (output style, rules, user skills), the local MCP servers (Ziva, Blender, Affinity, Meshy), the repo's `.claude/settings.json` (shared permissions, committed) and `.claude/settings.local.json` (this PC's extras, not committed). Connector tools are named by an ID that differs per account (`mcp__<id>__get_tasks`), so allow them in the local file, once per account, never in the committed one.

## Artifacts
An artifact belongs to the account that published it. The other account can open it only once the owner shares it, and can't edit it unless both accounts are in the same claude.ai organization (on 2026-11-27, Claude Code could not open the Story Room at all). So nothing in an artifact may exist only there: its source, and anything people add to it, also lives in the repo, and either account can rebuild its own copy from that.

| Artifact | Link | Made from | Source in the repo |
|---|---|---|---|
| Story Room (story canon) | https://claude.ai/artifact/7PGPmyvhZp2edGCTemJ76b | a Planning Project | none yet: canon lives only in the artifact |
| Pip Style Browser | https://claude.ai/artifact/U1ST3JJsFgWyApv688VFpa | Claude Code | `tools/style_browser/` builds the page; the picks live only in its database |

## Gotchas
- **Rename Asana sections with the connector's `update_project`** (2026-11-13, M1): its `rename_sections` option does it directly. It's a deferred tool, so search for it before concluding the connector can't; an earlier note here said it couldn't, which was wrong.
- **If renaming a section in the browser, finish with Tab, not Enter** (2026-11-13, M0): Enter saved the name but also opened a new blank task under it, which Asana saved. Press Tab to leave the field, then check the task count hasn't changed.
- **The two browsers sign in separately** (2026-11-13, M0): Claude in Chrome was not connected at first, and the built-in browser pane opened Asana's login page. When one browser fails, try the other, and expect the built-in one to need its own Asana sign-in.
- **Update the ◆ card when a decision changes its "Done when"** (2026-11-13, M2): M2's card still said three directions a day after the eight-directions decision, and it was only caught when the milestone came up for sign-off. When a `DECISIONS.md` line changes what a milestone needs, edit that ◆ card's "Done when" in the same session.
- **Win: the Asana connector reads the board directly** (2026-11-13, M2): with Chrome disconnected and the built-in browser stuck at sign-in, the Asana MCP tools (`get_project`, `get_tasks`, `add_comment`, `update_tasks`) read and updated the board in a few calls. When the board is needed, try the connector before either browser.
- **Shell deletes with a variable or glob get refused** (2026-11-20, M5): Claude Code's safety check refused `rm -f $D/*`, and a glob after `cd`. When clearing generated files, try removing them by exact name, or `"${D:?}"/name`, rather than a wildcard.
- **Asana search needs a paid plan** (2026-11-20, M5): `search_tasks` failed with "payment_required". When looking for cards, try `get_tasks` on the project with `opt_fields=name,completed,memberships.section.name`, which lists every card with its section.
