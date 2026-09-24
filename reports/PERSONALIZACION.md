# Personalización · tu compañero, su propia identidad

Este documento conserva el catálogo, alcance visual y pruebas de la entrega original de personalización. El estado actual de Arena y Cloudflare está en [Arena online](ARENA-ONLINE.md) y [Despliegue de Cloudflare](../backend/docs/DEPLOYMENT.md); las animaciones posteriores se documentan en [Secuencias de animación](ANIMATION-SEQUENCES.md). Los resultados siguientes no se repitieron durante la publicación de Cloudflare.

Brasa permite elegir el nombre y la apariencia de cada compañero, conservarlos al cerrar el juego y verlos en Liga, Historia, combates y repeticiones. El arquetipo sigue definiendo cómo pelea: vestir a Tepa con el cuerpo de Luma conserva las técnicas, el crecimiento y las estadísticas de Tepa.

## Cómo usarla

En una partida nueva, el creador permite elegir **base de combate**, nombre, cuerpo, paleta, efectos y presentación. **Crear compañero** lleva a Historia, con la campaña y sus tres puntos iniciales. La base identifica el estilo de juego; el cuerpo es una elección visual independiente.

En una partida existente, abre **Menú → Personalizar**, o usa **Personalizar** desde la ficha de **Compañeros**. El editor tiene vista previa animada, categorías, combinaciones y variación aleatoria entre opciones poseídas. Los cambios son un borrador hasta pulsar **Guardar cambios**; **Cancelar** conserva el nombre y la apariencia guardados. Durante un combate no se permite abrir la edición.

Los nombres nuevos admiten entre **2 y 24** letras o números Unicode, espacios, apóstrofo recto y guiones. Los espacios consecutivos se reducen a uno; se rechazan controles y nombres reservados. Dos compañeros o cuentas pueden tener el mismo nombre: el identificador interno es independiente y estable.

### Escritorio

![Editor de personalización en escritorio](customization-desktop.png)

### Móvil vertical

![Editor de personalización en móvil](customization-mobile.png)

Las capturas usan una fixture de demostración: base Mugo, cuerpo Balam, paleta Jade y aura Farol. Los desbloqueos se habilitaron sólo en esa fixture; en la partida normal se aplican los requisitos descritos a continuación.

## Antes y después

| Aspecto | Antes | Ahora |
| --- | --- | --- |
| Inicio de partida | Selección de compañero y nombre. | Creador con base de combate, nombre, cuerpo, paleta, efectos y presentación; continuación en Historia. |
| Apariencia | Ilustración asociada al personaje. | Trece cuerpos combinables con cosméticos definidos en el catálogo. |
| Nombre entre modos | Nombres dentro de los perfiles de Liga e Historia. | Una identidad por arquetipo compartida por ambos modos; cada modo conserva su progresión. |
| Confirmación | Sin un editor visual completo. | Vista previa y borrador; guardar o cancelar de forma explícita. |
| Historial | Resultado y datos de la pelea. | Las peleas nuevas conservan también nombre, ID, apariencia y eventos para su repetición visual. |
| Preparación en línea | Sin servicio de identidad. | Worker+D1 local con cuentas de desarrollo, inventario validado y fichas persistentes; sin publicación ni PvP completo. |

## Catálogo y desbloqueos

El catálogo tiene **29 opciones** contando las variantes originales y «sin efecto». Las poses y animaciones adicionales presentan las imágenes existentes; no añaden técnicas ni modifican sus tiempos de combate.

| Categoría | Opciones |
| --- | --- |
| Cuerpo · 13 | Nima, Luma, Mugo, Sira, Iria, Duna, Kiro, Neris, Taro, Balam, Tepa, Xuna y Copal. |
| Paleta · 5 | Original, Jade, Ocaso, Luna y Tinta. |
| Aura · 4 | Ninguna, Farol, Luciérnagas y Corona. |
| Estela · 3 | Ninguna, Brasa y Estela de jade. |
| Victoria · 2 | Clásica y Saludo. |
| Entrada · 2 | Clásica y Pulso. |

