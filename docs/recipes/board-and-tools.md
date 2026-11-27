# Recipe: the board and the tools around it

Working with the Asana board and the browsers agents use to reach it. How the board is run is in `CLAUDE.md`.

## Each account needs
Mike works from two Claude accounts on one PC. Anything set up per account has to be set up in both, or agents in one account hit a wall the other doesn't. `/housekeeping` checks this list.
- **The Pip FF7 Project** on claude.ai, with the instructions in `docs/planning.md` ("The Project's instructions") pasted exactly, and no project files.
- **Project memory** off, or swept at each housekeeping (anything real moves into the repo, the rest is deleted).
- **Connectors:** Asana (the board) and GitHub (Planning's clone). Others are optional and nothing in the project relies on them.
- **Claude in Chrome** signed in to that account, for `/occlusion` (MimicPC) and as the board's fallback.
- **Claude Code** in the desktop app signed in, with sessions opened in `Pip-ff7/`.

Artifacts don't need to open in both accounts: Mike moves their content between accounts by export (DECISIONS, 2026-11-27).

Shared by both accounts already, because they live on the PC rather than the account: `~/.claude` (output style, rules, user skills), the local MCP servers (Ziva, Blender, Affinity, Meshy), the repo's `.claude/settings.json` (shared permissions, committed) and `.claude/settings.local.json` (this PC's extras, not committed). Connector tools are named by an ID that differs per account (`mcp__<id>__get_tasks`), so allow them in the local file, once per account, never in the committed one.

## Artifacts
An artifact belongs to the account that published it. The other account can open it only once the owner shares it, and can't edit it unless both accounts are in the same claude.ai organization (on 2026-11-27, Claude Code could not open the Story Room at all). So nothing in an artifact may exist only there: its source, and anything people add to it, also lives in the repo, and either account can rebuild its own copy from that.

| Artifact | Link | Made from | Source in the repo |
|---|---|---|---|
| Story Room (story canon) | https://claude.ai/artifact/7PGPmyvhZp2edGCTemJ76b | a Planning Project | build notes in `docs/story-room/`; exports and handover packs go to `docs/story/`, return files to `docs/story/returns/`. page source in `tools/story_room/`; the canon itself lives in the artifact's database, and moves between accounts by handover pack and return file (`docs/story-room/twin.md`) |
| Pip Style Browser | https://claude.ai/artifact/U1ST3JJsFgWyApv688VFpa | Claude Code | `tools/style_browser/` builds the page; the picks live only in its database |

## Gotchas
- **Rename Asana sections with the connector's `update_project`** (2026-11-13, M1): its `rename_sections` option does it directly. It's a deferred tool, so search for it before concluding the connector can't; an earlier note here said it couldn't, which was wrong.
- **If renaming a section in the browser, finish with Tab, not Enter** (2026-11-13, M0): Enter saved the name but also opened a new blank task under it, which Asana saved. Press Tab to leave the field, then check the task count hasn't changed.
- **The two browsers sign in separately** (2026-11-13, M0): Claude in Chrome was not connected at first, and the built-in browser pane opened Asana's login page. When one browser fails, try the other, and expect the built-in one to need its own Asana sign-in.
- **Update the ◆ card when a decision changes its "Done when"** (2026-11-13, M2): M2's card still said three directions a day after the eight-directions decision, and it was only caught when the milestone came up for sign-off. When a `DECISIONS.md` line changes what a milestone needs, edit that ◆ card's "Done when" in the same session.
- **Win: the Asana connector reads the board directly** (2026-11-13, M2): with Chrome disconnected and the built-in browser stuck at sign-in, the Asana MCP tools (`get_project`, `get_tasks`, `add_comment`, `update_tasks`) read and updated the board in a few calls. When the board is needed, try the connector before either browser.
- **Shell deletes with a variable or glob get refused** (2026-11-20, M5): Claude Code's safety check refused `rm -f $D/*`, and a glob after `cd`. When clearing generated files, try removing them by exact name, or `"${D:?}"/name`, rather than a wildcard.
- **Asana search needs a paid plan** (2026-11-20, M5): `search_tasks` failed with "payment_required". When looking for cards, try `get_tasks` on the project with `opt_fields=name,completed,memberships.section.name`, which lists every card with its section.
- **The GitHub connector and the github plugin can be different accounts** (2026-11-22, M5): one had admin on the repo and the other only push and triage. When a GitHub action needs admin, or should come from a particular account, try `get_me` on the tool you're about to use first.
- **A terminal opened before installing gh doesn't find it** (2026-11-22, M5): after `winget install GitHub.cli`, `gh` was "not recognized" in the already-open terminal and in Claude's shell. When a new install isn't found, open a new terminal, or call `& "C:\Program Files\GitHub CLI\gh.exe"`.
- **A successful git push can show as a failure in PowerShell** (2026-11-22, M5): `git push` printed `941dc8c..5eaa8f8 main -> main`, but the PowerShell tool reported exit code 255, because git writes its progress to stderr. When a git command seems to fail there, read its output and `git status -sb` before retrying.
- **Rebasing onto another session's DECISIONS lines conflicts at the end of the file** (2026-11-22, M5): two sessions had each appended lines, so the rebase stopped on `docs/DECISIONS.md`. When that happens, try keeping both sides' lines, the already-pushed ones first, since the file is append-only, and check no conflict markers are left before `rebase --continue`.
- **Write big scripts with the Write tool, not a heredoc** (2026-11-24): writing `score.py` through a Bash heredoc put real newlines inside a regex and broke it, and a long heredoc with mixed quotes failed to parse. When a script or file is more than a few lines, try writing it with Write (to the scratchpad if it's throwaway) and running it.
- **A wait loop keyed on process memory quit early** (2026-11-23, M5): a background `until` loop that also exited when no large `python.exe` showed in `tasklist` stopped after 7 of 14 depth maps. When waiting for a batch, wait on the background job's own completion notice, or count the output files.
- **Win: test a page's scripts in headless Edge over the DevTools protocol** (2026-11-24): the built-in browser shows a `file://` page outside the project only as a static snapshot, without scripts. Edge with `--remote-debugging-port`, driven by a small Node 22 script (built-in WebSocket and fetch), clicked, dragged, pressed keys and took screenshots at several sizes. When a page needs interaction testing without a dev server, try that.
- **Edge headless screenshots come out blank with `--virtual-time-budget`** (2026-11-24): when taking a headless screenshot, try `--headless=new` with `--timeout=6000` instead.
- **Win: collect reflects from several sessions, then reconcile in one place** (2026-11-27, M5): four sessions that had skipped `/reflect` each ran it report-only (no edits, commits or board comments) and sent their lists to one session by SendMessage. That session pulled, checked every item against the current recipes and `git log`, and dropped 9 that later work had replaced before anything was written. When several sessions need reflecting, try that rather than letting each one write. The newest work wins, and Mike approves one list.
- **Searching other sessions for a skill's name finds them all** (2026-11-27, M5): `search_session_transcripts` for "reflect" matched nearly every session, because each one loads `CLAUDE.md`, which mentions `/reflect`. When checking whether a session ran a skill, try searching for a phrase from the skill's own body (for `/reflect`, "Turn this session's problems and wins").
- **A compacted session reflects from its summary** (2026-11-27, M5): the style-browser session said its early gotchas came from its compacted summary, not its transcript. When collecting reflects, ask each session to mark what it saw directly, and treat the rest as second-hand.
