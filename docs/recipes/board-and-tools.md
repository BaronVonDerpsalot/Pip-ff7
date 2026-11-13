# Recipe: the board and the tools around it

Working with the Asana board and the browsers agents use to reach it. How the board is run is in `CLAUDE.md`.

## Gotchas
- **Rename Asana sections with the connector's `update_project`** (2026-11-13, M1): its `rename_sections` option does it directly. It's a deferred tool, so search for it before concluding the connector can't; an earlier note here said it couldn't, which was wrong.
- **If renaming a section in the browser, finish with Tab, not Enter** (2026-11-13, M0): Enter saved the name but also opened a new blank task under it, which Asana saved. Press Tab to leave the field, then check the task count hasn't changed.
- **The two browsers sign in separately** (2026-11-13, M0): Claude in Chrome was not connected at first, and the built-in browser pane opened Asana's login page. When one browser fails, try the other, and expect the built-in one to need its own Asana sign-in.
