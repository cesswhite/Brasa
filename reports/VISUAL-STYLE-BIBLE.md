# Brasa · Biblia visual de la interfaz

**Autoridad: Historia actual.** Este documento describe el lenguaje de sus cinco pestañas y el sistema compartido que lo extiende al resto de Brasa. No cambia reglas de juego. El diagnóstico inicial se basó en código, manifiesto y capturas; la migración se verificó después con fixtures locales y capturas nativas, sin modificar producción.

Las secciones 1–11 conservan el análisis de la referencia original; la sección 12 define las APIs implementadas. Las cifras de progreso visibles en las capturas son datos de sus fixtures, no especificaciones de balance.

## 1. ADN que debe conservarse

Brasa presenta **lugares habitados por luchadores**, con información y acciones legibles dentro de esos lugares. Historia funciona porque el entorno ocupa toda la pantalla, la figura tiene presencia y los controles comparten sus materiales.

- Pintura digital 2D con pincel visible, superficies gastadas y siluetas nítidas. La textura procede del arte; no requiere una capa adicional de ruido sobre la interfaz.
- Piedra, madera, tejido y cuero oscuro con herrajes de cobre/bronce. Costuras, pequeñas gemas y remaches expresan fabricación artesanal.
- Faroles cálidos, sombras azul petróleo y fondos más oscuros que los personajes. La luz ambiental une figura, suelo y arquitectura.
- Títulos serif de tono narrativo; cuerpo sans legible para decisiones, estadísticas y acciones.
- Un foco claro por vista: rival en Ruta, decisiones en Taller, técnicas en Movimientos, compañero en Refugio, logro conservado en Legado.
- Materiales visibles donde ayudan: navegación, acciones y anuncios destacados. Las listas de atributos, técnicas y compañeros dejan respirar el escenario.

La jerarquía de Ruta es la referencia principal: cabecera y navegación estables; rival e información en el primer bloque; recorrido compacto después; acción principal fija al pie. El rival no necesita un gran contenedor rectangular detrás.

## 2. Fuentes y precedencia

| Fuente | Qué fija |
| --- | --- |
| `scripts/ui/story_panel.gd` | Tipografía, color semántico, composición, comportamiento responsive, contenido y estados legibles. |
| `scripts/ui/world_visuals.gd` | Roles de material, nine-slice, foco, estados, carga compartida y decoración condicionada. |
| `scripts/ui/world_backdrop.gd` | Fondo a sangre, conservación de aspecto, velo, orden de decoración y carga del contexto activo. |
| `data/ui_visual_manifest.json` | Fondos, tintes por lugar, regiones reales, márgenes, alias y condiciones de objetos. |
| `assets/ui/ART-DIRECTION.md` y `GENERATION-PROMPTS.json` | Dirección artística y procedencia de los siete PNG originales. |
| Capturas Historia | Evidencia de composición y legibilidad; no sustituyen al código cuando muestran una versión anterior de los datos. |
| `reports/organic-fx/COMBAT-FX.md` y render actual | Límite reciente de FX: motas y chispas orgánicas, sin anillos ornamentales de fuego. |

Si un nuevo componente entra en conflicto con una captura antigua, prevalece el código actual y la instrucción reciente del usuario. Si una excepción local difiere del sistema compartido, documentarla antes de convertirla en otro token global.

## 3. Color y luz

### Paleta de lectura

| Constante actual | Valor | Papel observado |
| --- | --- | --- |
| `CREAM` | `#F5E7CF` | Texto principal, nombre del rival, etiquetas de controles secundarios. |
| `GOLD` | `#EFB66F` | Capítulos, encuentros, XP, recomendaciones y títulos de sección. |
| `TEAL` | `#7DD7BD` | Fortalezas, crecimiento, disponibilidad y progreso superado. |
| `MUTED` | `#9AB3AC` | Metadatos, explicación secundaria, nivel y contexto. |
| `CORAL` | `#ED997F` | Debilidad, riesgo y aviso de guardado. |
| `DARK` | `#0C2228` | Base oscura de la familia; no cubre por sí sola todos los fondos. |
| `SURFACE` | `#153137` | Superficie plana de apoyo presente en el diálogo local. |
| Texto de acción primaria | `#152329` | Texto oscuro sobre correa ámbar. |
| Foco compartido | Ámbar `#EFB66F`, alfa `.22` | Relleno interior retraído 4 px, sin contorno exterior. |

Estos colores tienen significado. No usar coral para un dato neutro ni jade para una acción peligrosa. Fortalezas y riesgos siempre llevan palabras: el color no es el único indicador. No sustituir esta paleta por grises neutros, blanco puro o acentos nuevos en cada página.

### Variación del lugar, desde el manifiesto

Los acentos de contexto son datos disponibles del registro. Historia usa además sus constantes semánticas para el texto; no debe afirmarse que todo el texto cambia automáticamente al acento del lugar.

