# Motor autoritativo Brasa v1

Portado del Godot instalado `4.7.2.stable.official.ed1daf0bf`, sin modificar el motor GDScript ni los guardados. No usa HTTP, D1, reloj del sistema ni azar global. El módulo no concede recompensas.

## API

`index.js` exporta:

- `gameCatalog`, `ENGINE_VERSION`, `CATALOG_VERSION`, `RNG_VERSION`.
- `buildCombatant(dto)`: recibe `character_id`, `level`, `allocations`, `move_upgrades`, `perks`, `ai_config` y metadatos opcionales `fighter_id`, `owner_id`, `identity`, `appearance`. Calcula stats con las ocho asignaciones de Historia y técnicas legales. Ignora stats derivados, habilidades y técnicas suministradas por el DTO. Valida formas y límites; el servicio debe comprobar propietario, presupuesto de puntos/fichas, recompensas y revisiones.
- `statsForProfile(profile)`, `xpForLevel(level)`, `pointsForLevel(level)`, `getStatOptions()`, `getUnlockedMoves(id,level)`, `getPerks(id)`, `resolveMove(id,moveId,tier,perks)`.
- `getStoryStage(globalLevel)`, `getStoryOpponent(globalLevel)`: copia del encuentro exportado; fuera de1–100 devuelve `null`.
- `validateAiConfig(raw)`: devuelve `{style,weights}` o lanza error. Estilos: balanced/aggressive/defensive/fast/counter/risky/unpredictable. Cada peso opcional corresponde a un tipo conocido y está entre0.25 y4. Los presets alteran únicamente pesos; balanced conserva la IA de Godot.
- `simulateBattle(player,rival,seedString,options={})`: descriptores **confiables**, resultado completo con `events`, `metrics`, `winner`, `reason`, `duration`, `turns`, `player`, `rival`, `seed`, versiones y `final_state`/`terminal_state`. Cada evento mantiene su orden en el array y el `time` simulado. `options.battle_id` debe contener el ID asignado por el servicio.
- `BattleEngine`: interfaz interna `start/advance/surrender/snapshot/summary` para corpus y herramientas.

Los descriptores completos y las opciones de pruebas no son payloads autorizables directamente desde HTTP. En particular, `combat_stats`, `ability`, `moves`, `force_signature`, `initial_hp`, `initial_statuses`, `opening_time` y `surrender_at` permiten preparar casos internos y nunca deben exponerse como entradas del cliente.

`include_states:true` añade snapshots visuales a cada evento. El valor predeterminado es false; la reproducción normal usa eventos y el resultado final. Los snapshots completos aumentan notablemente el payload. No se implementó otro formato compacto en esta entrega.

La semilla es una cadena decimal uint64, sin ceros iniciales salvo `"0"`. El servidor genera una semilla impredecible; PCG permite después reproducir el combate. La cadena `"0"` representa una semilla determinista en este módulo, mientras que `CombatEngine.start(...,0)` local usa `randomize()`; los corpus de combate emplean semillas no nulas. Nunca transportar uint64 mediante un Number JSON.

## Catálogo y reglas

`../data/game-catalog.json` conserva 15 personajes, 75 técnicas jugables, 90 opciones de talento, 10 técnicas de jefes y 100 encuentros, capítulos, jefes, presupuestos, XP, atributos, estados y constantes de IA. Guarda SHA-256 de los ocho archivos GDScript de origen. El mismo `catalog_version` versiona los valores de combate y de progreso; su SHA-256 identifica los bytes exportados.

Las etapas17–100 usan los descriptores reales exportados con `run_seed=0`. Se conservan variantes, debilidades, técnicas, talentos, asignaciones y jefes; no se portó el hash de Godot para cambiar el personaje del pool por campaña. Los guardados y los pools locales permanecen intactos.

Se conservan mitigación, variación±8%, crítico, guardias, escudos, DoT simultáneo, tiempos de impacto/recuperación, acciones bajo stun, lentitud y reajuste de iniciativa, habilidades, fases, contraataques diferidos y rendición terminal. La Firma se arma una vez por luchador, al1%; no es1% por ataque. Al ejecutar Firma se conserva también la selección normal que Godot realiza antes de sustituirla: ese consumo de RNG importa para la paridad.

PCG32 procede del algoritmo de M. E. O'Neill (Apache-2.0); la adaptación float32 corresponde a Godot (MIT). Véanse [PCG](https://github.com/godotengine/godot/blob/ed1daf0bf/thirdparty/misc/pcg.cpp), [RandomPCG](https://github.com/godotengine/godot/blob/ed1daf0bf/core/math/random_pcg.h) y [RandomNumberGenerator](https://github.com/godotengine/godot/blob/ed1daf0bf/core/math/random_number_generator.h). No se usa `Math.random()`.

## Reproducción de las comprobaciones

Desde la raíz del proyecto Godot:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script scripts/export_game_catalog.gd
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/export_engine_corpus.gd
node --test backend/tests/engine-*.test.mjs
node backend/tests/engine-benchmark.mjs 10000 /ruta/absoluta/benchmark.json
```

La referencia está comprimida en `backend/tests/fixtures/engine-godot.json.gz`. El exportador guarda precisión numérica completa y el test verifica su vínculo con el hash del catálogo. Los eventos se comparan campo por campo, excluyendo únicamente `message`, que es texto localizado. Todos los números se comparan con igualdad exacta.

No existen dependencias nuevas. Los fixtures y los simuladores no se importan desde producción; `index.js` importa sólo el catálogo y los módulos puros.
