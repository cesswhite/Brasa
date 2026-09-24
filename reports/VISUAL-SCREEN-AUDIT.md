# Brasa · Inventario y auditoría de pantallas

## Estado más reciente · 22 de septiembre de 2026

La revisión actual cubre **42 estados, 84 capturas nativas**, partiendo de las 37 vistas de la revisión de rendimiento y añadiendo Color, Efectos, Estilo y dos subsecciones online. Incluye ayuda por temas, resumen plegable, ficha online por secciones, acciones con costes explícitos, más espacio útil en móvil y resultado móvil por encima de los personajes.

- [Análisis y cambios por pantalla](UX-REVIEW.md) · [Comparador Antes / Después](ux-review/index.html).
- [Escritorio](../../../work/ux-review/after/wall-1360x880.png) · [Móvil](../../../work/ux-review/after/wall-390x844.png) · [Manifiesto](../../../work/ux-review/after/screens.json).
- Validación: **26 suites de aceptación, 28,718 comprobaciones sin fallos**, más 153 comprobaciones de captura sin fallos. Las limitaciones de dos suites antiguas y la comparación con la versión previa están documentadas en el informe.
- Perfiles desechables; Online en memoria sin HTTP. No es una validación de producción. La captura anterior de Talentos apuntaba a Técnicas: ahora muestra la subsección correcta y se avisa en el comparador.

Lo que sigue conserva el inventario histórico del 20 de septiembre y las revisiones posteriores; sus cifras y puntuaciones no sustituyen la evidencia actual.

---

**Las 37 superficies auditadas ya comparten la familia visual de Historia.** La entrega reúne 74 capturas finales de escritorio/móvil, 72 anteriores y un tablero comparativo local. La base tenía cuatro familias de controles aisladas; la migración unifica materiales, tipografía y composición, conservando las reglas y las rutas existentes.

Fecha: 20 de septiembre de 2026. Esta auditoría distingue la **base anterior a las migraciones** del seguimiento posterior. Los archivos de producción pueden cambiar durante el trabajo; las puntuaciones iniciales se refieren a las capturas y fuentes congeladas, no a una versión móvil del repositorio.

## Evidencia y método

- [Muro de escritorio, 36 estados](../../../work/visual-system/before/wall-1360x880.png) y [muro móvil, 36 estados](../../../work/visual-system/before/wall-390x844.png).
- [Manifiesto de las 72 capturas](../../../work/visual-system/before/screens.json), [log nativo](../../../work/visual-system/audit-native.log), [fuentes anteriores](../../../work/visual-system/source-before/scripts/main.gd) y [manifiesto visual anterior](../../../work/visual-system/source-before/ui_visual_manifest.json).
- [Harness reutilizable](../tests/test_visual_screen_audit.gd): **123 comprobaciones, 0 fallos**, 72 capturas de pantalla y dos muros. Resoluciones capturadas: 1360×880 y 390×844. No implica cobertura visual de todos los tamaños de los otros tests.
- Render directo de Godot mediante SubViewport. Main usa archivos nuevos en `work/visual-system/fixtures`; Historia usa un modelo en memoria y Online un mock sin HTTP. No se abren perfiles reales, navegador, red, Cloudflare ni autenticación.
- Los resultados de combate usan el motor real con HP inicial sintético para conseguir victoria y derrota. Son fixtures etiquetados, no una grabación de partidas naturales. Las repeticiones leen esos eventos conservados.
- Diferencia metodológica: la base esperó dos fotogramas y sus resultados pueden mostrar opacidad intermedia durante la entrada. Las capturas finales esperan además **0.3 segundos reales**; para los resultados avanzan **1.2 segundos sólo la presentación Node2D**, manteniendo Main/motor manuales y verificando que eventos y progreso no cambian, y después congelan. Exigen alfa ≥ .999 y registran `settled_visuals` y el valor de alfa. No se fuerza ninguna pose ni se reemplaza la base. Es un muro de UI asentada, no una grabación de animación natural; esta diferencia no debe atribuirse a una mejora del diseño.
- [Tablero HTML local](visual-system/index.html): referencia fija de Historia, filtros, Antes/Después y zoom a tamaño original. Contiene los 36 estados base y el nuevo estado independiente Ajustes: 74/74 Después, sin huecos. Ajustes no tiene Antes propio porque sus controles estaban dentro de Menú; esa ausencia se explica sin fabricar una captura.

La revisión agrupa jerarquía, color, tipografía, espaciado, alineación, repetición, contraste y acabado en cinco ejes puntuados de 0 a 4. Cada punto vale cinco puntos del total, que va de 0 a 100:

| Eje | Qué se compara con Historia |
| --- | --- |
| M · Mundo | Lugar ilustrado, luz y conexión del personaje con el entorno. |
| S · Superficies | Materiales, controles, selección, foco y estados de una familia común. |
| T · Tipografía | Titular narrativo, cuerpo legible y jerarquía consistente. |
| C · Composición | Protagonista claro, agrupación, aire y prioridad de acciones. |
| N · Navegación | Continuidad entre vistas, acceso móvil, scroll y rutas reconocibles. |

0 = ausente o contradictorio; 1 = coincidencia de color aislada; 2 = parcial; 3 = mayormente coherente con una diferencia concreta; 4 = referencia o equivalencia clara. Son juicios comparativos de diseño, **no una certificación de accesibilidad, rendimiento o corrección funcional**. Un HUD compacto puede conservarse aunque no use toda la decoración de Historia. Los estados de foco y pulsación requieren pruebas propias, además de una captura estática.

**KEEP** conserva la solución; **ADAPT** conserva estructura y aplica la familia compartida; **REDESIGN** recompone prioridades usando los datos y arte existentes. Ninguna decisión autoriza cambios de economía, cuentas, combate o guardado.

## Inventario puntuado de la base

Los IDs coinciden con el harness y los PNG: `ID-1360x880.png` / `ID-390x844.png`, en la [carpeta de base](../../../work/visual-system/before). Las rutas exactas y el tipo de fixture están en `screens.json`. Cada fila incluye la pieza que debería compartirse, el arte reutilizable y la intervención propuesta.