| Contexto | Fondo | Acento | Sombra base | Tinte del fondo |
| --- | --- | --- | --- | --- |
| `route_journey` | `journey` | `#EFB66F` | `#0B2026` | `#FFFFFF` |
| `route_storm` | `storm` | `#A4D5E6` | `#101E2C` | `#FFFFFF` |
| `route_late` | `storm` | `#DFC891` | `#101E26` | `#E8D7C0` |
| `route_boss_journey` | `journey` | `#EFB780` | `#281B17` | `#FFE4C3` |
| `route_boss_storm` | `storm` | `#AFCEDF` | `#151B2F` | `#E5DEF4` |
| `route_boss_late` | `storm` | `#EDB39B` | `#251422` | `#F4C8C1` |
| `workshop` | `workshop` | `#ECC18D` | `#221A19` | `#FFFFFF` |
| `moves` | `workshop` | `#CBB398` | `#181B23` | `#D5E2EF` |
| `camp` | `camp` | `#F0BC84` | `#211C1A` | `#FFFFFF` |
| `legacy` | `archive` | `#DECDB0` | `#171D28` | `#FFFFFF` |

`route_boss` permanece como contexto compatible; la selección normal usa la variante de jefe correspondiente al capítulo. Un jefe conserva el lugar de su ruta, añade insignia y aumenta presencia del personaje; no obliga a una escena visual ajena.

### Velos, profundidad y contraste

`WorldBackdrop` dibuja un fondo opaco con `STRETCH_KEEP_ASPECT_COVERED`: ocupa el área, conserva proporción y recorta lo necesario. No estira personajes o controles junto con la imagen.

El velo vertical tiene RGB `(0.015, 0.03, 0.04)` y paradas `(posición, alfa)` de `(0, .68)`, `(.42, .14)`, `(.76, .20)`, `(1, .88)`. Mantiene despejado el centro y protege cabecera y pie. Historia añade un velo horizontal RGB `(0.015, .025, .025)`: alfa `.66` a la izquierda, `.42` en `.46` y `.14` a la derecha de Ruta; en las otras pestañas el último alfa es `.58`.

Conservar la luz del suelo y del personaje. Resolver el contraste con la posición del texto y el velo necesario; reservar marcos opacos para una agrupación importante o un diálogo. Los números anteriores son la referencia actual, no una garantía de contraste para cualquier recorte futuro.

## 4. Tipografía

| Rol observado | Familia y tamaño lógico |
| --- | --- |
| Cuerpo por defecto | `Avenir Next`, fallback `DejaVu Sans`, luego `Arial`; 15 px. |
| Texto explicativo y metadatos | Misma sans, normalmente 14 px; datos compactos 12–13 px. |
| Rótulo superior / encuentro | Sans, 12 px, mayúsculas breves, ámbar. |
| Título del capítulo | `Georgia`, fallback `DejaVu Serif`; 29 px, 20 en teléfono o altura corta. |
| Nombre protagonista en Ruta | Serif 42 px; 32 en teléfono o altura corta. |
| Título del encuentro | Serif 20 px, ámbar. |
| Taller / Refugio | Titulares serif 30–32 px; secundarios y cifras destacadas 20–22 px. |
| Navegación | Sans 15 px; 13 en teléfono. |
| Nombre en lista de compañeros | Serif 20 px; rol sans 13, nivel 12, ruta 11. |
| Marcadores de ruta | Número 15, nombre 13, detalle 10 px. |

El helper actual aplica serif a cualquier etiqueta de 20 px o más. Para centralizar, convertir los usos en roles explícitos —por ejemplo título de página, nombre protagonista, título de bloque, cuerpo, metadato y rótulo— manteniendo primero su apariencia. Estos nombres son una propuesta de organización, no APIs existentes.

Las familias son `SystemFont`: hoy no hay una fuente empaquetada que garantice idénticas métricas en todos los sistemas. Conservar los fallbacks y verificar anchuras antes de distribuir en otra plataforma. No copiar cifras de peso tipográfico que el código no fija. Una futura fuente incorporada requiere resolver su licencia y comprobarla contra Historia.

Los 10–11 px de ruta son una excepción compacta observada; no convertirlos en el tamaño general de mensajes de error, requisitos o controles. El texto importante admite salto de línea. La elipsis se reserva para etiquetas compactas, con detalle completo accesible.

## 5. Materiales y controles

### Atlas existente

`assets/ui/shared/surfaces-v1.png` contiene ocho piezas: correa primaria ámbar, correa secundaria petróleo, panel habitual, panel de jefe, insignia normal, insignia de jefe, separador e insignia de élite. Las regiones son las cajas reales registradas, no ocho celdas ideales de una cuadrícula.

Los botones conservan cuero, costura y remates metálicos; los paneles conservan esquinas reforzadas. Las insignias mantienen su proporción al dibujarse. No incrustar nombres ni números en estos PNG.

| Rol/API actual | Nine-slice L/T/R/B | Padding L/T/R/B | Uso |
| --- | --- | --- | --- |
| `primary`, `secondary` | `24 / 8 / 24 / 8` | `14 / 10 / 14 / 10` | Acciones completas con remates. |
| `navigation`, `navigation_active` | `8 / 8 / 8 / 8` | `3 / 8 / 3 / 8` | Recorte central de las mismas correas; conserva costuras y deja espacio al texto. |
| `panel`, `boss_panel` | `26 / 22 / 26 / 22` | `18 / 16 / 18 / 16` | Agrupación destacada y marco especial. |