Los trece cuerpos, Original/Jade/Ocaso, ausencia de aura/estela y ambas presentaciones de victoria/entrada están disponibles desde el principio. Las otras siete opciones se obtienen jugando:

| Recompensa | Requisito |
| --- | --- |
| Paleta Luna | Llegar a nivel de personaje 10 en Liga o Historia. |
| Paleta Tinta | Ganar 10 combates de Liga con un compañero. |
| Aura Farol | Superar el encuentro 8 de Historia. |
| Estela Brasa | Superar el encuentro 20 de Historia. |
| Aura Luciérnagas | Superar el encuentro 50 de Historia. |
| Aura Corona | Superar el encuentro 100 de Historia. |
| Estela de jade | Ganar 25 combates de Liga con un compañero. |

Las condiciones se comprueban sobre el progreso válido de un compañero; no se suman victorias de distintos perfiles para alcanzar un umbral. Una vez obtenido, el cosmético pertenece al inventario local compartido y puede usarse en los demás compañeros. No se consume al equiparlo. Las combinaciones bloqueadas muestran su requisito. No hay compras ni monetización.

**Alcance visual de aquella entrega:** se reutilizan los atlas ilustrados originales con sus ocho poses. La paleta aplica un tinte suave a la ilustración completa. No existen capas independientes para recolorear ropa, pelo o accesorios por separado. Aura, estela y presentación se añaden alrededor de esas poses. Esta ampliación no necesitó generar imágenes nuevas.

## Progreso, guardado y partidas anteriores

La identidad se guarda en un archivo adicional junto al guardado principal:

```text
~/Library/Application Support/BrasaLiga/brasa_save.json.identity.json
```

Con una ruta de guardado personalizada se usa `<save>.identity.json`. Contiene la cuenta local, IDs de luchador, nombres, apariencias e inventario; **no contiene ni sustituye los niveles, XP, atributos, técnicas o talentos** de los trece perfiles. Liga e Historia mantienen sus archivos y progresiones independientes. Cambiar cuerpo, nombre o efectos no añade poder ni altera estadísticas, alcance o reglas de combate.

La migración conserva los nombres existentes. Si Liga e Historia tienen nombres personalizados distintos para el mismo arquetipo, se conserva el de Liga; si Liga mantiene el nombre original y sólo Historia lo personalizó, se conserva el de Historia. Los nombres antiguos se respetan aunque no cumplan la regla nueva, mientras no se modifiquen. Renombrar no cambia el ID ni la fecha de creación del luchador.

El archivo de identidad se valida antes y después de escribir, usa un temporal y reemplazo atómico, y conserva la versión anterior en `.bak`. Un bloqueo y la comprobación del hash evitan que dos ventanas sobrescriban cambios ajenos. Ante corrupción, versión desconocida o conflicto, se conserva el archivo y la personalización queda protegida; no se intenta reconstruirla borrando el progreso. Las pruebas usan archivos independientes de la partida real.

## Combates y repeticiones

Al iniciar la pelea se copia la identidad de cada participante junto con su apariencia y datos de combate. El HUD, el resultado y el registro usan esa copia. Un cambio posterior de nombre o equipo no reescribe lo que ocurrió.

En **Menú → Historial → Ver repeticiones**, las peleas nuevas pueden reproducirse con las poses y eventos registrados. La repetición muestra los nombres y cuerpos de aquel momento, permite revisar la acción y **no concede XP, victorias ni recompensas**. Los registros antiguos siguen siendo legibles; no se inventan eventos o imágenes históricas que nunca se guardaron.

![Repetición con identidades históricas](customization-replay.png)

## Servicio local de Workers y D1

La preparación autorizada funciona en **`http://127.0.0.1:8787`**, mediante Wrangler y D1 local. Incluye UUID estables, catálogo canónico, inventario por cuenta, creación/lectura de luchadores, cambio atómico de nombre/apariencia y vista persistente de un oponente aunque su dueño esté desconectado. El adaptador opcional Godot es [IdentityApi](../scripts/identity_api.gd).