| ID / pantalla | Sistema anterior | M/S/T/C/N → total | Inconsistencia y refactor propuesto | Decisión |
| --- | --- | --- | --- | --- |
| `story-route` · Ruta | StoryPanel + WorldBackdrop/WorldVisuals | 4/4/4/4/4 → 100 | Referencia de fondo, rival, fortalezas, ruta y CTA. Conservar contextos journey/storm y paginación. | KEEP |
| `story-upgrades` · Taller | StoryPanel, fondo workshop | 4/4/4/4/4 → 100 | Referencia de atributos abiertos, impacto y acción; reutilizar cabecera y filas de estadísticas. | KEEP |
| `story-respec` · Confirmar redistribución | Diálogo local de Story, panel plano | 3/2/3/3/4 → 75 | El cuadro interior tiene otro acabado. Pasarlo al diálogo común sin cambiar confirmación ni devolución de puntos. | ADAPT |
| `story-moves` · Movimientos | StoryPanel, workshop tintado | 4/4/4/4/4 → 100 | Conservar técnica, propósito, riesgo, requisito y mejora limitada; compartir filas legibles con Online. | KEEP |
| `story-perks` · Talentos | Sección desplazada de Movimientos | 4/4/4/3/4 → 95 | La densidad pide preservar scroll y distinción entre disponible/elegido; no añadir tarjetas ornamentales por talento. | KEEP |
| `story-companions` · Refugio | StoryPanel, camp | 4/4/4/4/4 → 100 | Referencia para lista de compañeros, protagonista y biografía; conservar perfiles individuales. | KEEP |
| `story-legacy` · Legado pendiente | StoryPanel, archive | 4/4/4/3/4 → 95 | Estado vacío ya pertenece al archivo; conservar explicación y acceso a campañas. | KEEP |
| `story-legacy-complete` · Legado ganado | StoryPanel, archive + trofeos | 4/4/4/4/4 → 100 | Referencia de logro y estadísticas congeladas; no recalcular recuerdos desde el equipo actual. | KEEP |
| `arena-idle` · Preparación | Main + ArenaView, botones planos | 4/1/2/3/3 → 65 | Mundo y figuras funcionan; cabecera y acciones no comparten materiales. Adaptar HUD/botones conservando BattleLayout. | ADAPT |
| `menu` · Menú y ajustes originales | Documento Main, cuadrícula plana | 1/1/2/1/3 → 40 | Gran panel vacío, destinos y ajustes tienen igual peso. Recomponer como refugio con personaje y destino principal; separar Ajustes. | REDESIGN |
| `training` · Entrenamiento Liga | Documento Main y cuatro tarjetas | 1/1/2/2/3 → 45 | El progreso parece un formulario aislado. Reutilizar taller y filas de atributos; conservar las cuatro mejoras propias de Liga. | REDESIGN |
| `profile` · Ficha Liga | Documento RichTextLabel | 1/1/2/2/3 → 45 | Mucho texto sin figura ni jerarquía de ficha. Compartir retrato, títulos y estadísticas; seguir disponible durante combate en lectura. | REDESIGN |
| `help` · Manual | Documento Main | 1/1/2/3/3 → 50 | Lectura funcional con acabado ajeno. Diálogo de lectura común, títulos narrativos y ancho cómodo; mantener scroll. | ADAPT |
| `history-empty` · Historial vacío | Documento Main | 1/1/2/1/3 → 40 | Espacio plano sin contexto de recuerdo. Reusar archivo y estado vacío breve; conservar cierre directo. | ADAPT |
| `log-empty` · Registro vacío | Documento Main | 1/1/2/1/3 → 40 | Explicación útil dentro de un panel desproporcionado. Usar documento común y estado vacío compacto. | ADAPT |
| `roster` · Compañeros Liga | RosterPanel, tema local plano | 2/1/2/3/3 → 55 | Arte pequeño y ficha densa frente al Refugio. Reutilizar camp, retrato dominante y selección común; preservar 15 perfiles y ficha móvil. | REDESIGN |
| `customization` · Personalizar | CustomizationPanel, tema local | 2/1/2/3/3 → 55 | Buen eje figura/opciones, pero parece otra herramienta. Compartir workshop, tabs, campos, selección y aviso; conservar inventario y validación. | ADAPT |
| `arena-active` · Combate | Main + ArenaView + FighterView + CombatFX | 4/1/2/3/3 → 65 | Siluetas y FX pertenecen al mundo; controles y tipografía divergen. Adaptar chrome sin tapar HUD, caras o reloj. | ADAPT |
| `surrender` · Rendirse | Documento Main con dos acciones | 1/1/2/3/3 → 50 | Correcta confirmación funcional, material ajeno. Diálogo común; conservar opción segura, pausa y consecuencias escritas. | ADAPT |
| `result-victory` · Victoria | Resultado sobre Arena en Main | 4/1/2/2/3 → 60 | Resultado y recompensa tienen poca presencia narrativa. Cabecera/insignia compartidas, conservando figuras y acción siguiente. | ADAPT |
| `result-defeat` · Derrota | Resultado sobre Arena en Main | 4/1/2/2/3 → 60 | Misma oportunidad de jerarquía; conservar pista, XP y reintento sin ocultar información bajo decoración. | ADAPT |
| `summary` · Resumen | Documento Main | 1/1/2/3/3 → 50 | Bloque textual aislado. Reusar documento y filas de cifras, manteniendo datos exactos del combate terminado. | ADAPT |
| `history` · Historial con combates | Documento Main | 1/1/2/2/3 → 45 | Lista de recuerdos en una caja genérica. Archivo + fila de combate + acción Ver repetición; conservar orden y snapshots. | ADAPT |
| `log` · Registro con acciones | Documento Main | 1/1/2/3/3 → 50 | La lectura es adecuada; sólo requiere material y jerarquía comunes. No convertir cada evento en una gran tarjeta. | ADAPT |
| `replay` · Repetición local | BattleReplayPanel + ArenaView | 4/1/2/3/3 → 65 | El combate se ve Brasa y el contenedor no. Compartir cabecera, selector y transporte; conservar reloj, pausa y lectura histórica. | ADAPT |
| `online-arena` · Rivales online | OnlinePanel, tema local plano | 1/1/2/2/3 → 45 | Columna de perfil pequeña y lista tipo herramienta. Arena compartida, retrato/fila rival y CTA; conservar autoridad del servidor. | REDESIGN |
| `online-story` · Historia online | OnlinePanel, panel de texto | 1/1/2/2/3 → 45 | Ruta pierde representación y contexto de Historia. Adaptar su preview/ruta a datos remotos sin simular progreso local. | REDESIGN |
| `online-profile` · Mi ficha | OnlinePanel, controles propios | 1/1/2/2/3 → 45 | Atributos y crecimiento dispersos. Compartir ficha/taller manteniendo revisión y errores del servidor. | REDESIGN |
| `online-perks` · Talentos y estilo | Sección desplazada de Mi ficha | 1/1/2/2/3 → 45 | Mismos conceptos que Historia con otro acabado. Compartir filas, selección y confirmación; preservar elecciones limitadas. | ADAPT |
| `online-activity` · Actividad | OnlinePanel, listas planas | 1/1/2/2/3 → 45 | Historial y resultados offline necesitan familia de archivo. Mantener origen remoto, estados vacíos y acceso al replay. | REDESIGN |
| `online-empty` · Sin rivales | OnlinePanel, mensaje y actualizar | 1/1/2/2/3 → 45 | Estado útil pero desconectado del patio. Contexto de Arena y acción secundaria común; no inventar rivales. | ADAPT |
| `online-create` · Crear luchador online | OnlinePanel, selector/campo plano | 2/1/2/2/3 → 50 | Figura y formulario carecen de lugar. Compartir creador/preview y controles, conservando creación remota explícita. | REDESIGN |
| `online-replay` · Combate online | BattleReplayPanel desde Online | 4/1/2/3/3 → 65 | Mismo refactor de replay local; no recompensar al reproducir ni rehacer eventos. | ADAPT |
| `online-login` · Acceso | OnlinePanel, texto centrado | 0/1/2/2/3 → 40 | Se pierde el mundo antes de entrar. Fondo de refugio, cabecera y CTA; conservar flujo real de acceso en navegador. | REDESIGN |
| `online-device` · Autorizar dispositivo | Estado de OnlinePanel | 0/1/2/2/3 → 40 | Código/espera quedan en un vacío. Agrupar instrucción, código, estado y cancelar; no ocultar expiración o rechazo. | ADAPT |
| `creation` · Primera creación | CustomizationPanel desde Main | 2/1/2/3/3 → 55 | Buena preview pero formulario separado del mundo. Compartir taller y controles; distinguir crear de editar y conservar entrada a Historia. | ADAPT |