El atlas de superficies se adapta una vez a escala `.35` en memoria; los PNG originales se conservan. Los márgenes son los que usa el render actual sobre esa textura. Las regiones y la escala deben tener una única fuente en el manifiesto.

Alias actuales: `danger → secondary`, `reward → panel`, `dialog → boss_panel`, `tooltip → panel`. `danger` añade tinte `#DC9A86`; `navigation_active` añade `#FFE6B9`. Un alias de material no implementa por sí mismo un diálogo, tooltip o estado de error.

### Estados compartidos

| Estado | Presentación actual |
| --- | --- |
| Normal | Tinte `#FFFFFF`. |
| Hover | Tinte cálido `#FFF3DB`. |
| Pulsado / hover pulsado | Tinte `#B9A789`; no cambia tamaño ni silueta. |
| Deshabilitado | Material `#717878`, texto `#9CA9A6`; la causa se expresa en texto cuando afecta a la decisión. |
| Seleccionado | Correa primaria ámbar para navegación; texto oscuro. |
| Foco de teclado | Fondo transparente, borde `#F8E8B9` de 2 px, radio 5, expansión de 2 px. |

La sombra del texto de botón es negra a alfa `.2` en primarios y `.8` en secundarios, desplazamiento vertical 1 px. No existe una escala general de sombras flotantes; la profundidad principal viene de los materiales pintados y la iluminación.

`apply_button` fija mínimo 44 px; Historia pide 48 px. Extender con 48 px como altura de referencia de acciones, selectores y cierre. Los controles mantienen su silueta en todos los estados: una ficha de compañero no debe transformarse en una correa gigante al recibir hover.

### Superficies abiertas

Taller y Movimientos agrupan con columnas, títulos y separadores sutiles, sin panel individual alrededor de cada estadística o técnica. En Refugio las fichas usan fondo translúcido petróleo y borde inferior: normal alfa `.16`, seleccionado `.42`, hover `.55`. La selección se reconoce por el borde ámbar de 2 px; conserva foco nativo. Este tratamiento es una variante deliberada para figuras, no un reemplazo de los botones de acción.

## 6. Espaciado y composición responsive

La escala observada agrupa distancias de `4, 8, 10, 12, 16, 18, 20, 24, 32, 36` px. Usarlas según función; no reducirla artificialmente a una cuadrícula que cambie Historia.

| Relación | Medida actual |
| --- | --- |
| Margen exterior | 32; 16 en teléfono o altura corta. |
| Título y metadatos | Separación 4. |
| Pila interna habitual / navegación | 8. |
| Secciones, pie y rejilla habitual | 12; shell 10 con poca altura. |
| Cabecera | 16 entre grupos. |
| Rival e información / cabecera del Refugio | 32 horizontal, 12 vertical. |
| Taller | Banco 24; atributos 36 horizontal y 18 vertical. |
| Pie | Dos acciones, separación 12; primaria con proporción de expansión 1.4. |
| Ruta | Fila de 96 px, objetivo de marcador de 92 px; insignia máxima 48 px. |

Breakpoints existentes: teléfono si ancho `<600`; altura corta si alto `<540`; hero de Ruta apilado si ancho `<900` y no es altura corta. El ancho `<1100` reduce columnas de ciertas rejillas. Son reglas de contenido diferentes, no un único escalado global.

- **Escritorio:** lectura a la izquierda, rival grande a la derecha; altura reservada 420 px, 470 para jefe. Ruta horizontal con el número real de encuentros del capítulo.
- **Teléfono y tablet apilada:** personaje antes de la información, altura 270 px o 290 para jefe; cuerpo desplazable y pie siempre visible. Navegación conserva cinco opciones con nombres breves: Ruta, Mejora, Golpes, Equipo, Legado.
- **Horizontal con poca altura:** dos columnas de Ruta, figura de 160 px y metadatos superiores reducidos. Prioridad a decisión y acciones alcanzables.
- **Recorrido móvil:** cuatro marcadores por fila y altura `ceil(cantidad / 4) × 96`; diez encuentros requieren tres filas. Se conservan IDs, orden, nombre, nivel, estado y tipo de enemigo. El código conecta marcadores de la misma fila; no representa un camino continuo entre filas.
- **Refugio:** dos compañeros por fila en teléfono, tres bajo 1100, cuatro en escritorio; altura mínima 242/280. El retrato seleccionado grande y su descripción preceden a la colección.
- **Taller y Movimientos:** una columna en teléfono, dos fuera de él. Legado usa métricas de dos o cuatro columnas.

La pantalla no tiene scroll horizontal; `ScrollContainer.follow_focus` acompaña el foco. El scroll vertical llega hasta el último requisito y la última fila sin ocultarlos detrás del pie. Mantener acciones en el pie no permite borrar descripción, recompensas o recomendación para que todo parezca caber.

## 7. Imágenes, figuras, iconos y objetos

### Gramática de los lugares

