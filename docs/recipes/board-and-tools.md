# Recipe: the board and the tools around it

Working with the Asana board and the browsers agents use to reach it. How the board is run is in `CLAUDE.md`.

## Gotchas
- **The Asana connector can't rename sections** (2026-11-13, M0): it has no section tools. When a section needs renaming (moving "(ACTIVE)" or "(DONE)"), do it in the browser: click the section name, select all, type.
- **Finish an Asana section rename with Tab, not Enter** (2026-11-13, M0): Enter saved the name but also opened a new blank task under it, which Asana saved. When renaming, press Tab to leave the field, then check the task count hasn't changed.
- **The two browsers sign in separately** (2026-11-13, M0): Claude in Chrome was not connected at first, and the built-in browser pane opened Asana's login page. When one browser fails, try the other, and expect the built-in one to need its own Asana sign-in.