## Superficies y variantes fuera de las 72 capturas

| Superficie | Cobertura de esta auditoría | Tratamiento |
| --- | --- | --- |
| Ajustes | En la base estaba dentro de Menú. La migración lo separa en `_show_settings()` con sonido, ritmo, movimiento y pantalla completa. Nuevo ID de captura `settings`. | ADAPT como modal común, conservando los cuatro comportamientos. |
| Estados de control | Código de normal, hover, pulsado, seleccionado, deshabilitado y foco; muestrario independiente ya existente. No se capturó cada combinación en cada página. | WorldVisuals/GameVisualSystem deben ser la única familia. |
| Guardado bloqueado/error, error de red, reintento, nombre inválido, inventario bloqueado | Inventariados en sus paneles y pruebas existentes; no forzados todos en la base visual. | Mensaje visible junto a su acción; semántica y validación intactas. |
| Tooltip, OptionButton y listas largas | Cobertura de fuente; algunas listas se capturaron arriba y abajo. No todos los desplegables ni posiciones de scroll. | Tipografía, foco, contraste y zonas táctiles compartidos. |
| Jefes, capítulo 100, recompensas, talentos pendientes y legado anterior | Fixtures y tests específicos existentes; la base sólo usa una ruta y un legado de muestra. | Conservar contenido y diferenciación semántica; reutilizar el mismo sistema. |
| Firma, estados, daño flotante, pausa, KO y FX | Presentación real compartida, con suites propias. Una captura estática no valida sus relojes. | KEEP comportamiento; sólo adaptar chrome que no invada figuras/HUD. |
| Acceso web con passkey y aprobación de dispositivo | Inspección de `backend/web/index.html`; sin abrir navegador ni hacer solicitudes. Sin puntuación visual nativa. | ADAPT tokens web en fase separada, conservando origen, nonce, verificación y aprobación explícita. |
| Diálogo de passkey del sistema/navegador | Fuera de la UI controlada por el juego. | KEEP; no imitar ni restilizar interfaces de seguridad del sistema. |

## Componentes y arte compartidos

| Pieza | Situación observada / acción |
| --- | --- |
| WorldBackdrop + manifiesto | Historia ya carga un lugar a sangre, velo legible y hasta tres objetos sin input. Extender contextos, no duplicar fondos/velos en cada pantalla. |
| WorldVisuals | Atlas de correas, paneles, insignias y estados. Mantener recortes y caché de texturas; una superficie plana auxiliar no debe convertirse en otra fábrica global. |
| GameVisualSystem y componentes nuevos | La fundación posterior añade theme, encabezado, preview, modal, insignia y otros componentes. Usarlos como adaptadores a la autoridad existente, sin sustituir Historia por una reinterpretación. |
| FighterView / GameFighterPreview | Reutilizar identidad y cosméticos reales. El retrato es presentación; no escribir estadísticas ni perfiles al navegar. |
| BattleLayout, ArenaView, CombatFX | Mantener escala/encuadre y relojes independientes de la migración de controles. Cambios concurrentes de geometría se revisan por sus propietarios. |
| Formularios y listas | Campo de nombre, selector, fila de atributo, técnica, talento, rival, historial y aviso necesitan roles comunes; preservar diferencias entre Liga, Historia y Online. |

Los siete PNG de la autoridad congelada son `journey`, `storm`, `workshop`, `camp`, `archive`, `surfaces` y `props`, registrados en el manifiesto anterior. Arena y replay reutilizan además los escenarios de combate y los atlas reales de los luchadores. **No se generó ni editó arte para esta auditoría**. Los muros son capturas de una composición de Godot, no modificaciones de los PNG de producción.

No hace falta un gran marco alrededor de todo. Historia usa espacios abiertos y separación para estadísticas y técnicas; reserva correas/materiales para navegación, acciones y anuncios. Las nuevas vistas deben repetir esa decisión, además de sus colores.

## Cobertura de las rutas solicitadas

Los 37 IDs son **estados de captura**, no 37 productos ni páginas nuevas. Las 16 áreas nombradas se corresponden con las siguientes rutas; compartir una vista no implica duplicar una función.