| Sección | Composición que se conserva |
| --- | --- |
| Ruta inicial | Camino, faroles, arquitectura hacia bordes; espacio para la figura y zona de lectura oscura. |
| Tormenta / rutas posteriores | Raíces, hierro, musgo, piedra húmeda, montañas y luz fría; calor localizado de faroles. |
| Mejoras | Taller de piedra y madera, banco de trabajo; estadísticas como decisiones sobre ese espacio. |
| Movimientos | Mismo taller con tinte más frío; repetición útil del lugar, no otro fondo arbitrario. |
| Compañeros | Refugio abierto, tienda, suelo compartido, figuras completas. |
| Legado | Archivo de piedra, profundidad de escalones, reliquia y recuerdo del compañero. |

Las figuras son instancias del renderer de luchadores. Conservan identidad, apariencia y animación; la UI no sustituye su cuerpo por una ilustración incrustada en el fondo. La cámara común se obtiene de `CharacterVisualProfiles.portrait_scale` y `portrait_envelope`: reposo para fichas, ataque para la prueba de movimientos y victoria para Legado. El tamaño físico de cada especie procede de `world_height`; no se agranda cada silueta para llenar su caja. Los pivotes comparten suelo, con espacio para pies y extremos. La pose de victoria reserva el brazo alzado y su movimiento. No recortar antenas, colas o puños para uniformar cajas.

Las insignias son objetos pintados: medallón normal, pieza romboidal de élite y marco de jefe con remate flameado. Se acompañan de texto «AHORA», «SUPERADO», «POR LLEGAR», «ÉLITE» o «JEFE». El círculo funcional que destaca un marcador de ruta no es un efecto de fuego de combate; no extenderlo a auras ornamentales.

Los símbolos nativos `×`, `+ 1`, flecha de crecimiento y estrella de insignia cubren acciones simples. No añadir paquetes de iconos de estilo ajeno por defecto. Los iconos decorativos ignoran puntero y foco; el área interactiva pertenece al control nativo.

### Decoración con significado real

Hay seis objetos fuente en `props-v1.png` y siete definiciones de uso en el manifiesto. Se muestran como máximo tres, uno por ancla, ordenados por prioridad. Anclas existentes: inferior izquierda, inferior derecha y superior derecha; márgenes mínimos 8 px y escala adaptativa `.55–1.25`.

| Objeto/uso | Condición actual |
| --- | --- |
| Tela de Tepa / vendas de Balam | `appearance.body_style_id`, con `character_id` como fallback. |
| Brasero de Ascua | Ocho encuentros superados. |
| Reliquia de tormenta | Dieciséis encuentros y propiedad de `palette:luna`. |
| Mochila | Un encuentro superado o paleta jade equipada. |
| Medalla de Arena | Diez victorias reales recibidas por el caller. |
| Farol equipado | `aura:farol` poseída y `aura_id:farol` equipada. |

Las condiciones sólo seleccionan decoración. La capa visual no lee guardados, no concede recompensas y no inventa victorias para llenar un rincón. Si no recibe un dato opcional, el objeto permanece apagado. Ningún prop tapa texto o una acción en un formato estrecho.

## 8. Movimiento y FX

La navegación de Historia cambia de estado directamente. No hay un sistema global de entradas elásticas, zoom al hover o duración de transición entre pestañas que deba inventarse al centralizar. La vida de la pantalla viene del personaje, el lugar y la respuesta inmediata del control.

Para conservar el lenguaje de combate actualizado:

- Chispas estrechas y direccionales en el contacto; polvo tenue junto a los pies; pequeñas brasas que ascienden cerca del cuerpo.
- Sin anillos expansivos, ondas cerradas, bolas luminosas grandes ni marcos de fuego que compitan con la silueta.
- La indicación de turno usa resplandor de suelo difuso y pequeño rombo legible; no requiere un círculo ornamental.
- Carga, impacto, recuperación y KO siguen los eventos y relojes existentes. El estilo nunca adelanta daño ni modifica resultados.
- Pausa congela relojes de presentación. Movimiento reducido elimina emisiones y cámara innecesarias; conserva estado, foco y mensajes útiles.

Las cifras vigentes de CombatFX son límites del subsistema, no tamaños para iconos UI: 20 emisores, 320 partículas reservadas, máximo 24 por emisor y duración configurada aproximada `.17–.74 s`. La iluminación reflejada es breve y tenue. Para FX nuevos, reutilizar las reglas orgánicas y validar claridad móvil antes de aumentar cantidad o resplandor.

## 9. Estados de producto y accesibilidad

La adaptación visual conserva las causas y acciones de cada estado. Historia ya distingue bloqueo, máximo alcanzado, selección, talento elegido, práctica sin recompensa, reintento y error de guardado mediante texto.

Para login, red, inventario, historial y otras pantallas futuras, reutilizar la misma jerarquía: título breve, explicación concreta y acción contextual. Es una regla de extensión, no una afirmación de que StoryPanel implemente autenticación o reconexión.

