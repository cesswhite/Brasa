# Guía histórica de Brasa

Documento conservado de la entrega local. Las cifras, pruebas, rutas externas y estado de servicios describen su fecha; consulta README.md y el código para el estado del checkout actual. Algunos archivos `work/` pertenecen al entorno original y no se distribuyen.

# Brasa · Liga de los Faroles

Auto battler 2D para Mac: eliges y entrenas a tu compañero; él pelea automáticamente en un mercado nocturno ilustrado. La arena ocupa toda la ventana, con personajes animados mediante imágenes, HUD enfrentados y controles sobre un degradado transparente. Incluye quince personajes personalizables, cinco movimientos por personaje, campaña de 100 encuentros, mejoras de técnicas, talentos, progresión individual y la liga original.

## Obtener el proyecto desde GitHub

```sh
git clone https://github.com/cesswhite/Brasa.git
cd Brasa
```

Importa `project.godot` en Godot o utiliza `Jugar.command` en macOS. El repositorio incluye código, assets, backend, pruebas y documentación. Godot reconstruye su caché `.godot/` al abrirlo.

Para trabajar en el backend, consulta [backend/README.md](../backend/README.md). Sus dependencias se instalan con `npm ci` dentro de `backend/`; credenciales, secretos, bases locales y partidas personales no forman parte del repositorio. Clonar el proyecto no publica ni modifica el servidor de Cloudflare existente.

## Abrir y jugar

Requiere **Godot 4.7.2 estándar para Mac**, instalado en `/Applications/Godot.app`.

1. Abre **Jugar.command** con doble clic.
2. En una partida nueva, elige base de combate, nombre y apariencia; pulsa **Crear compañero** para entrar en Historia y repartir sus **3 puntos iniciales**.
3. Elige el encuentro y pulsa **Entrar al combate**. En Liga, usa **Entrar a la arena** o **Espacio**. Los ataques son automáticos.
4. Al terminar, abre **Resumen** para ver la experiencia de ambos y las mejoras de nivel.
5. Entrena o cambia de compañero. Cada uno conserva su nivel, XP, puntos y resultados.

**En Liga, Entrenar:** abre las cuatro mejoras. **En Historia, Mejoras:** permite repartir puntos entre ocho atributos. **Compañeros** (o **Equipo** en ventanas pequeñas): plantel y selección. **Menú:** refugio con tu luchador y acceso a Historia, Arena, Personalizar, Ficha, Historial, Registro y Cómo jugar. **Menú → Ajustes:** Sonido, Ritmo, Movimiento reducido y Pantalla completa. **Esc:** cerrar paneles. **F11:** alternar pantalla completa. **Ritmo ×2:** acelerar la reproducción, sin cambiar las reglas. Los paneles de lectura pausan el combate.

Durante la pelea, el botón principal indica **Combate automático** y el indicador de turno identifica al personaje que actúa. Los efectos temporales aparecen junto a cada luchador; el registro completo se abre desde Menú o Registro cuando está visible. **Rendirse** permanece separado y requiere confirmar. El resultado, la XP de ambos y los cambios de nivel aparecen sobre la misma arena; **Resumen** conserva el detalle completo.

La distribución se adapta a ventanas de escritorio, proporciones de tableta, móvil vertical y horizontal. El fondo conserva su proporción y se recorta para cubrir la ventana; los controles mantienen tamaños acotados. Esta entrega sigue siendo el proyecto local para Mac, sin un paquete móvil exportado.

Puedes importar `project.godot` en Godot y pulsar **F5**. Para **F6**, abre `scenes/main.tscn`.

## Personaliza a tu compañero

Abre **Menú → Personalizar** o la ficha de **Compañeros** para editar nombre, cuerpo, paleta, aura, estela, victoria y entrada. La vista previa permite probar combinaciones antes de **Guardar cambios**; cancelar conserva lo anterior. La base de combate mantiene sus técnicas y estadísticas aunque elijas otro cuerpo.