| Área solicitada | Ruta existente / evidencia nativa |
| --- | --- |
| Arena | Main: preparación y combate; `arena-idle`, `arena-active`. |
| Online Arena | Online, pestaña Arena: `online-arena`, `online-empty`. |
| Main Menu | HomePanel: `menu`. |
| Character Creation | Personalizador en modo creación: `creation`; creación remota: `online-create`. |
| Fighter Profile | Ficha local `profile` y remota `online-profile`. |
| Upgrades | Entrenar Liga `training`, Taller/Golpes/Talentos de Historia y Mi ficha Online. Cada modo conserva sus propias reglas. |
| Companions | Lista Liga `roster` y Refugio de Historia `story-companions`. |
| Legacy | `story-legacy`, `story-legacy-complete`; los recuerdos conservan sus datos históricos. |
| Settings | Documento independiente `settings`; antes sus controles formaban parte de Menú. |
| Battle Results | `result-victory`, `result-defeat`, `summary`; Online presenta su resumen de respuesta dentro del panel. |
| Matchmaking | Lista de rivales/desafío dentro de Arena Online; no hay una cola separada que capturar. |
| Leaderboards | **No existe una pantalla ni un endpoint de clasificación.** `sections.leaderboards` sólo reserva un alias visual para un posible uso posterior. No cuenta como área implementada o validada. |
| Inventory | Lista de cosméticos poseídos/bloqueados de `customization`; no hay una página de inventario adicional. |
| Cosmetics | Selección/equipamiento en `customization`, también reutilizado por Online. |
| Story | Ruta, taller, técnicas, talentos, refugio y legado de StoryPanel; `online-story` para la ruta remota. |
| Boss | Tipo de encuentro dentro de Historia: previsualización, insignia, rival y combate; no es una página independiente. |

## Revisión de fuentes tras las migraciones

Main, Home, Personalización, Online, Compañeros, Historia y Replay usan `GameVisualSystem.theme()`. Los controles pasan por sus roles compartidos; encabezados, previsualizaciones, insignias, resultados y documentos usan los componentes comunes. La revisión no encontró otra fábrica de Button/Panel por defecto fuera de la familia Historia. Se corrigieron también los alias de color de Online, el helper de estilo plano sin usos en Main y la ruta de ayuda **Menú → Ajustes → Movimiento reducido**.

Los paneles abiertos `StyleBoxEmpty`, el velo para lectura, las muestras de paleta, las barras semánticas de vida/XP y los contornos de foco son decisiones deliberadas. No se clasifican como pantallas pendientes por ser simples. Persisten algunos tamaños tipográficos numéricos adaptados al espacio, pero usan las familias comunes; no son un defecto visual demostrado por sí solos. La revisión estática se complementa con las capturas: no sustituye la prueba de recorte, scroll, foco o estados de interacción.

El acceso nativo Online se captura con una API en memoria. Esta pasada **no despliega ni prueba seguridad web**, passkeys, D1, red, sesiones, cuentas ni clasificaciones. La página web de autorización y el diálogo seguro del sistema son superficies externas a la matriz nativa. Su existencia no permite atribuirles validación funcional a partir de una captura offline.

La herramienta [capture_final.py](../../../work/visual-system/capture_final.py) prepara la captura global después de congelar fuentes y arte. Inventaría SHA-256 de scripts/datos/escenas, configuración, assets originales y fixtures antes y después; cualquier cambio durante la ejecución invalida la evidencia. Excluye backend, informes y archivos de importación. Verifica 37 IDs por dos resoluciones, archivos PNG reales, aislamiento y resultados asentados. Sin `--run` sólo crea un inventario y no abre Godot. Los hashes prueban el límite de esta ejecución; no atribuyen a la migración visual cambios de arte concurrentes ocurridos antes de congelarla.

## Pruebas que acompañan cada familia

| Familia | Tests existentes que deben conservarse al migrar |
| --- | --- |
| Fundación/materiales | [test_game_visual_system.gd](../tests/test_game_visual_system.gd), [test_game_components.gd](../tests/test_game_components.gd), [test_world_visuals.gd](../tests/test_world_visuals.gd), [test_world_surfaces.gd](../tests/test_world_surfaces.gd). |
| Historia | [test_story_panel.gd](../tests/test_story_panel.gd), [test_story_world_visuals.gd](../tests/test_story_world_visuals.gd), [test_story_campaign_ui.gd](../tests/test_story_campaign_ui.gd), [test_story_chapter_integration.gd](../tests/test_story_chapter_integration.gd), [test_campaign100_integration.gd](../tests/test_campaign100_integration.gd), [test_story_integration.gd](../tests/test_story_integration.gd). |
| Main/Arena/resultados | [test_battle_layout.gd](../tests/test_battle_layout.gd), [test_identity_integration.gd](../tests/test_identity_integration.gd), [test_identity_edges.gd](../tests/test_identity_edges.gd), [test_core.gd](../tests/test_core.gd). |
| Compañeros/creación/identidad | [test_roster.gd](../tests/test_roster.gd), [test_customization_visuals.gd](../tests/test_customization_visuals.gd), [test_cat_roster_ui.gd](../tests/test_cat_roster_ui.gd), [test_mexican_roster_ui.gd](../tests/test_mexican_roster_ui.gd), [test_fighter_identity.gd](../tests/test_fighter_identity.gd). |
| Online | [test_online_ui.gd](../tests/test_online_ui.gd), [test_online_integration.gd](../tests/test_online_integration.gd). Los tests API/Worker con HTTP son otra fase; no se ejecutan para capturar esta auditoría offline. |
| Replay/animación/FX | [test_animation_sequences_visual.gd](../tests/test_animation_sequences_visual.gd), [test_status_ko_presentation.gd](../tests/test_status_ko_presentation.gd), [test_move_clock.gd](../tests/test_move_clock.gd), [test_move_presentation.gd](../tests/test_move_presentation.gd), [test_organic_fx.gd](../tests/test_organic_fx.gd). |
| Auditoría secuencial nueva | [test_visual_screen_audit.gd](../tests/test_visual_screen_audit.gd), [test_visual_menu_navigation.gd](../tests/test_visual_menu_navigation.gd) y [test_visual_documents.gd](../tests/test_visual_documents.gd). |

Esta lista identifica cobertura disponible, no afirma que todas esas suites se hayan ejecutado de nuevo para redactar el inventario. Cada migración debe ejecutar las pruebas pertinentes y registrar sus resultados por separado.

## Seguimiento de migraciones