- Una acción no disponible mantiene etiqueta legible y motivo. No comunicar error únicamente atenuando la textura.
- Conservar estados de teclado y foco visible en selectores, listas, diálogo y cierre. Un atlas no reemplaza semántica del control.
- Los bloques decorativos usan `MOUSE_FILTER_IGNORE` y `FOCUS_NONE`; no interceptan scroll o clics.
- Contrastar texto contra el fondo ya compuesto, no sólo contra el hex del fallback. La presente auditoría no certifica ratios de contraste.
- Mantener datos largos en texto nativo; probar nombres de usuario, traducciones, números grandes y requisitos completos.
- Los avisos críticos no deben depender de una elipsis o un tooltip exclusivo de ratón.

## 10. Plan de extracción identificado en la base

Ya existe el registro de materiales y lugares. La primera fase debe compartir la presentación antes de migrar páginas:

1. Elevar los colores semánticos, familias/tamaños por rol y medidas observadas a una fuente común, preservando valores de Historia.
2. Mantener `WorldVisuals` como acceso a superficies, estados e ilustraciones, y el manifiesto como fuente de regiones y contextos.
3. Formalizar variantes abiertas para lista de compañeros, fila estadística y técnica; compartir todos sus estados, no sólo el fondo normal.
4. Extender esa familia a entrada de texto, desplegable abierto, lista/tabla, aviso, estado vacío y diálogo. Reutilizar material petróleo, costura/borde y foco existentes; no producir un nuevo atlas antes de comprobar que falta.
5. Migrar después cada pantalla con una comparación nativa contra Historia, manteniendo callbacks, datos, foco, scroll y límites de interacción.

### Excepciones de la base que no conviene multiplicar

- La confirmación de redistribución usa un `StyleBoxFlat` local en vez del alias compartido `dialog`.
- El cierre `×` borra sólo el fondo normal; otros estados proceden de la correa heredada. Un futuro control de icono debe definirlos coherentemente.
- El `OptionButton` de capítulos comparte la superficie cerrada, pero no establece por sí mismo toda la estética del popup abierto.
- Los separadores de filas son nativos tenues; el separador ilustrado del atlas existe, pero no es obligatorio entre cada estadística.
- El foco del marcador de Ruta se dibuja localmente; los botones ordinarios usan un relleno ámbar interior compartido, sin contorno exterior.
- Fuentes, espaciado y colores están repartidos entre StoryPanel y el registro. No crear una segunda paleta mientras se extraen.

### Necesidades reales de assets

**Ningún PNG nuevo es necesario para comenzar.** Hay cinco entornos, dos atlas y suficientes variantes de superficie para construir el sistema común. Movimientos y rutas posteriores ya demuestran reutilización mediante contexto/tinte.

Sólo encargar arte adicional cuando exista una composición nueva que los fondos actuales no soporten, o un objeto reconocible que no pueda expresarse con los símbolos/materiales existentes. Un nuevo modo no exige automáticamente otro fondo. La necesidad actual de fuentes consistentes es de empaquetado/licencia, no de generación de imagen.

Un asset futuro debe conservar pintura, materiales, luz y espacio útil; carecer de texto incrustado; aportar regiones, margen, transparencia cuando corresponda y procedencia. Fondos opacos; objetos y superficies con alfa real. Cargar únicamente el lugar activo y retener como compartidos los atlas, sin precargar todos los ambientes.

## 11. Criterios para aceptar cada extensión

Comparar al menos los siete formatos ya usados por Historia: `1360×880`, `1224×792`, `1920×1080`, `768×1024`, `390×844`, `430×932`, `844×390`.

- El primer vistazo identifica lugar, figura o decisión principal y acción disponible.
- La tipografía, los colores, el material y sus estados proceden del sistema compartido; las excepciones quedan justificadas.
- La escena conserva aspecto, los personajes conservan escala coherente y ninguna pose queda cortada.
- Cabecera, cinco pestañas y pie no se solapan; la última fila y el último requisito son alcanzables.
- Probar normal, hover, pulsado, foco, deshabilitado, seleccionado, vacío, error y texto largo, según corresponda a la pantalla.
- Inspeccionar Ruta normal y jefe, diez nodos en teléfono, Taller, técnicas bloqueadas, compañero seleccionado y Legado completo/vacío.
- Verificar pausa y movimiento reducido donde haya animación; conservar relojes y eventos originales.
- Confirmar que los objetos responden a datos reales y que una decoración no captura interacción.

La revisión visual complementa las pruebas funcionales. Una aserción aprobada no demuestra por sí sola contraste, ausencia de cortes o coherencia del material.

## Referencias verificadas

- [StoryPanel: color y navegación](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/story_panel.gd:25), [tipografía y capas](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/story_panel.gd:220), [responsive](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/story_panel.gd:318), [composición de Ruta](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/story_panel.gd:460).
- [WorldVisuals: materiales y estados](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/world_visuals.gd:93), [WorldBackdrop](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/world_backdrop.gd:25), [manifiesto](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/data/ui_visual_manifest.json), [dirección del arte](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/ui/ART-DIRECTION.md).
- Capturas revisadas: [Ruta escritorio](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/story-world-desktop.png), [Ruta móvil](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/story-world-mobile.png), [diez encuentros](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/story-world-mobile-route.png), [jefe](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/story-world-boss.png), [Taller](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/story-world-workshop.png), [Legado](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/story-world-legacy.png), [Refugio con Bruma](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/organic-fx/live/story-bruma-1360x880.png).
- [FX orgánicos actuales](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/reports/organic-fx/COMBAT-FX.md), [turno difuso en ArenaView](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/arena_view.gd:214).