Hay **31 opciones**: 15 cuerpos, 5 paletas, 4 auras, 3 estelas, 2 victorias y 2 entradas, contando las variantes originales y sin efecto. Parte se obtiene al llegar a nivel 10, ganar 10/25 combates de Liga o superar los encuentros 8/20/50/100 de Historia. El inventario es compartido, sin compras. Los atlas actuales admiten tinte suave de toda la ilustración; no tienen capas separadas de ropa o pelo.

Cada arquetipo comparte su nombre y apariencia entre Liga e Historia, con ID estable, mientras ambos modos conservan su progresión independiente. Los nombres anteriores se preservan. La identidad se guarda aparte en `<save>.identity.json`, con respaldo y escritura atómica. Las peleas nuevas conservan nombre, apariencia y eventos: **Historial → Ver repeticiones** muestra aquella versión del compañero sin conceder XP ni cambiar el progreso.

La identidad anterior se adapta a v2 para incluir los dos cuerpos de gato. Conserva nombres, IDs, equipo y recompensas; cargar no reescribe archivos y el siguiente guardado conserva una copia v1. [Compatibilidad y pruebas](../reports/CAT_IDENTITY_MIGRATION.md).

**Arena online** está publicado en un [servidor de pruebas de Cloudflare](https://brasa-api-staging.acessloop.workers.dev/auth), con passkeys, luchadores persistentes, rivales de otras cuentas, historial y resultados defensivos. Arena e Historia online comparten progresión; los guardados locales permanecen independientes. El acceso, Arena e Historia pasaron las pruebas remotas. El usuario activó Workers Paid, confirmado en Cloudflare, y la verificación remota se repitió correctamente bajo ese plan: 32 comprobaciones de acceso y 60 de juego y revocación.

Para entrar, abre `Jugar online.command` o **Arena online** en el menú y pulsa **Iniciar sesión en el navegador**. Usa **Crear cuenta con passkey** o **Entrar con mi passkey**, confirma en tu dispositivo, compara el código y pulsa **Autorizar este dispositivo**. Al volver al juego podrás crear tu luchador. **Historia** permite jugar aunque todavía no haya rivales públicos. Consulta los [pasos de acceso](../backend/docs/AUTH.md#entrar-desde-godot) y el [estado de Cloudflare](../reports/CLOUDFLARE-STAGING.md). La personalización local se documenta en [PERSONALIZACIÓN](../reports/PERSONALIZACION.md).

## Modo Historia · 100 encuentros

Historia usa escenarios ilustrados: camino de faroles, patio de la tormenta, taller de entrenamiento, refugio y archivo de legados. El rival domina la vista previa, los encuentros forman una ruta conectada y los controles conservan texto nativo. Pequeñas pertenencias y recuerdos aparecen según apariencia y progreso. El [informe visual](../reports/UI-WORLD.md) reúne la comparación, capturas y validación; [dirección de arte y prompts](../assets/ui/ART-DIRECTION.md) documenta las siete imágenes nuevas.

Historia también es la autoridad visual del juego completo. Menú, Arena, Online, creación, fichas, mejoras, compañeros, resultados, repeticiones y ajustes reutilizan `GameVisualSystem`, sus tokens y componentes. Consulta la [biblia visual](../reports/VISUAL-STYLE-BIBLE.md), la [auditoría por pantalla](../reports/VISUAL-SCREEN-AUDIT.md) y el [muro interactivo Antes/Después](../reports/visual-system/index.html). Los datos del muro son fixtures locales; las pantallas conservan los flujos reales de identidad, progreso y servidor.

Abre **Historia**, junto a Menú. Cada compañero comienza una campaña independiente en nivel 1, con sus estadísticas normales, tres puntos y dos técnicas. La liga conserva su propia progresión.

La ruta contiene **100 encuentros en 11 capítulos**. Los primeros dos mantienen sus ocho encuentros, Ascua y Véspera; Nima sigue en nivel 2. El tercer capítulo cubre los encuentros 17–20 y los demás diez cada uno. Hay jefes en 8, 16, 20, 30, 40, **50**, 60, 70, 80, 90 y **100**, además de élites entre ellos. Ascua regresa como Corazón del Solsticio en el 50; Véspera cierra la campaña como El último eclipse.

El mapa distingue **encuentro de Historia** y **nivel del personaje**, permite consultar capítulos y muestra el próximo jefe y recompensa. Las vistas previas explican estilo, fortalezas, debilidades, técnicas y habilidad. Algunos encuentros normales eligen entre rivales compatibles; la elección se conserva durante esa campaña, también al reabrir el juego o reintentar. Los jefes tienen identidad fija.

**Mejoras** ofrece ocho atributos: Vida, Ataque, Defensa, Velocidad, Precisión, Evasión, Crítico y Resistencia. Subir hasta el nivel 20 concede tres puntos por nivel; después, dos. Las élites de los dos primeros capítulos conservan sus dos puntos adicionales. Las partidas anteriores mantienen todos los puntos que ya habían ganado.

**Movimientos** explica las cinco técnicas del personaje y sus riesgos. Comienza con dos y desbloquea las otras en niveles de personaje **5, 12 y 20**. Las fichas de los encuentros **5, 10, 20, 30, 40, 50, 60, 70, 80 y 90** permiten mejorar las técnicas hasta dos grados. Los encuentros **10, 30 y 50** conceden una elección de talento: puedes elegir tres entre seis opciones vinculadas al personaje.

En **Mejoras → Redistribuir mejoras** puedes recuperar los puntos, fichas y elecciones que ya gastaste para desarrollar otra estrategia. Requiere confirmar dentro del juego; conserva nivel, XP, ruta e historial de capítulos. No crea recursos nuevos.

Las victorias dan más XP que las derrotas. Las derrotas completas permiten seguir mejorando y generan una pista basada en fallos, ritmo, críticos o estados de esa pelea. Rendirse y repetir derrotas reducen la recompensa. Puedes volver a jugar encuentros superados como **práctica sin XP ni premios adicionales**.

Cada cierre de capítulo queda en **Legado**, con estadísticas, decisiones e insignia. La transición al capítulo siguiente es explícita. Los jefes obedecen las mismas reglas y límites; las fases de los jefes especiales están descritas y anunciadas durante el combate.

Historia se guarda en `~/Library/Application Support/BrasaLiga/brasa_save.json.story.json`. El formato v3 lee los formatos v1/v2 sin escribir al abrirlos ni avanzar capítulos. Antes de la primera escritura conserva una copia permanente `.v1.bak` o `.v2.bak`, además del respaldo habitual y escritura atómica. Las pruebas usan copias y archivos independientes.

## Audio · primer escenario

El primer banco dirigido cubre **Ascua y Patio de Faroles** con 51 archivos seleccionados de ElevenLabs: movimiento, contacto, guardia, críticos, carbón, transformación, Firma, KO, resultados, confirmación, ambiente y música original. Los sonidos físicos compartidos también acompañan a los otros luchadores; sus poderes propios y los demás ambientes siguen en el plan de producción. Los sonidos se activan por los eventos y marcadores reales del combate, también en las repeticiones y Arena Online. La revisión de realismo sustituye contacto, movimiento y ambiente, conserva la velocidad natural de las grabaciones y reduce los roces y las capas de fuego.

**Menú → Ajustes** permite guardar los volúmenes General, Música y Efectos. Silenciar conserva esos valores. La pausa detiene las nuevas acciones sonoras, y Movimiento reducido conserva el audio. La mezcla separa música, ambiente, movimiento, contacto, UI y reacciones, con variaciones y prioridades.

Consulta la [biblia y plan de audio](../reports/AUDIO-BIBLE.md), la [entrega y validación](../reports/AUDIO-DELIVERY.md) y el [comparador con grabación real del combate](../reports/audio-asset-review.html). Las mediciones técnicas no sustituyen la revisión auditiva; la producción del resto del plantel está documentada para la siguiente etapa.

## Técnicas y animación

Cada técnica tiene datos de daño, precisión, prioridad, crítico, estados, enfriamiento, preparación, desplazamiento, recuperación, riesgo y desbloqueo. La selección automática considera vida, velocidad relativa, estados, enfriamientos y movimientos anteriores, con variación aleatoria.

Los golpes rápidos sirven para mantener presión; los fuertes tienen anticipación y recuperación largas. Las cargas retroceden antes de avanzar. Los saltos usan distintas trayectorias y ventajas. Las posturas defensivas pueden reducir el daño y provocar respuestas probabilísticas. Las habilidades originales siguen activas; el Golpe Firma es independiente de las técnicas normales.

El motor envía preparación e impacto por separado: el daño se aplica al contacto. Las réplicas pueden animarse junto a otro ataque sin borrar su preparación. **Ritmo ×2** acelera simulación y animación juntas. **Menú → Ajustes → Movimiento reducido** conserva las poses y tiempos sin desplazamientos, destellos ni partículas. Abrir el menú pausa ambos luchadores y el combate.

Los quince compañeros y ambos jefes tienen ahora secuencias de anticipación, ataque, seguimiento y recuperación, con reacciones distintas para golpes rápidos, pesados, críticos, cargas y firmas. El KO comienza en el evento letal, también por veneno o quemadura. Polvo, estelas e impactos se componen como efectos independientes. Ascua dispone de una transformación visual temporal. El [informe de animación](../reports/ANIMATION-SEQUENCES.md) incluye el video, los primeros 480 fotogramas adicionales, sus prompts y las comprobaciones. Con los dos gatos, el plantel suma **544 poses adicionales en 34 bancos**; la ampliación se documenta en [GATOS.md](../reports/GATOS.md).

Las cargas, impactos, auras y entradas usan ahora **partículas orgánicas**: brasas, motas y polvo que siguen la pose y se desprenden con el movimiento. La luz se integra en la silueta y los círculos de energía dejan de mostrarse. [Comparación y validación](../reports/EFECTOS-ORGANICOS.md).

## Quince maneras de pelear

| Compañero | Identidad | Ventaja y contrapartida |
| --- | --- | --- |
| Nima | Velocidad y combos | Presiona con su secuencia; tiene poca defensa. |
| Luma | Equilibrio y adaptación | Mejora la precisión tras fallar; no tiene una especialidad explosiva. |
| Mugo | Tanque resistente | Aguanta y amortigua críticos; ataca despacio. |
| Sira | Críticos | Sus críticos atraviesan parte de la defensa; soporta pocos golpes. |
| Iria | Veneno | Acumula desgaste; necesita tiempo y tiene daño directo bajo. |
| Duna | Escudos | Bloquea daño periódicamente; ejerce poca presión inicial. |
| Kiro | Riesgo y furia | Gana daño al perder vida; puede fallar en el momento decisivo. |
| Neris | Recuperación | Se cura una vez cuando baja de vida; la curación puede debilitarse. |
| Taro | Contraataques | Castiga ataques recibidos; sus réplicas son probabilísticas. |
| Balam · Jaguar | Acecho y cargas | Castiga con golpes fuertes y críticos; necesita preparar sus ataques. |
| Tepa · Teporingo | Saltos y velocidad | Cambia de trayectoria y presiona rápido; tiene poca vida y defensa. |
| Xuna · Xoloitzcuintle | Guardia y desgaste | Resiste críticos y mantiene quemaduras; tarda en imponer su ritmo. |
| Copal · Cacomixtle | Fintas y réplicas | Combina desplazamientos, engaños y contraataques; sus respuestas no están garantizadas. |
| Ónix · Gato negro | Velocidad y evasión | Presiona con combos y esquivas; tiene poca vida y defensa. |
| Bruma · Gato gris | Precisión y contraataques | Mantiene el ritmo y responde a los golpes; tiene menos evasión. |

Los nueve compañeros originales conservan sus apariencias propias: Nima es un lince; Luma, un ajolote; Mugo, un gólem; Sira, una mantis; Iria, una rana botánica; Duna, un armadillo; Kiro, un jabalí; Neris, una garza; y Taro, un tejón. Ascua tiene un diseño exclusivo de guardián volcánico con cuernos, cola y núcleo ámbar. Véspera, la jefa del segundo capítulo, es una polilla lunar con alas índigo y plata.

Balam, Tepa, Xuna y Copal añaden cuatro animales vinculados con México, con ilustraciones propias, cinco técnicas, seis opciones de talento y un Golpe Firma individual. Están disponibles desde **Compañeros** en la liga y **Historia → Compañeros** para iniciar campañas independientes. Las partidas anteriores conservan sus personajes activos y su progreso. El arte, los prompts y las referencias están en [assets/sprites/FAUNA-MEXICANA.md](../assets/sprites/FAUNA-MEXICANA.md).

**Ónix**, gato negro de ojos amarillos, y **Bruma**, gato gris de ojos verdosos, tienen cada uno cinco técnicas, seis talentos y 40 poses ilustradas. Se eligen en Liga e Historia y conservan progresión individual. Sus diseños, pruebas y prompts están en [reports/GATOS.md](../reports/GATOS.md).

Cada personaje conserva sus ocho poses PNG originales con transparencia: reposo, respiración, preparación, golpe, impacto, esquiva, victoria y derrota. Se añaden **32 poses por cuerpo**, distribuidas en dos atlas transparentes, para los **17 cuerpos** del juego. Las habilidades y el progreso conservan su identidad original. Las secuencias y su procedencia están en [assets/sprites/sequences/manifest.json](../assets/sprites/sequences/manifest.json). Los siete diseños originales y sus prompts están en [assets/sprites/PERSONAJES-V3.md](../assets/sprites/PERSONAJES-V3.md); los tres primeros atlas, en [assets/sprites/PROMPTS.md](../assets/sprites/PROMPTS.md); el fondo y su procedencia, en [assets/ARTE.md](../assets/ARTE.md).

## Estadísticas, probabilidades y efectos

Las estadísticas provienen de una única definición por personaje: base de nivel uno, crecimiento propio y entrenamiento adquirido. Los efectos de pelea modifican una copia temporal. El entrenamiento conserva cuatro controles, con límite de 30 por valor: Vida añade 20 PV; Fuerza añade 1.5 de ataque; Agilidad mejora evasión y crítico; Velocidad acorta el intervalo entre acciones.

| Estadística | Efecto y límites |
| --- | --- |
| Vida | 100–2000 PV. Se recupera al comenzar una pelea. |
| Ataque | 5–150 antes de defensa y modificadores. Variación normal de ±8%. |
| Defensa | 0–160. Daño recibido × `100 / (100 + defensa)`. |
| Velocidad | 1–36. Intervalo `2.4 / (1 + velocidad × 0.035)` segundos. |
| Precisión | Se enfrenta a evasión. Probabilidad final de acertar entre 62% y 96%. |
| Evasión | 0–30%; reduce la posibilidad de recibir el golpe. |
| Crítico | 3–32% al conectar. Se calcula separado del acierto. |
| Daño crítico | Multiplicador ×1.2–×2.1; no se combina con la firma. |
| Resistencia | 0–50%; reduce aplicación o duración de estados negativos. |

No se incluye Suerte: duplicaría otras probabilidades sin ofrecer una decisión distinta. Un valor interno de poder ayuda a emparejar rivales y nunca multiplica el daño. Los niveles añaden crecimiento gradual; después del nivel 20 se aplica el 45% del crecimiento normal. Los rivales se buscan cerca del nivel y poder del compañero activo.

Cada luchador tiene una habilidad propia y un **Golpe Firma** separado: se realiza una sola tirada de **1% al comenzar cada combate**, nunca una tirada por ataque. Si sale, se programa para una de sus primeras acciones. Solo puede ocurrir una vez, siempre conecta, hace aproximadamente **×1.6** del daño normal y aplica un efecto negativo con duración explícita. La resistencia puede acortar la firma, pero no anularla. Una pelea que termine antes de la acción prevista puede impedir verla.

Los estados incluyen tipo, magnitud, fuente, duración, turnos restantes y regla de acumulación. El tiempo de un estado se mide en **acciones propias del personaje afectado**. Las aplicaciones repetidas refrescan, reemplazan o acumulan intensidad según su definición; los límites y la caducidad se aplican en el módulo común. La vida, los escudos y los turnos restantes aparecen en la arena; Registro explica los eventos.

El combate termina al agotar la vida o por rendición. A los **60 segundos** gana quien conserve mayor proporción de vida. Los empates exactos se resuelven de forma reproducible con el RNG del combate. Los mejores números mantienen ventaja estadística, con resultados ocasionalmente inesperados.

## Experiencia y rendición en la liga

Se necesitan `55 + (nivel − 1) × 25` XP para subir. La XP sobrante se conserva y cada nivel entrega **2 puntos** además del crecimiento particular del personaje. El nivel máximo es **50**; la experiencia posterior sigue contando para su trayectoria.

En nivel uno, las recompensas base son **40 XP por victoria**, **25 por derrota** y **8 por rendición**. Aumentan un 16% del valor base por nivel. Partidas muy cortas y repeticiones reducen la recompensa correspondiente. El ganador por rendición recibe una victoria normal; quien abandona recibe **al menos 1 XP**. Una breve pausa de cuatro segundos tras rendirse limita la obtención de XP mediante abandonos instantáneos. Los rivales también conservan XP y suben de nivel en perfiles separados del plantel del jugador.

**Rendirse** requiere confirmar. Mientras decides, la simulación está pausada. Al confirmar, el motor termina inmediatamente: no hay ataques posteriores ni recompensas duplicadas. El historial distingue la rendición de una derrota normal y actualiza victorias, derrotas y rachas.

## Guardado de la liga y compatibilidad

El guardado local automático se encuentra en:

```text
~/Library/Application Support/BrasaLiga/brasa_save.json
```

La versión 2 guarda el plantel, compañero activo, rivales, historial y controles de recompensas. Migra la versión anterior conservando nombre, nivel, XP, entrenamiento, puntos y resultados, y crea un respaldo antes de escribir. Usa escritura temporal y reemplazo atómico. Un archivo corrupto o de una versión desconocida se protege para evitar sobrescribir progreso que no se pueda interpretar.

Los modos locales no requieren cuenta, Internet ni compras. Arena online requiere conexión y una cuenta con passkey; los duelos son asíncronos y automáticos, sin conexión simultánea de los participantes. Los cosméticos no alteran estadísticas.

## Arquitectura y pruebas

| Archivo | Responsabilidad |
| --- | --- |
| `scripts/balance.gd` | Curvas, probabilidades, caps, XP y constantes globales. |
| `scripts/move_catalog.gd` | Técnicas, desbloqueos, grados, talentos y pesos de selección. |
| `scripts/campaign_config.gd` | Capítulos, presupuestos, variantes, jefes, recompensas e hitos. |
| `scripts/character_catalog.gd` | Quince definiciones, ayudas y cálculo de estadísticas/poder. |
| `scripts/combat_rules.gd` | Cálculos comunes de acierto, crítico y daño. |
| `scripts/status_effects.gd` | Efectos temporales, acumulación, resistencia y expiración. |
| `scripts/combat_engine.gd` | Estado autoritativo, iniciativa, RNG con semilla, eventos y resumen. |
| `scripts/progression.gd` | Plantel, rivales, entrenamiento, XP, historial, migración y guardado. |
| `scripts/main.gd` | Arena, flujo, paneles, feedback y audio. |
| `scripts/ui/battle_layout.gd` | Distribución adaptable del HUD, personajes, controles y resultados. |
| `scripts/story_catalog.gd` | Capítulos, rutas, perfiles de rivales, atributos, jefes y pistas basadas en combate. |
| `scripts/story_progression.gd` | Campañas, transición de capítulos, legados, puntos, XP, reintentos y migración de Historia. |
| `scripts/ui/story_panel.gd` | Ruta, vista previa, mejoras, elección de campaña y legado. |
| `scripts/ui/world_visuals.gd` | Registro de entornos, superficies reutilizables y condiciones decorativas. |
| `scripts/ui/world_backdrop.gd` | Fondo bajo demanda, objetos ambientales y contraste; sin lógica de juego. |
| `data/ui_visual_manifest.json` | IDs de assets, regiones de atlas, nueve segmentos, temas y props. |
| `scripts/ui/roster_panel.gd` | Selección y fichas generadas desde el catálogo. |
| `scripts/fighter_view.gd` | Atlas, poses, anclajes, orientación y variantes visuales. |
| `scripts/fighter_animation_set.gd` | Secuencias por fases, reacciones, transformaciones visuales y caché de atlas. |
| `scripts/combat_fx.gd` | Impactos, polvo, estelas, energía y desplazamiento breve de cámara. |
| `data/combat_fx.json` | Regiones y duración de los ocho efectos transparentes. |
| `scripts/fighter_identity.gd` | Identidad compartida, inventario cosmético, migración y guardado independiente. |
| `scripts/cosmetic_catalog.gd` | Categorías, opciones, compatibilidad y requisitos; export canónico JSON. |
| `scripts/ui/customization_panel.gd` | Creador y editor visual con borrador, vista previa y confirmación. |
| `scripts/battle_identity.gd` | Nombre y apariencia históricos junto con los eventos de combate. |
| `scripts/identity_api.gd` | Adaptador opcional de la API local, sin sincronización automática. |
| `scripts/arena_view.gd` | Fondo, luces y partículas. |

La regresión final de personalización supera **22.816 comprobaciones en 24 suites, sin fallos**, más el recorrido **UI_SMOKE_PASS**. Las pruebas nativas, de identidad y del servicio local se detallan en [PERSONALIZACIÓN](../reports/PERSONALIZACION.md).

Las pruebas usan archivos separados; nunca la partida real. Desde esta carpeta, con Godot instalado:

```sh
BRASA_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$BRASA_GODOT" --headless --path . --script res://tests/test_fighter_identity.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_identity_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_identity_edges.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_customization_visuals.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_core.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_sprites.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_distinct_sprites.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_mexican_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_mexican_roster_ui.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_cat_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_cat_roster_ui.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_cat_identity_migration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_battle_layout.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_progression.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_combat.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_campaign.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_panel.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_progression_v2.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_combat_v2.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_moves.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_move_presentation.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_move_clock.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_animation_sequences.gd -- --require-roster
"$BRASA_GODOT" --headless --path . --script res://tests/test_combat_fx.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_status_ko_presentation.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_campaign100.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_campaign100_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_campaign_ui.gd
"$BRASA_GODOT" --headless --path . --script res://tests/test_story_chapter_integration.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_campaign100.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_mexican_roster.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_cat_roster.gd
"$BRASA_GODOT" --headless --path . -- --smoke-test
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_balance.gd
"$BRASA_GODOT" --headless --path . --script res://tests/simulate_story.gd
```

`--smoke-test` recorre plantel, entrenamiento, firma forzada de prueba, combate, recompensa única, resumen, historial, ficha, revancha, rendición cancelada/confirmada y recarga. Su guardado está en `work/ui_smoke_save_<sesión>.json`, fuera de la partida del jugador. También admite `--save-path=/ruta/absoluta/archivo.json`. Quita `--headless` para observarlo en ventana.

El motor acepta una semilla opcional para reproducir errores sin depender de la tasa de fotogramas. Las opciones de forzar firma están destinadas únicamente a pruebas; las partidas normales usan la probabilidad del catálogo. Las simulaciones y su informe se incluyen junto a las pruebas para volver a medir el balance al modificar datos.

La ampliación a trece personajes y su validación están en [reports/FAUNA-MEXICANA.md](../reports/FAUNA-MEXICANA.md), y su balance está en [reports/MEXICAN_ROSTER_BALANCE.md](../reports/MEXICAN_ROSTER_BALANCE.md). La validación de los 100 encuentros con los nueve personajes originales está en [reports/CAMPANA-100.md](../reports/CAMPANA-100.md), con pruebas de integración, migración, movimiento y capturas.

Los informes [VALIDACION](../reports/VALIDACION.md), [INTERFAZ](../reports/INTERFAZ.md), [HISTORIA](../reports/HISTORIA.md), [STORY_BALANCE](../reports/STORY_BALANCE.md) y [CAPITULO-2](../reports/CAPITULO-2.md) documentan entregas anteriores; sus resultados de combate preceden al sistema de cinco técnicas. El arte y sus prompts siguen documentados en [PERSONAJES](../reports/PERSONAJES.md) y [assets/CAPITULO-2.md](../assets/CAPITULO-2.md).
