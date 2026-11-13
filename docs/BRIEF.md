# Pip FF7 — Brief

Changes only when Mike or Mark has said yes. Status is on the board, decisions are in `DECISIONS.md`, how-tos are in `recipes/`. None of that is repeated here.

## What this is
A short game for Christine starring Pip, the chibi creature she and Mike created. It follows the birthday game (Part 1, which is canon). Pip walks through hand-painted screens shown from fixed cameras, in the manner of FF7's backgrounds. Purely personal.

## Principles
1. A short, complete game beats an ambitious unfinished one.
2. One milestone at a time. Everything else waits in the Parking lot.
3. Playing something decides things. Documents don't.
4. Nothing is built "for later games" until the slice ships.
5. Christine only ever gets finished products. Mike and Mark play everything before that; nothing in progress goes to her.

## The slice
The slice is done when Mike or Mark plays this from start to end, on the pad, on final art:
1. Pip arrives in Monarch's Wallow and walks through about three connected marsh screens.
2. Pip walks, runs, creeps and idles in eight directions (five rendered, three mirrored).
3. At least one screen has an animated loop.
4. One villager, hypnotised, blocks the way. Pip can talk to them.
5. Pip's fart wakes the villager and the way on opens.

Not in the slice: sword combat, a boss, saves, Firefly, a story data pipeline, the phone, audio beyond a single track.

## Look
Hand-sketched storybook: soft watercolour fills, loose pencil linework, visible paper texture, at full HD. A muted, quiet, slightly melancholy painted world, with Pip the brightest, cleanest thing in it. Pip is the only chibi character; everyone else has grounded proportions. Lines on characters redraw every couple of frames.

## How it is made
| Part | Made with |
| --- | --- |
| Engine | Godot 4.7 |
| Pip | Rendered from his Blender rig (`recipes/pip-blender.md`) |
| Screens | Google Flow stills (`recipes/screens-flow.md`) |
| Screen animation | Flow video loops (untested; recipe written in the screen pipeline milestone) |
| Other characters | Open |
| Story | Story Room holds canon. The slice's lines live in a file in this repo. |
| Input | Xbox controller first; keyboard fully supported |

## Open decisions
This is the only list of open decisions. When one closes, it moves to `DECISIONS.md` and leaves this list.
1. How other characters are made (Meshy plus Blender, or another route). Decided by the other-character milestone.
2. The font.
3. How often character lines redraw.