Las líneas anteriores identifican la versión inspeccionada; pueden moverse durante la extracción posterior del sistema. Notas de alcance y procedencia: `work/visual-system/style-notes.md`.


## 12. Contrato central implementado

La sección 10 conserva el diagnóstico anterior a la migración. La implementación vigente se apoya en estas fuentes; no se deben crear temas por pantalla:

| Fuente | Responsabilidad |
| --- | --- |
| `data/game_visual_tokens.json` | Paleta semántica, espacios 4/8/12/16/24/32/48/64, jerarquía de fuentes, altura táctil, foco y duración de transición. |
| `scripts/ui/game_visual_system.gd` | Theme compartido, fuentes por rol, superficies, tarjetas abiertas, barras, selectores, iconos grabados, velos y entrada de sección. |
| `data/ui_visual_manifest.json` + `world_visuals.gd` | Regiones originales, nueve parches, estados, fondos de cada lugar y elegibilidad de objetos. |
| `world_backdrop.gd` | Fondo lejano, ambiente ilustrado, objetos elegibles y velo oscuro. Sólo carga el ambiente activo. |
| `components/game_fighter_preview.gd` | Figura real con identidad/cosméticos; cámara común de reposo y escala entre especies, derivada de los perfiles de presentación del renderer. |
| `components/game_section_header.gd` / `game_badge.gd` | Jerarquía de cabecera e insignias con texto semántico y material de Historia. |
| `components/game_modal.gd` | Diálogo único: marco, overlay, título, cierre, scroll, foco y retorno. `use_location_layout()` reutiliza el contrato en una sección ilustrada abierta. |
| `components/game_overlay_focus.gd` | Tab/Shift-Tab dentro de la pantalla activa; respeta desplegables abiertos y Escape sin dobles acciones. |
| `components/game_battle_result_panel.gd` | Marco de recompensa, titular, explicación y XP; recibe valores reales, sin calcular recompensas ni dirigir animaciones. |

`Visuals.apply_button(control, role)` define todos los estados para `primary`, `secondary`, `danger`, `navigation`, `navigation_active` e `icon`. Un cierre usa `icon`; una tarjeta de lista usa `apply_card_button`, no otra correa. El estado seleccionado combina fondo abierto y línea ámbar. Deshabilitado conserva texto legible. `apply_option` tematiza también el desplegable abierto; `apply_progress` distingue XP, vida propia y vida rival dentro del mismo carril.

El Theme cubre paneles, tooltips, RichTextLabel, campos, listas, pestañas, sliders, checks, scrollbars y menús. Los pequeños iconos de controles son marcas nativas de crema/bronce con sombra oscura y peso común; las insignias narrativas continúan usando el atlas pintado. No se introdujo otro paquete de iconos.

Las secciones aportan lugar y acento: refugio para Menú/Ficha/Compañeros, taller para creación/inventario/mejoras, patio para Arena/Online, archivo para recuerdos y Legado. Matchmaking reutiliza los retadores de Online; las clasificaciones futuras tienen contexto registrado, pero esta migración no inventa una clasificación que el servidor no ofrece.

La apertura común usa un fundido de 0.18 s cuando el movimiento está permitido. Hover, presión y selección responden inmediatamente mediante el material; no hay rebote ni escalado decorativo que mueva objetivos táctiles. El renderer conserva sus propios relojes de acciones y energía ligada al cuerpo. Las diferencias de tamaño entre especies no se borran para llenar una tarjeta.

Arena y repeticiones comparten `Visuals.battle_veil` superior e inferior. El combate conserva su encuadre y espacio de acciones, con la ilustración a sangre detrás del HUD. Las repeticiones muestran el escenario, nombres, ropa y eventos guardados en el combate original; reproducir no actualiza identidades ni entrega recompensas.

Para añadir una pantalla: empezar por `Visuals.theme()`, elegir contexto con `mount_background`, usar roles compartidos y componentes; suministrar datos reales de identidad/propiedad; validar teclado, scroll y tamaños estrechos. Registrar la pantalla en `tests/test_visual_screen_audit.gd` y `work/visual-system/review-screens.json`, y regenerar el [tablero de comparación](visual-system/index.html). Los controles de seguridad del navegador/sistema quedan fuera de este Theme nativo.

## 13. Refugios personales del menú

Por solicitud del usuario, el menú principal deja de superponer un retrato animado y usa una ilustración cotidiana por cuerpo. Conserva los materiales, la tipografía y los estados de interacción de Historia. La consistencia entre personajes se limita al lenguaje pictórico; hábitat, luz, actividad, distancia de cámara y lado del personaje deben distinguirlos claramente. La composición de botones puede pasar a derecha o izquierda según el arte. El móvil conserva el foco del personaje y pone la navegación debajo. Véase [el catálogo y sus capturas](CHARACTER-REFUGES.md).