| Paso | Antes | Después / evidencia | Estado |
| --- | --- | --- | --- |
| Menú principal | 40/100; documento plano que mezclaba destinos y ajustes. | [Escritorio](../../../work/visual-system/after/menu/menu-1360x880.png), [móvil](../../../work/visual-system/after/menu/menu-390x844.png): refugio a sangre, compañero dominante, título narrativo, Historia principal y materiales comunes. Comparación con la referencia: 4/4/4/4/4 → 100/100. | Apariencia y navegación aprobadas. El escape de foco al HUD fue corregido: ciclo entre Cerrar y destinos habilitados. [Prueba nativa](../../../work/visual-system/menu-navigation-native.log): **294 comprobaciones, 0 fallos** en 1360×880, 390×844 y 844×390. |
| Arena | 65/100; buena escena con chrome plano. | Capturas posteriores en `work/visual-system/after/arena`; revisión de controles separada de cambios concurrentes en escala de actores. | Migración aprobada y fijada en la matriz global final; esta auditoría no cambia BattleLayout. |
| Online | 40–50/100 en paneles; 65/100 en replay. | [Muro escritorio](../../../work/visual-system/online-final/wall-1360x880.png), [muro móvil](../../../work/visual-system/online-final/wall-390x844.png). Veinte capturas revisadas; patio, taller y archivo, títulos narrativos y controles comunes. Paneles de esta fase: 4/4/4/3/4 → 95/100. El replay de estas capturas, anterior a su migración común final, puntuó 4/3/2/4/4 → 85/100; ese valor no describe el Replay actualizado, puntuado en la matriz final de abajo. | Aprobado. Sin clipping ni solapes; las filas parciales corresponden al scroll. El fallback vacío de Historia se sustituyó por un hito compacto `09`. [Validación del propietario](../../../work/visual-system/online-migration-results.json): 815/0 nativo en siete tamaños, 147/0 casos adicionales y matriz 33/0. No se suman como pruebas independientes de toda la aplicación. |
| Ficha Liga | 45/100; documento sin figura ni lugar. | [Escritorio](../../../work/visual-system/after/profile/profile-1360x880.png), [móvil](../../../work/visual-system/after/profile/profile-390x844.png): refugio, protagonista y lectura separada. 4/4/4/3/4 → 95/100. | Aprobado; se conservan las nueve estadísticas, habilidad, firma y lectura por scroll. |
| Entrenamiento Liga | 45/100; cuatro tarjetas en un panel genérico. | [Escritorio](../../../work/visual-system/after/training/training-1360x880.png), [móvil](../../../work/visual-system/after/training/training-390x844.png): taller, figura y cuatro mejoras propias de Liga. 4/4/3/4/4 → 95/100. | Aprobado tras corregir el mínimo de anchura retenido. [Prueba nativa de ficha/entrenamiento](../../../work/visual-system/documents-native.log): **637 comprobaciones, 0 fallos** en siete tamaños; mismo resultado headless. Incluye cuatro hitboxes/etiquetas/valores, scroll y una mejora persistida por fixture sin alterar Historia ni XP/nivel. |
| Creación / Personalizar | 55/100; formulario de otra familia. | [Creación móvil](../../../work/visual-system/after/creation/creation-390x844.png), [editor escritorio](../../../work/visual-system/after/creation/customization-1360x880.png). Taller, listas abiertas, selección y acciones de una familia común; encuadre móvil corregido. 4/4/4/3/4 → 95/100. | Fase aprobada. La matriz `after/all` ya contiene el subtítulo móvil completo «Tu nombre. Tu estilo. Tu historia.» y el encuadre vigente. |
| Resultados | 60/100; resultado con poca presencia narrativa. | [Victoria escritorio](../../../work/visual-system/after/results/result-victory-1360x880.png), [derrota móvil](../../../work/visual-system/after/results/result-defeat-390x844.png): panel material, título y recompensa claros, con figuras y CTA conservados. 4/4/4/3/4 → 95/100. | Aprobación final tras corregir el solape del panel con la pose asentada. La matriz `after/all` muestra el panel bajo las figuras en escritorio; las capturas de fase anteriores se conservan como tales. |

Secuencia aplicada por etapas: menú → Arena/HUD/resultados → Online → creación/personalización → ficha/entrenamiento → Compañeros → documentos/legados/ajustes. Historia permanece como referencia y sólo se corrigen sus excepciones de componente. Cada paso debe comparar dos tamaños con la misma fixture, revisar foco/scroll y comprobar que la ruta vuelve al lugar esperado antes de avanzar.

La prueba de menú recorre los destinos reales con un espía offline para la acción Online, comprueba Tab y Shift-Tab, desplazamiento al foco, controles de al menos 48 px, exclusión de acciones durante combate, acceso a Ficha en pausa, Escape y conservación byte a byte de Liga e Historia. No acciona pantalla completa ni guarda preferencias. La puntuación 100 expresa equivalencia con esta referencia visual en el alcance revisado; no afirma que no exista ninguna mejora futura.

## Matriz final puntuada

Las puntuaciones se basan en los dos tamaños revisados. Son comparativas y deliberadamente no automáticas: van de 90 a 100; los documentos densos, el espacio de estados vacíos y la navegación por scroll explican diferencias concretas. **37/37 estados revisados, sin bloqueo visual pendiente.** Los cortes de filas al borde de una zona desplazable y la abreviación de roles de tarjetas no significan que la ficha completa sea inaccesible.

