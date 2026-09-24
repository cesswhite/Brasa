# Mapa de contexto para otro LLM

Empieza por [AGENTS.md](../AGENTS.md). Este archivo enruta hacia código y contratos; los datos actuales del checkout prevalecen sobre informes históricos.

| Tarea | Entrada y fuentes |
| --- | --- |
| Navegación/pantallas | `scripts/main.gd`, `scripts/ui/`, `scenes/main.tscn` |
| Sistema visual | `scripts/ui/game_visual_system.gd`, `scripts/ui/components/`, `data/game_visual_tokens.json`, [biblia visual](../reports/VISUAL-STYLE-BIBLE.md) |
| Personajes y escala | `scripts/fighter_view.gd`, `scripts/character_visual_profile.gd`, `scripts/fighter_animation_set.gd` |
| Heridas | `scripts/damage_art.gd`, `scripts/visual_damage_state.gd` |
| Reglas y combate | `scripts/combat_engine.gd`, `scripts/combat_rules.gd`, `scripts/move_catalog.gd` |
| Progresión/Historia | `scripts/progression.gd`, `scripts/story_progression.gd`, `scripts/story_catalog.gd`, `scripts/story_achievements.gd` |
| Identidad/cosméticos | `scripts/fighter_identity.gd`, `scripts/cosmetic_catalog.gd`, `scripts/battle_identity.gd` |
| Audio | `scripts/audio/audio_director.gd`, `data/audio_events.json`, [restricciones](../LICENSING.md) |
| Online cliente | `scripts/online_api.gd`, `scripts/identity_api.gd`, `scripts/online_session_store.gd` |
| Worker/identidad | `backend/src/`, [auth](../backend/docs/AUTH.md), [contrato online](../backend/docs/ONLINE.md) |
| Motor autoritativo | `backend/battle-engine/`, [contrato y paridad](../backend/battle-engine/README.md) |
| Pruebas | `tests/`, `backend/tests/`, [guía](DEVELOPMENT.md) |

## Contratos que no debes inferir

- La cuenta personal del mantenedor no está autorizada por clonar el repo. El staging documentado es un servicio remoto real.
- Un nombre o ID enviado por el cliente no demuestra propiedad. Los resultados online se calculan en el servidor.
- Los perfiles locales y online no se mezclan como si el guardado local fuera confiable.
- Una prueba previa en `reports/` no acredita cambios nuevos. Indica siempre checkout, prueba y entorno.
- Los archivos ausentes de audio son intencionales en la edición pública; no republiques el pack privado para arreglar un test.
- MIT no cubre arte/audio ni reemplaza licencias de terceros.

## Flujo de trabajo

Carga solamente el área afectada; inspecciona tests y consumidores antes de cambiar contratos. Conserva APIs/migraciones salvo que la tarea pida cambiarlas. Verifica la implementación con pruebas pertinentes y, si cambia UI, con capturas. Entrega qué cambió, evidencia y limitaciones sin afirmar despliegues o confirmaciones biométricas no realizados.

Las [skills](../SKILLS.md) tienen rutas relativas a la raíz del repo y no dependen de una instalación personal de Codex. Cualquier LLM que pueda leer archivos puede seguir sus SKILL.md aunque no tenga descubrimiento automático.