## 14. Contacto y profundidad durante el combate

Arena, Historia y repeticiones enlazan la pareja mediante `FighterView.set_combat_lane(limit, opponent)`. La separación de guardia sigue siendo estable; durante un ataque, el sprite puede atravesar el límite central para alcanzar visualmente el tercio frontal del torso rival. El acercamiento usa el mismo reloj de anticipación, viaje, impacto y recuperación. Nunca desplaza la raíz de combate, cambia la escala de especie o recalcula daño, alcance lógico o iniciativa.

El objetivo se calcula desde el torso neutral anotado y las raíces sin avance. No persigue el desplazamiento del otro atacante. El alcance visual usa el socket de mano anotado o, en paquetes sin esa anotación, el borde delantero de la pose de golpe. Esta aproximación visual no se convierte en anatomía ni hitbox. La altura del golpe sigue perteneciendo a la ilustración; no se hunden los pies ni se deforma al personaje para igualar estaturas.

Durante viaje/contacto/recuperación, el atacante se dibuja delante del rival. Los contactos simultáneos se ordenan por los eventos de presentación y mantienen separados los centros de los cuerpos. Se intercambian exclusivamente los dos puestos de dibujo; FX y HUD permanecen encima. Los empates conservan una orientación estable. Si un resultado interrumpe un ataque, la figura conserva su posición horizontal hasta el siguiente combate, sin teletransportarse hacia su carril. Movimiento reducido mantiene sus poses y prioridad visual, sin añadir el acercamiento.

Comparación reproducible: [contacto antes/después](combat-contact/index.html). Alcance, validación y límites en [COMBAT-CONTACT.md](COMBAT-CONTACT.md).


## 15. Daño ilustrado persistente

La autoridad actual del daño es la ilustración completa del personaje, no manchas o rayas generadas encima de su superficie. Los 23 cuerpos tienen una familia herida de 40 poses: 22 cuerpos con arte nuevo y Ascua con sus tres bancos critical-v1 reutilizados. Dañado y crítico (grados 2 y 3) comparten esa misma familia; el grado 1 conserva el arte limpio y las poses de fatiga. No anunciar tres niveles distintos de arte cuando existen limpio y herido.

Las heridas respetan la pintura, el material y la identidad: ropa rasgada, rostro cansado o magullado y posturas de fatiga; piedra astillada para los cuerpos de piedra. No introducir sangre, equipamiento nuevo ni marcas vectoriales flotantes. Los tintes cosméticos y flashes de impacto mantienen sus funciones independientes. El estado persiste durante movimientos, reacciones, victoria y KO; curarse no restaura prendas a mitad de una batalla.

Cada banco conserva un escalar común, celda 512, pivote 256/448 y densidad 1,5. El encorvamiento no autoriza aumentar la escala. Los metadatos corresponden al cuadro herido efectivo. Apoyos proyectados y anclajes heredados se identifican como aproximados; en ausencia de una mano anotada se permite el borde pintado de la pose de golpe como aproximación visual, nunca como anatomía certificada ni alcance lógico.

La aceptación exige alfa real, huecos transparentes y ausencia de halos sobre fondos claro y oscuro, además de revisión nativa de contacto y continuidad. El [tablero de daño ilustrado](illustrated-damage/index.html) conserva comparaciones técnicas y procedencia; el [informe](ILLUSTRATED-DAMAGE.md) distingue la revisión de arte, el pase nativo (3832/0, 39 PNG) y las seis suites headless (56 484/0). La muestra nativa no se anuncia como un recorrido animado de las 40 poses. Esta sección sustituye la descripción histórica del desgaste procedural, sin borrar sus evidencias anteriores. No modifica reglas ni progresión.

## 16. HUD pintado y cierre del combate

Arena, Historia y la presentación de Online comparten `game_combatant_hud.gd`: nombre, nivel y vida sobre el material pintado de recompensa, con cifras nativas y barras simétricas. Menú ocupa el centro superior; se eliminan la marca de Arena, el acceso directo Historia y la explicación redundante de ataques automáticos.

Al terminar, resultado y continuación forman un grupo centrado sobre un velo de la escena final. Esta superposición es intencional y reemplaza la antigua franja de recompensa bajo los pies. No reubica ni reescala a los luchadores, ni interviene en las recompensas. Los paneles posteriores se dibujan por encima del cierre; los números de daño permanecen detrás. Online interpreta el ganador desde el lado del usuario y conserva XP/rating recibidos. Las repeticiones históricas mantienen su encuadre anterior. [Revisión y pruebas](BATTLE-UI.md).


## Logros: información antes que decoración

La pestaña antes llamada Legado se presenta como Logros. Archivo conserva fondo y materiales de Historia, pero omite objetos decorativos y el emblema vacío. Objetivos, conseguidos y colección comparten tarjetas, foco y tipografía existentes. Los recuerdos de capítulos son secundarios y sus decisiones se despliegan a demanda. [Referencia actual](achievements-ui/index.html).