| ID | Antes | M/S/T/C/N → Después | Observación final |
| --- | --- | --- | --- |
| `story-route` | 100 | 4/4/4/4/4 → **100** | Referencia conservada: rival completo, debilidad y siguiente acción; ruta y ficha móvil por scroll. |
| `story-upgrades` | 100 | 4/4/4/4/4 → **100** | Taller abierto, puntos/impacto/acción claros; los atributos continúan por scroll. |
| `story-respec` | 75 | 3/4/4/4/4 → **95** | Confirmación breve y acciones seguras dentro del modal neutro; el lugar queda atenuado. |
| `story-moves` | 100 | 4/4/4/3/4 → **95** | Familia común; técnicas y seis talentos mantienen una densidad considerable. |
| `story-perks` | 95 | 4/4/4/3/4 → **95** | Sección desplazada de Golpes; requisitos, riesgos y mejoras legibles, no todo cabe a la vez. |
| `story-companions` | 100 | 4/4/4/4/4 → **100** | Refugio con personaje protagonista, biografía y miniaturas contenidas. |
| `story-legacy` | 95 | 4/4/4/3/4 → **95** | Archivo y capítulo claros; el estado vacío conserva un área amplia. |
| `story-legacy-complete` | 100 | 4/4/4/3/4 → **95** | Siguiente capítulo y recuerdo diferenciados; el legado detallado requiere scroll móvil. |
| `arena-idle` | 65 | 4/4/4/3/4 → **95** | HUD y acciones ya comparten familia; el móvil conserva gran espacio de arena entre información y figuras. |
| `menu` | 40 | 4/4/4/4/4 → **100** | Refugio, compañero y destino principal forman una jerarquía común con Historia. |
| `settings` | Dentro de Menú | 4/4/4/3/4 → **95** | Cuatro controles claros con selección/foco; el modal deja aire inferior amplio. |
| `training` | 45 | 4/4/3/4/4 → **95** | Taller y figura compartidos; las cuatro estadísticas conservan jerarquía tipográfica compacta. |
| `profile` | 45 | 4/4/4/3/4 → **95** | Personaje y contexto claros; ficha extensa y estadísticas posteriores mediante scroll. |
| `help` | 50 | 4/4/3/3/4 → **90** | Material y titular compartidos; lectura larga con cuerpo de peso uniforme. |
| `history-empty` | 40 | 4/4/4/3/3 → **90** | Archivo claro; espacio libre amplio y pie de scroll genérico aun sin registros. |
| `log-empty` | 40 | 4/4/4/3/3 → **90** | Ausencia de acciones explícita; modal amplio y pie genérico aun con poco texto. |
| `roster` | 55 | 4/4/4/3/4 → **95** | Colección y ficha comparten Refugio; algunos roles se abrevian en tarjetas móviles. |
| `customization` | 55 | 4/4/4/3/4 → **95** | Taller, retrato y equipamiento unidos; muchas opciones visibles requieren scroll. |
| `arena-active` | 65 | 4/4/4/3/4 → **95** | HUD, escena y acciones pertenecen al mismo mundo; reserva amplia para movimiento móvil. |
| `surrender` | 50 | 3/4/4/4/4 → **95** | Confirmación clara y dos acciones diferenciadas; la escena queda atenuada para leer. |
| `result-victory` | 60 | 4/4/4/3/4 → **95** | Panel bajo las figuras: cabeza y puño libres; acción siguiente repetida en panel y pie de escritorio. |
| `result-defeat` | 60 | 4/4/4/3/4 → **95** | Derrota, recompensa y CTA claros; celebración rival libre y mensaje siguiente repetido en el pie. |
| `summary` | 50 | 4/4/3/3/4 → **90** | Datos exactos en documento común; jerarquía del cuerpo y aire conservan aspecto de informe. |
| `history` | 45 | 4/4/4/3/4 → **95** | Archivo con identidad, desenlace y acción comunes; dos recuerdos dejan bastante aire. |
| `log` | 50 | 4/4/3/3/4 → **90** | Registro legible y continuo; tipografía uniforme deliberada para eventos. |
| `replay` | 65 | 4/4/4/3/4 → **95** | Título, selector y transporte compartidos; gran reserva central para la secuencia. |
| `online-arena` | 45 | 4/4/4/3/4 → **95** | Rival, contexto y desafío siguen Ruta; cabecera de cuenta añade densidad móvil. |
| `online-story` | 45 | 4/4/4/3/4 → **95** | Hito 09 legible y acción clara; preview limitada a los datos de la fixture remota. |
| `online-profile` | 45 | 4/4/4/3/4 → **95** | Retrato y taller compartidos; estadísticas continúan bajo el primer viewport móvil. |
| `online-perks` | 45 | 4/4/4/3/4 → **95** | Técnicas/talentos/estilo usan filas abiertas; contenido largo por scroll. |
| `online-activity` | 45 | 4/4/3/3/4 → **90** | Archivo coherente y acciones claras; resumen denso. La pluralización se corrigió antes de la captura final. |
| `online-empty` | 45 | 4/4/4/3/4 → **95** | Ausencia sincera de rivales y una acción; el patio mantiene espacio libre amplio. |
| `online-create` | 50 | 4/4/4/3/4 → **95** | Personaje y formulario en el taller; la acción de retorno continúa bajo scroll móvil. |
| `online-replay` | 65 | 4/4/4/3/4 → **95** | Mismos materiales, texto y transporte del visor local; escena reservada para el movimiento. |
| `online-login` | 40 | 4/4/4/3/4 → **95** | Acceso legible y CTA único dentro del patio; gran espacio ambiental. |
| `online-device` | 40 | 4/4/4/3/4 → **95** | Código, estado y cancelación visibles; bloque de instrucciones más denso que Ruta. |
| `creation` | 55 | 4/4/4/3/4 → **95** | Nombre/base/figura/estilo diferenciados; configuración densa en móvil. |

## Validación y límite de la evidencia final

- [74 capturas + dos muros](../../../work/visual-system/after/all/screens.json), [log nativo](../../../work/visual-system/audit-final-native.log): **143 comprobaciones, 0 fallos**. Todos los resultados tienen alfa 1 y presentación asentada.
- [Acta de revisión visual](../../../work/visual-system/final-visual-review.json) y revisiones independientes de [Main](../../../work/visual-system/final-main-review.md), [Historia](../../../work/visual-system/final-story-review.md), [Online](../../../work/visual-system/final-online-review.md) y [documentos/Replay](../../../work/visual-system/final-document-review.md).
- [Hashes de la captura](../../../work/visual-system/final-native-provenance.json): 50 archivos de fuente, 229 de arte y cinco fixtures estables antes/después. [Ventana del caché importado](../../../work/visual-system/import-cache-window.json): ninguno de 388 archivos se escribió durante la captura. Son pruebas de ese intervalo, no una prohibición de cambios posteriores en otras tareas.
- [Regresión consolidada](../../../work/visual-system/final-validation/results.json): **27 suites, 17 447 comprobaciones, 0 fallos**, con las reevaluaciones pertinentes ya incorporadas. No se suman de nuevo las ejecuciones parciales de esta página. La nueva regresión del resultado comprueba siluetas pintadas asentadas en siete tamaños: 1950/0.
- [Comprobación del tablero](../../../work/visual-system/review-test.log): **63 comprobaciones, 0 fallos**. Incluye filtros, referencia fija, zoom 1:1, foco al cerrar, ausencia de desbordamiento móvil y hashes de las 146 copias. Carga como archivo local: cero solicitudes HTTP y cero errores de navegador. Ocho pruebas de las herramientas comprueban selección de fuentes, ausencia explícita y límites del empaquetado.
- [Preservación](../../../work/visual-system/preservation-final.json): fondos/materiales y módulos de reglas conservados. Las secuencias de sprites ajustadas por la tarea paralela pertenecen a otro trabajo; no se presentan como arte generado o editado por esta migración de UI.

La primera pasada pasó las comprobaciones funcionales, pero la revisión visual detectó que el resultado de escritorio ocultaba una cabeza/puño levantado. Se conserva en [first-pass-result-overlap](../../../work/visual-system/first-pass-result-overlap/review-status.json). El panel se desplazó entre los pies y las acciones, se revisó a tamaño original y se repitió la matriz global completa. Actividad Online también corrigió la concordancia de «1 combate · 1 victoria». La evidencia final es la segunda matriz aceptada; no se atribuye aprobación visual a la pasada rechazada.

Los PNG del tablero son copias byte a byte. El HTML permite referencia fija de Historia, filtro por sección, escritorio/móvil, Antes/Después y zoom 1:1. No genera imágenes, no interpola una fase ausente y no hace solicitudes HTTP al abrirse como archivo local. El acceso web de seguridad y Leaderboards quedan explícitamente fuera del conjunto implementado/revisado, según la tabla de cobertura.

