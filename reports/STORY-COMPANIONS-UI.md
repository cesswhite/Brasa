# Story Mode · Companions

| Before | After |
| --- | --- |
| Chapter heading unrelated to the selection and redundant mark. | Companions and brief instruction: each story retains its progress. |
| Name, biography and skills mixed up. | Card with name, role, level, campaign progress and XP. Details in “Meet the partner”. |
| Small characters and unclear selection. | Expanded main view, collection with common camera and selection mark. |
| Campaign state exposed as scattered data. | Unstarted, current chapter and encounter, completed chapter or completed story; a bar of 100 encounters. |
| List mixed role, level and progress with a lot of information. | Cards focused on name, level and Story Mode status. The role is in the tab and in the contextual help. |
| Large bottom buttons and Full Width Customize. | Compact actions with 48 px height; Start story or Continue story according to actual progress. |
| Selecting a card did not clearly differentiate consultation and use. | Tags In use / Preview. Confirming with the bottom action preserves the existing flow. |
| Overlapping objects and permanent descriptions. | Shared background and materials; decorations omitted and optional reading of strength, weakness, ability and biography. |
| Visual reordering without attention to the keyboard or long names. | Focus returns to the card, cards adapt their height and their portraits share a scale. |

The main view reserves 360 px on desktop, 280 on phone, and 180 on low windows. The collection uses three columns on the desktop and two on narrower windows. Physical differences between bodies are preserved through the shared portrait component and a common camera for the cards.

Each profile shows its own Story progress. The view does not change the active peer until it is committed. A newly created profile without combat or advancement presents Start Story. Personalize directs the colleague being consulted.

## Verification

- **5917 native checks, 0 failures**, in seven sizes: 43 traps, six states per size and one additional case with long name. In-memory profiles; selection, identity, XP, focus, text, common scale, portrait boundary and fixed footer verified.
- **436 StoryPanel checks, 0 failures**: navigation, empty campaigns and access to the last companion.
- **337 campaign integration checks, 0 failures**: existing persistence and progression.

No personal items, balance or backend were modified. Existing art is reused. [Report index](README.md).
