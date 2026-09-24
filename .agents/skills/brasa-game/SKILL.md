---
name: brasa-game
description: "Modificar combate, Historia, progresión o identidad del juego Brasa. Usar cuando una tarea afecte reglas o guardados, conservando paridad online cuando corresponda."
---

# Cambiar lógica de Brasa

La raíz del repositorio está en `../../..` desde esta carpeta. Lee `AGENTS.md` y `docs/LLM-GUIDE.md`; resuelve las rutas siguientes contra esa raíz.

Localiza el contrato en scripts/combat_engine.gd, combat_rules.gd, progression.gd o story_progression.gd antes de editar main.gd. Conserva IDs de personajes y esquemas de guardado; prueba migraciones con fixtures, sin reescribir partidas reales.

Si una regla afecta al online, lee backend/battle-engine/README.md, revisa el port y el catálogo exportado. Mantén orden de consumo RNG y precisión numérica; un cambio visual no justifica cambiar balance. No aceptes resultados del cliente como autoridad.

Ejecuta las pruebas del área según docs/DEVELOPMENT.md y reporta resultados concretos. Las suites históricas no son evidencia de esta revisión. No despliegues ni uses staging por una tarea local.
