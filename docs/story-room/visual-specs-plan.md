# Story Room: visual specs, world lore and NPC hooks (plan)

Agreed 21 Nov 2026 between Mike and Claude, after the Pip 2 planning room (the game agent) proposed screen specs, world lore and NPC hooks. The planning room accepted the revised version with four small changes (listed below). This is the next build item for the Story Room. It goes ahead of story flags (item 4 in build-plan.md), because Mike is making Flow assets now and the prompt doc gets more fragile with every batch.

## Mike's decisions (21 Nov)

1. Migrate all four existing Flow prompt batches (the Pip 2 Flow prompt doc) into the Story Room as brainstorm specs. Convert the camera overrides into shot purpose: LOW 15° to reveal, EYE 0° to insert, HIGH 75° to layout, default to playable or establishing.
2. The base style prompt stays in the game project. Clean separation: no style, medium or art direction words ever go in the Story Room.
3. Claude drafts specs automatically, as brainstorm, when a record has none.
4. Items include props, pickups and quest objects.
5. Return path: option a, a manifest. The game agent has access to the Story Room artifact, so it writes the manifest straight into the database. Automated, no pasting.
6. The three lore seeds are canon: the Reformed Church of the Damp, the Third Unspooling of King Mothrag, the Drowned Emperor (half the marsh insists he was a frog). Mike loves grand, mock-solemn names like these for wider lore.
7. The Bog Organ lies in very shallow water in the courtyard pond, water lapping round its belly and legs. Not submerged, and no mound. Both bible records were updated on 21 Nov (claude_changes `ch_21nov_organ_shallow`), and every hub 1 prompt in the Flow doc was rewritten to match the same day.

## The planning room's changes to the revised version (accepted)

- Text on screen: the planning room decides per screen whether sign text is painted in or overlaid in-engine. The spec just holds the exact wording.
- Character and item images are the source for 3D models, so they must be whole and unobstructed. Poses, views and turnarounds are the planning room's business, not the spec's.
- Cinematics are only for moments too complex to stage in-engine. Anything Pip's rig sprites can do stays in-engine.
- The manifest records file paths in the game repo (e.g. assets/screens/<id>/...), never Flow download names.

## What to build

- A spec type with four kinds: screens, characters, items, cinematics. Fields are in the prompt below.
- Screens hang under places. Padding screens hang under route places (such as road_h1_h2), not as their own bible records.
- States: variants of a screen that name the state they come from plus the change, so the game project can edit the image instead of regenerating it.
- A tally that shows records without specs, stale specs (written before their source records last changed), specs with no accepted image (from the manifest), and one-way or dangling exits.
- An asset manifest collection the planning room writes to: one doc per spec id with state, repo file path(s) and picked date. Name it when building and tell Mike, so the planning room can be told.
- Specs are owner-only. They never reach Christine's guest view, because they're spoiler soup.
- A shot-list export in game order, shaped for the flow-assets skill.
- Lore built on the existing kinds (events, groups and factions, rules and lore). Events get claims (who believes what) and an owner-only "what actually happened" field. Add the three canon seeds as series-wide records.
- An NPC hook field on characters. The script room warns when a speaker has no hook. Minor NPCs are lightweight records. Roleplay already sends full character records, so hooks reach roleplay for free.
- Health check: flag an NPC lore contradiction only when the NPC has no matching wrong belief.

## Notes for the build chat

- Record collection is `entries` (characters, places, events, items: `kind` field). Beats are `beats`. Change log is `claude_changes`.
- The live brief (`briefs/pip_2`) only refreshes when Mike opens the app. On 21 Nov it still showed the pre-20-Nov Organ, which misled a chat into thinking the bible was wrong. Read records, not the brief, when checking a fact.
- The manifest collection must be the only place the planning room writes. Enforce it in the db rules if they can tell the writers apart. If not, it's a convention the planning room has agreed to (ground rule 0e).

## The final prompt (confirmed by Mike and the planning room, 21 Nov)