La cuenta se provisiona con una herramienta local: token aleatorio privado, hash en D1, caducidad y revocación. El servidor valida dueño, revisión, categoría, ID, compatibilidad y posesión; el cliente no puede concederse cosméticos ni enviar rutas de recursos o shaders. Dos ediciones simultáneas con la misma revisión producen un único cambio aceptado. El módulo servidor de snapshots sólo copia luchadores existentes y conserva el hash de su catálogo para lecturas históricas.

**En esta entrega histórica no se había publicado el servicio.** Todavía no había login de producción, matchmaking ni un ejecutor PvP. El juego no sube automáticamente sus partidas o recompensas al servicio, y las cuentas locales de D1 no se vinculan automáticamente con el archivo de identidad de Godot. La vista de oponente y los snapshots preparan esa futura integración; no representan partidas en línea ya implementadas.

El arranque, credenciales, endpoints, errores y pruebas están en [backend/README.md](../backend/README.md). El backend está excluido de la importación/exportación de Godot y sus credenciales y datos temporales no forman parte de los archivos de distribución.

## Fuentes y validación

El [catálogo canónico](../data/cosmetic_catalog.json) es el export de [CosmeticCatalog](../scripts/cosmetic_catalog.gd), compartido con el backend. El código de [FighterIdentity](../scripts/fighter_identity.gd) separa identidad y progreso; [BattleIdentity](../scripts/battle_identity.gd) conserva las copias históricas.

| Prueba | Qué comprueba |
| --- | --- |
| [test_fighter_identity.gd](../tests/test_fighter_identity.gd) | Nombres, IDs, migración, desbloqueos, guardado, fallos de escritura y conservación del progreso. |
| [test_identity_integration.gd](../tests/test_identity_integration.gd) | Creador, editor, Liga/Historia, HUD, combate, historial y repetición sin recompensas. |
| [test_identity_edges.gd](../tests/test_identity_edges.gd) | Identidad protegida, fallos de guardado, snapshots incompletos y respuestas de API no válidas. |
| [test_customization_visuals.gd](../tests/test_customization_visuals.gd) | Variantes visuales y adaptación del editor/combate a siete tamaños. |
| [test_identity_api.gd](../tests/test_identity_api.gd) | Peticiones reales de Godot al Worker+D1 local y rechazos 401/403/409/422. |
| [backend/tests](../backend/tests) | Autenticación, límites HTTP, permisos, atomicidad, carreras, persistencia, hashes y snapshots. |

Resultados finales confirmados de aquella entrega:

| Conjunto | Resultado |
| --- | --- |
| Regresión final de Godot, 24 suites sin ventana | **22.816 comprobaciones, 0 fallos**. |
| Identidad, migración e inventario | **894 comprobaciones, 0 fallos**. |
| Editor y variantes visuales con render nativo | **1.866 comprobaciones, 0 fallos**. |
| Integración final con render nativo | **85 comprobaciones, 0 fallos**. |
| Worker + D1 local | **15 pruebas, 0 fallos**. |
| Godot → HTTP real de Wrangler | **15 comprobaciones, 0 fallos**. |
| Recorrido completo de la interfaz | **UI_SMOKE_PASS**. |

El agregado de 22.816 ya incluye la integración de identidad (80), sus casos límite (28), la integración de Historia (85), la presentación de movimientos (751) y el reloj (148); no se suman otra vez. Se usaron los resultados finales de los archivos `.log`, incluido el render nativo final, y no resultados intermedios anteriores.

Se comprobaron siete tamaños: 1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 y 844×390. Las capturas proceden de renders nativos con fixtures, sin modificar la partida del usuario.

La [verificación final](customization-validation.json) registra hashes de código y capturas, resultados de pruebas y la comparación de los guardados reales al reabrir esta versión. Los archivos de Liga e Historia permanecieron idénticos byte a byte.