## Ruta: jerarquía de decisión

La nueva Ruta prioriza estado del encuentro, nombre y acción. El rival dispone de una reserva más compacta; el emblema vacío y los objetos decorativos se omiten. Fortaleza, habilidad y técnicas se consultan a demanda. Pie con acciones de 48 px de alto y hasta 240 px de ancho; repetir es secundario cuando existe continuación. [Referencia vigente](route-ui/index.html).


## Mejoras: lectura y confirmación

Puntos antes que introducción; valor actual prominente y próximo valor secundario. Ayuda a demanda y confirmación breve al aplicar. Material training_card compartido, cuatro/dos/una columnas, acciones de 48 px de alto y ancho acotado. [Referencia](upgrades-ui/index.html).


## Movimientos: decisiones separadas

Técnicas consume fichas; Talentos consume elecciones. Mostrar recurso y efecto antes que detalles numéricos. Material training_card compartido, tres/dos/una columnas, acciones de 48 px y foco persistente. [Referencia](moves-ui/index.html).


## Compañeros de Historia: selección informada

Separar consulta y activación con En uso / Vista previa. Destacar identidad, nivel y avance individual; mantener biografía y habilidades opcionales. Retratos con cámara común, material training_card compartido y acciones compactas. [Referencia](story-companions-ui/index.html).


## Sliders: grosor y contraste

El estilo compartido reserva 10 px de grosor para las barras horizontales y verticales. Carril oscuro, relleno dorado y agarrador de 32 px; foco visible dentro del control. Ajustes mantiene 48 px de área interactiva. [Referencia](sliders-ui/index.html).


## Precisión de sprites · 21 de septiembre de 2026

Los 23 cuerpos usan daño localizado sobre la geometría exacta de su pose sana. El daño no modifica la tonalidad, iluminación ni opacidad de las zonas intactas. Se conservan la escala propia de cada cuerpo y el origen común. Ver [informe y validación](SPRITE-PRECISION.md) y [comparativa](sprite-precision/index.html).


## Foco y rendimiento · 21 de septiembre de 2026

El foco compartido usa un relleno interior ámbar, sin trazo ni expansión fuera del control. Conservar navegación por teclado. Las listas suspenden los retratos fuera del área recortada; una pantalla opaca completa suspende la arena que cubre. Diálogos translúcidos y transiciones conservan el fondo. [Cambios y mediciones](PERFORMANCE-UI.md).


## Revisión de claridad · 22 de septiembre de 2026

Esta revisión extiende el sistema existente para que las decisiones sean más fáciles de encontrar. [Análisis por pantalla](UX-REVIEW.md) y [comparador nativo](ux-review/index.html).

- `GameReadingSections` reutiliza tipografía y navegación del sistema visual para ayuda y resúmenes desplegables. Los componentes solo presentan texto y estados; no calculan recompensas ni cambian progreso.
- Las acciones nombran su resultado y su coste cuando existe: `Mejorar · 1 punto`, `Entrar con el navegador`, `Mi ruta`. El compañero ya activo ofrece `Volver con…`.
- `OnlinePanel` divide Mi ficha en Atributos, Técnicas, Talentos y Estilo. Cambiar de sección conserva el estado del luchador, mueve el foco a la pestaña y vuelve al inicio de la lista; no escribe en el servidor.
- El selector de apariencias se llama `Conjunto visual…`. En móvil, la previsualización deja más espacio útil a las opciones; el pie admite varias líneas. Se conserva el tamaño relativo de las especies y la vista previa de contenido bloqueado sin equiparlo.
- La ayuda de teclado de los modales se muestra en ventanas de al menos 600 px. La X y la navegación por teclado siguen disponibles en las pequeñas.
- Durante el combate no se muestra la acción principal desactivada. En el resultado móvil, anuncio y acción quedan encima de las siluetas; el escritorio mantiene su centro.
- Los colores, materiales, contornos internos de foco y controles de volumen siguen siendo los compartidos. No se incorporan nuevas imágenes ni contornos exteriores.

Evidencia: 42 estados × 2 resoluciones = 84 capturas nativas, 153 comprobaciones de captura sin fallos. 26 suites de aceptación de UI e integración local pasan; las limitaciones de dos suites antiguas están detalladas en el informe. Datos desechables y API simulada, sin cambios en cuentas reales.


## Presencia de personajes · 22 de septiembre de 2026

La revisión posterior amplía moderadamente los retratos de Entrenamiento, Ficha, Personalizar móvil, selección e Historia/Online. Combate de escritorio admite hasta escala 2.05 con suelo 24 px más abajo. Móvil conserva el límite horizontal de dos animaciones completas. Las especies comparten cámara y mantienen su tamaño relativo; nunca se ajusta la escala a los píxeles de cada pose. No cambian arte, tonos ni lógica de juego.

[Medidas, decisiones y validación](CHARACTER-PRESENCE.md) · [Muro móvil más reciente](../../../work/character-presence/after/wall-390x844.png) · [Muro escritorio más reciente](../../../work/character-presence/after/wall-1360x880.png).