```
Additions to the Story Room, agreed with the Pip 2 planning room (21 Nov), revised by the Story Room side, then confirmed by Mike:

0. GROUND RULES
   a. Only Mike sets canon. Everything the planning room or Claude adds
      lands as brainstorm until he says otherwise. Claude drafts specs
      for gaps automatically, as brainstorm.
   b. Names come from the Story Room: Pip's past starts at the
      Mouldworks, in Gloomcap Hollow. There is no "Gloomworks".
   c. Ids are stable snake_case and never renamed. The planning room
      adds take suffixes (_01a, _01b) on its side only.
   d. Style, medium and art direction live only in the planning room.
      Specs never contain them.
   e. The planning room writes to the Story Room's database in one
      place only: the asset manifest (section 4). It never creates,
      edits or deletes records, specs or anything else there. Changes
      to the story go to Mike, who makes them in the Story Room.

1. VISUAL SPECS
Four kinds: screens, characters, items, cinematics. Every spec stores
when it was written; the Story Room flags it stale when the records it
was drawn from change. A stale spec should not be generated until it
has been refreshed.

   SCREENS (one per playable screen or still)
   a. Id: e.g. h1_courtyard. Prefix by area (fb_, m1_, h1_, r12_, h2_...)
   b. Place: the place record it belongs to. Padding screens hang under
      a route place (e.g. road_h1_h2) rather than becoming places
      themselves
   c. Beat: linked beat(s), or "padding" if none
   d. Contents: what is physically there, stated as fact, no style
      words (e.g. "round huts with reed-and-mud walls and thatched
      roofs around a flagstone courtyard")
   e. Must be visible: what the beat needs on screen (e.g. a narrow
      path a villager can block)
   f. Must not be visible: e.g. no characters (NPCs are placed
      in-engine), never Pip
   g. Exits: each exit and the screen id it leads to. The Story Room
      flags one-way and dangling exits
   h. Mood and time of day
   i. Shot purpose: playable, establishing, layout (map), reveal
      (scale), or insert (close detail). The planning room turns this
      into a camera angle
   j. States: variants of the same screen (dusk, hypnotised, restored,
      low/high water). Each names the state it comes from and what
      changes, so the planning room edits the existing image instead
      of regenerating
   k. Text on screen: exact sign wording. The planning room decides
      per screen whether it is painted in or overlaid in-engine
   l. Tags: canon, mixed or invented; a "mystery" flag for planted
      FF7-style mysteries

   CHARACTERS and ITEMS (items include props, pickups and quest objects)
   a. Id, and the record it belongs to
   b. Must show: identifying features taken from the record
   c. States: e.g. Firefly bright / torn wing / dim; frog normal / swirl
   d. Isolated, full body, whole and unobstructed: the image is the
      source for a 3D model

   CINEMATICS (the only specs where Pip may appear)
   a. Id, and the scene and beat it belongs to
   b. What happens, start frame and end frame
   c. Who is in shot
   d. Pip's look comes from his character record plus the reference
      image in the planning room
   e. Only for moments too complex to stage in-engine. Anything the
      engine can do with Pip's rig sprites stays in-engine

2. WORLD LORE
Built from the Story Room's existing kinds (events, groups and
factions, rules and lore), not a parallel section. Series-wide by
default, tagged with the game where it is first mentioned.
   a. Pip remembers nothing before the Mouldworks and could not
      imagine a world outside, so the wider world can be huge and
      absurd: gods, rulers, epic history, mentioned by NPCs in passing
      as if everyone knows
   b. History is contested: each event records the claims and which
      factions or sects hold them
   c. Each event has an owner-only "what actually happened" field,
      which can say "undecided" or "never decided". This separates
      deliberate contradiction from continuity error
   d. Lore obeys the existing rules: no real-world references until
      London, and nothing may confirm a twist the rules hold back
      (above all, the murk being in charge)
   e. Naming style Mike likes: grand, mock-solemn, faintly damp
   f. Canon seeds (Mike, 21 Nov):
      - The Reformed Church of the Damp (a sect; presumably there is
        an unreformed one, still damp in all the old wrong ways)
      - The Third Unspooling of King Mothrag (a historical event)
      - The Drowned Emperor, who half the marsh insists was a frog
      What actually happened behind each is undecided.

3. NPC HOOKS
Every NPC gets one specific hook before any dialogue is written: an
obsession, a grudge, a hobby, a faction or affiliation, or a wrong
belief about the lore.
   a. Hooks link to the faction or lore record they touch; a wrong
      belief names the claim it believes
   b. Hooks overlap, and NPCs contradict each other about the lore.
      The health check only flags a contradiction when the NPC has no
      matching wrong belief
   c. The script room warns when a speaker has no hook
   d. Minor NPCs are lightweight records, so hundreds of them don't
      bury the bible
   Lore and NPCs added by anyone but Mike are brainstorm until he
   says otherwise.

4. ASSET MANIFEST (the return path)
After each batch Mike picks from, the planning room writes one
document per spec id into the Story Room's asset manifest collection
(name set when the Story Room side is built; do not write until it
exists). Each records the spec id, the state, the accepted file
path(s) in the game repo (e.g. assets/screens/<id>/...), never a Flow
download name, and when they were picked. Overwrite a spec's document
when its pick changes; never delete one without Mike saying so. This
is how the Story Room tally knows which specs are done.

5. A CANON FACT ALREADY CHANGED
The Bog Organ lies asleep in the very shallow water of the courtyard
pond, the water lapping round its belly and legs. Not submerged, and
no mound. Any existing hub 1 prompt that puts it on a mossy mound
clear of the water is out of date.
```