## Repetir una captura aislada

Desde la raíz del workspace, con Godot nativo:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path outputs/Brasa \
  --script res://tests/test_visual_screen_audit.gd -- \
  --only=main-menu \
  --capture-dir=/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/work/visual-system/after/menu
```

`main-menu` es alias de `menu`. Se admiten listas como `--only=arena-idle,arena-active,result-victory,result-defeat` o `--only=settings,training,profile`. Sin filtro recorre todas las pantallas. El filtro evita inicializar fases ajenas; el menú no requiere combatir ni crear Online. Cada ejecución usa nuevos archivos desechables. Guardar las siguientes migraciones en carpetas `after` propias; **no sobrescribir la base congelada**. Las capturas posteriores de producto y las fuentes actuales no convierten las capturas anteriores en resultados del código nuevo.

## Cierre: acceso, familias y desgaste

Acceso revisado con materiales compartidos de Historia: [escritorio](../../../work/auth-experience/native/1360x880-login.png), [móvil](../../../work/auth-experience/native/390x844-login.png), [informe](AUTH-EXPERIENCE.md). Validación de navegador WebAuthn: 13 escenarios; sesión y Keychain: 16/0.

[El nuevo muro de familias y daño](../../../work/damage-families/review.html) contiene tres comparaciones de familia y 23 referencias de daño nativas. Véase [alcance, capturas y pruebas](DAMAGE-AND-FAMILIES.md). Son fixtures visuales y no representan cuentas o inventarios de usuarios.

## Corrección posterior: bordes y cruce de peleadores

El usuario detectó un borde blanco en Ascua dañado y solapamiento al atacar o caer. Ambos defectos invalidan esa parte de la revisión anterior. [Corrección y capturas verificadas](ASCENDING-EDGE-CLEARANCE-FIX.md): cuatro bancos limpiados y límites de presentación compartidos en Main y Replay, escritorio/móvil y KO doble.

## Menú: hábitats y vida cotidiana

La captura anterior de `menu` queda sustituida por esta [revisión del refugio personal](character-refuges/index.html), con [detalle y validación](CHARACTER-REFUGES.md). Veintiuna ilustraciones activas, sin figura animada ni props superpuestos; jerarquía en tres grupos y composición adaptada al personaje. La primera propuesta de fondos se descartó por repetir valle, vegetación y pose. La segunda conserva identidad individual y diferencia hábitats, iluminación, acciones y encuadres. El nuevo muro conserva capturas nativas de escritorio/móvil y acceso al arte completo; el muro global anterior sigue siendo evidencia histórica de las otras pantallas.

## Contacto: proximidad y superposición del atacante

El límite central de la corrección de bordes retraía también el brazo extendido y producía golpes al aire. Se adapta ese límite exclusivamente para la pareja en combate, conservando cámara, raíz, escala de especie y materiales de Historia. El atacante avanza hacia el torso neutral rival, ocupa el primer plano y recupera su posición al terminar. Se conserva el desplazamiento si un KO interrumpe la acción.

| Superficie | Clasificación | Cambio comprobado |
| --- | --- | --- |
| Arena e Historia en combate | ADAPT | Contacto más próximo; atacante delante; guardia y encuadre conservados. |
| Repeticiones de Arena/Online | ADAPT | Mismo renderer, acercamiento y profundidad con eventos grabados. |
| Retratos y selección sin pareja | KEEP | No incorporan el avance de contacto. |

[Comparación antes/después](combat-contact/index.html) · [alcance y validación](COMBAT-CONTACT.md). Las capturas de este ajuste son fixtures de presentación, independientes del muro histórico de UI.


### Simplificación de la cabecera del menú

El menú ahora empieza directamente con «Empezar historia» o «Continuar historia», según el progreso del personaje seleccionado. Se eliminaron cabecera, nivel y rótulos redundantes, y el foco primario usa el tono del material sin contorno blanco. [Capturas actuales de escritorio y móvil](character-refuges/index.html); fuentes nativas en `work/menu-cleanup/`. Esta revisión sustituye solo las capturas previas del menú.


## Entrenamiento: tarjetas y ayuda contextual

La pantalla de entrenamiento de Liga tiene composición acotada, puntos destacados, vista previa numérica, tarjetas con ayuda desplegable y estados claros sin puntos. [Capturas actuales](training-ui/index.html) y [validación](TRAINING-UI.md): 756 comprobaciones en siete tamaños, más 327 de navegación; sin fallos. Esta revisión sustituye la evidencia anterior de entrenamiento.


## Personalizar: acciones compactas y escala compartida

Cancelar y Guardar se alinean a la derecha; Aplicar estilo y Al azar ocupan una fila acotada. La vista del compañero aprovecha el espacio sin normalizar tamaños entre especies. [Capturas actuales](customization-ui/index.html) y [detalle de verificación](CUSTOMIZATION-UI.md). Esta revisión sustituye sólo la evidencia anterior de Personalizar.


## Color y skins: muestras, colección y pruebas

Color incorpora doce paletas con muestras grandes y las seis skins de familia. Pruebas bloqueadas separadas del borrador, retorno explícito y requisitos reales. [Capturas finales](color-skins/index.html) y [verificación / alcance online](COLOR-SKINS.md). Esta revisión actualiza Personalizar y conserva sus controles compactos; el nuevo catálogo de colores aún no está publicado en Cloudflare.


## Daño ilustrado: rostro, ropa y postura

La implementación anterior de desgaste de superficie queda sustituida por una familia de sprites heridos completa en los 23 cuerpos: 920 poses, 69 pares PNG/JSON; 22 cuerpos recién ilustrados y Ascua reutilizado desde critical-v1. Grados 2 y 3 comparten el arte herido, mientras grado 1 conserva limpio y fatiga. El material de Historia, los entornos y la interfaz permanecen como referencia.

| Superficie | Clasificación | Evidencia y límite |
| --- | --- | --- |
| Arena e Historia en combate | ADAPT | Sustitución del cuadro completo por arte herido del mismo cuerpo y pose; Pase nativo final 3832/0; 39 PNG. |
| Repeticiones locales y Online | ADAPT | Mismo renderer y eventos guardados; no generan recompensas. Paridad de mínimos de vida y estado comprobada en la suite de daño ilustrado. |
| Retratos, catálogo y selección | KEEP | No se fuerza daño para mostrar una apariencia; se conserva el arte limpio y la escala física. |
| Arte, fuentes y documentos anteriores | KEEP histórico | El shader anterior y sus capturas no acreditan la nueva biblioteca. |

[Tablero de los 23 cuerpos](illustrated-damage/index.html) · [Alcance y procedencia](ILLUSTRATED-DAMAGE.md). El tablero muestra recortes técnicos de PNG de producción, no capturas del juego. Las comprobaciones de alfa/escala no certifican sockets anatómicos: los apoyos proyectados siguen declarados como aproximados y el contacto puede usar el borde pintado. El cierre registra 3832/0 en Godot nativo y seis suites headless con 56 484/0 (incluido el gate estricto 14 977/0). Se revisaron las 23 láminas de cuatro clips en dos orientaciones y los 16 contextos; los originales nuevos completos se inspeccionan por separado. El primer pase 3878/46 queda preservado como fallo de una aserción de la fixture aplicada a KO sin pareja; el arte y runtime no cambiaron para resolverlo. Los 39 PNG finales son idénticos a los revisados. No se afirma QA de navegador del tablero HTML.


## Efectos: partículas legibles y prueba de bloqueados

Auras y Estelas incorporan muestras visuales, siete efectos nuevos y vista previa independiente del inventario. Capa visible sobre el sprite, desvanecimiento de estelas, demostración automática y movimiento reducido. [Capturas / video actuales](effects-ui/index.html) y [validación / alcance online](EFFECTS-UI.md). Esta revisión actualiza Efectos; conserva Color y Skins de la revisión anterior. El catálogo nuevo permanece sin publicar en Cloudflare.


## Estilo: contexto y demostraciones

Entrada / Victoria, ocho ejemplos, tarjetas descriptivas, reproducción automática opcional y prueba sin equipar. [Revisión actual](style-ui/index.html), [alcance y validación](STYLE-UI.md). Conserva los cambios previos de colores, skins y efectos. Catálogo v5 local; nuevos estilos pendientes de publicación online.


## Combate: HUD pintado y resultado centrado

Arena e Historia eliminan la marca, el acceso Historia y la explicación redundante de ataques. Menú centrado; HUD reutilizable y resultado/continuación central con velo. Online comparte HUD y resultado desde la perspectiva del usuario. Repeticiones históricas mantienen sus coordenadas. [Capturas](battle-ui/index.html) · [validación](BATTLE-UI.md). El resultado se superpone intencionalmente a la escena final; reemplaza la antigua exigencia de mantener la silueta fuera del anuncio. Sin cambios en reglas o servidores.


## Compañeros: escala, atributos y progreso

Tarjetas con cámara común y XP individual; vista principal ampliada; atributos actuales separados del crecimiento opcional y de Habilidades y perfil. Menos texto redundante y Personalizar compacto. Selección, nombres y perfiles sin cambios. [Capturas](roster-ui/index.html) · [Validación](ROSTER-UI.md). Los perfiles de la galería son fixtures en memoria.


## Ficha: lectura compacta

Cuadrícula de atributos, habilidades en tarjetas y explicaciones a demanda. Mismo encuadre del compañero; valores de Liga/Historia y pausa conservados. [Capturas](profile-ui/index.html) · [Verificación](PROFILE-UI.md). Sustituye el documento extenso anterior.


## Logros: objetivos, recuerdos y colección

Sustituye Legado: 17 reconocimientos por personaje derivados del progreso guardado, objetivos con avance, recuerdos de capítulos opcionales y cosméticos del inventario compartido. Se eliminan el emblema vacío, objetos decorativos y selectores de capítulos redundantes. [Capturas](achievements-ui/index.html) · [Alcance y verificación](ACHIEVEMENTS-UI.md). Sin concesión de premios ni cambios de guardados o backend.


## Ruta: encuentro, mapa y acciones

Ruta simplifica la introducción, conserva los detalles en un desplegable y separa repetir de continuar con botones compactos. Sin cambios en progresión. [Capturas](route-ui/index.html) · [Verificación](ROUTE-UI.md).


## Mejoras: atributos y decisiones

Ocho atributos en tarjetas, valor actual y mejora real, estados de máximo y sin puntos, ayudas opcionales y acciones compactas. [Capturas](upgrades-ui/index.html) · [Verificación](UPGRADES-UI.md).


## Movimientos: técnicas y talentos

Técnicas y talentos en secciones separadas, beneficios resumidos, detalles exactos opcionales y acciones compactas. [Capturas](moves-ui/index.html) · [Verificación](MOVES-UI.md).


## Compañeros de Historia: selección y progreso

Vista ampliada, ficha compacta, detalles opcionales, progreso por personaje y acciones de empezar/continuar. [Capturas](story-companions-ui/index.html) · [Verificación](STORY-COMPANIONS-UI.md).


## Ajustes: sliders visibles

Barras de volumen con grosor real, contraste y agarradores rellenos. [Capturas](sliders-ui/index.html) · [Validación](SLIDERS-UI.md).


## Precisión de sprites · 21 de septiembre de 2026

Los 23 cuerpos usan daño localizado sobre la geometría exacta de su pose sana. El daño no modifica la tonalidad, iluminación ni opacidad de las zonas intactas. Se conservan la escala propia de cada cuerpo y el origen común. Ver [informe y validación](SPRITE-PRECISION.md) y [comparativa](sprite-precision/index.html).


## Foco sin contorno y rendimiento · 21 de septiembre de 2026

Auditoría nativa: 37 superficies en 1360×880 y 390×844 (74 capturas, 143 comprobaciones sin fallos). Perfiles desechables; no son datos de servidor. Se revisaron ambas paredes visuales y capturas individuales de Ajustes y Redistribuir mejoras. El foco permanece dentro de los controles y los carriles de volumen siguen visibles.

- [Pared de escritorio](../../../work/performance-ui/screens/wall-1360x880.png)
- [Pared móvil](../../../work/performance-ui/screens/wall-390x844.png)
- [Cambios, pruebas y mediciones](PERFORMANCE-UI.md)


## Presencia de personajes · 22 de septiembre de 2026

La revisión posterior amplía moderadamente los retratos de Entrenamiento, Ficha, Personalizar móvil, selección e Historia/Online. Combate de escritorio admite hasta escala 2.05 con suelo 24 px más abajo. Móvil conserva el límite horizontal de dos animaciones completas. Las especies comparten cámara y mantienen su tamaño relativo; nunca se ajusta la escala a los píxeles de cada pose. No cambian arte, tonos ni lógica de juego.

[Medidas, decisiones y validación](CHARACTER-PRESENCE.md) · [Muro móvil más reciente](../../../work/character-presence/after/wall-390x844.png) · [Muro escritorio más reciente](../../../work/character-presence/after/wall-1360x880.png).
