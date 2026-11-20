# Recipe: the board and the tools around it

Working with the Asana board and the browsers agents use to reach it. How the board is run is in `CLAUDE.md`.

## Gotchas
- **Rename Asana sections with the connector's `update_project`** (2026-11-13, M1): its `rename_sections` option does it directly. It's a deferred tool, so search for it before concluding the connector can't; an earlier note here said it couldn't, which was wrong.
- **If renaming a section in the browser, finish with Tab, not Enter** (2026-11-13, M0): Enter saved the name but also opened a new blank task under it, which Asana saved. Press Tab to leave the field, then check the task count hasn't changed.
- **The two browsers sign in separately** (2026-11-13, M0): Claude in Chrome was not connected at first, and the built-in browser pane opened Asana's login page. When one browser fails, try the other, and expect the built-in one to need its own Asana sign-in.
- **Update the ◆ card when a decision changes its "Done when"** (2026-11-13, M2): M2's card still said three directions a day after the eight-directions decision, and it was only caught when the milestone came up for sign-off. When a `DECISIONS.md` line changes what a milestone needs, edit that ◆ card's "Done when" in the same session.
- **Win: the Asana connector reads the board directly** (2026-11-13, M2): with Chrome disconnected and the built-in browser stuck at sign-in, the Asana MCP tools (`get_project`, `get_tasks`, `add_comment`, `update_tasks`) read and updated the board in a few calls. When the board is needed, try the connector before either browser.
- **Shell deletes with a variable or glob get refused** (2026-11-20, M5): Claude Code's safety check refused `rm -f $D/*`, and a glob after `cd`. When clearing generated files, try removing them by exact name, or `"${D:?}"/name`, rather than a wildcard.
