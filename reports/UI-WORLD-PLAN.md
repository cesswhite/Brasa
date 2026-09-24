# Story Mode as a place · audit and previous plan

## Proven architecture

`scenes/main.tscn` instance `main.gd`; Story Mode opens as `StoryPanel`, a Control generated in code that outputs signals to the controller. `StoryProgression` preserves all logic and persistence. That limit is not modified.

StoryPanel uses MarginContainer → VBoxContainer → header, navigation HBox, ScrollContainer with dynamic body and fixed footer. The five destinations are Route, Upgrades, Moves, Companions, and Legacy. The current breakpoints are 600 px for phone, 540 px height for short format, and 1100 px for columns. There are fixtures of seven sizes between 390×844 and 1920×1080, including 844×390.

Its current look comes almost entirely from StyleBoxFlat: flat blue-green background, uniform cards with rounded corners, rectangular navigation, and grid encounter tabs. The opponent's chip appears below the grid and its standard preview measures 166×172, so it is outside the first viewport on the desktop. SystemFont uses Avenir Next/DejaVu Sans/Arial. There is no illustrated surface system or NinePatch on this screen.

The game already has FighterView with dynamic appearance and sprites, painted Lantern and Storm backgrounds, cosmetic catalog and chapter metadata. Characters, animations, identity and all data are reused. Combat is not replaced nor progression values ​​are changed.

## Visual direction

2D painted illustration, with soft edges and visible brush. Worn stone, dark wood, copper, rope and sewn cloths. Amber lantern light against petrol blue fog. Mineral and earth colors; limited accents according to chapter. Sun, brazier and path ornaments, consistent with Brasa. Without photorealism, pixel art or flat icons foreign to the world.

The rival dominates the match on the right on the desk; information and actions maintain contrast to the left. The route is represented by connected milestones, with numbers and native states. On mobile the composition is stacked and preserves scroll and footer actions. Bosses use more scale, light, and a frame/badge of their own.

## Asset plan

| Asset | Use |
| --- | --- |
| `assets/ui/story/journey-v1.png` | Lantern Path and Training Yard: Opening Chapter and Tempered Variants. |
| `assets/ui/story/storm-v1.png` | Courtyard of Roots, Iron and Rain: Chapter Identity 2 and Storm Variants. |
| `assets/ui/workshop/workshop-v1.png` | Workshop and training equipment: Improvements/Movements. |
| `assets/ui/companions/camp-v1.png` | Shelter around a fire: Companions. |
| `assets/ui/legacy/archive-v1.png` | Archive and pedestals of memories: Legacy. |
| `assets/ui/shared/surfaces-v1.png` | Reusable atlas of surfaces and marks: primary/secondary button, standard/boss frame, milestone and separator. |
| `assets/ui/shared/props-v1.png` | Transparent Atlas: Fighters' belongings, boss souvenirs, backpack and Arena medal. |

All resources are generated without text, figures or labels. Your regions are registered once and consumed with AtlasTexture and StyleBoxTexture/nine-slice. Art does not contain game state.

## System and sequence

A theme registry links stable IDs to backgrounds, surfaces, accents, and props. Data conditions choose at most a few items based on character, appearance, possessed items, and passed encounters. Props ignore the mouse, stay behind the content, and never grant achievements.

First the Route is integrated and the rival's scale, reading and navigation are checked; The same family is then applied to the workshop, refuge and legacy within Story Mode. The rest of the game is not redesigned in this installment. Funds are debited upon opening the section and the previous reference is released; Not all chapters are preloaded. Ambient motion, if added, must respect the reduced motion preference.

Delivery requires native captures, comparison with previous screen, normal/hover/pressed/focus/disabled states, seven sizes, original navigation/actions and intact saves. Code snapshots and initial hashes are in `work/world-ui/before.json`.
