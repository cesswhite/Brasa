# Historia como lugar · auditoría y plan previo

## Arquitectura comprobada

`scenes/main.tscn` instancia `main.gd`; Historia se abre como `StoryPanel`, un Control generado en código que emite señales al controlador. `StoryProgression` conserva toda la lógica y persistencia. No se modifica ese límite.

StoryPanel usa MarginContainer → VBoxContainer → cabecera, HBox de navegación, ScrollContainer con cuerpo dinámico y pie fijo. Los cinco destinos son Ruta, Mejoras, Movimientos, Compañeros y Legado. Los breakpoints actuales son 600 px para teléfono, 540 px de alto para formato corto, y 1100 px para columnas. Hay fixtures de siete tamaños entre 390×844 y 1920×1080, incluyendo 844×390.

Su aspecto actual proviene casi por completo de StyleBoxFlat: fondo azul verdoso plano, tarjetas uniformes con esquinas redondeadas, navegación rectangular y fichas de encuentros en grid. La ficha del rival aparece debajo del grid y su preview estándar mide 166×172, por lo que queda fuera del primer viewport en escritorio. SystemFont usa Avenir Next/DejaVu Sans/Arial. No hay un sistema de superficies ilustradas ni NinePatch en esta pantalla.

El juego ya tiene FighterView con sprites y apariencia dinámica, fondos pintados de los Faroles y Tormenta, catálogo de cosméticos y metadatos de capítulos. Se reutilizan los personajes, animaciones, identidad y todos los datos. No se sustituye el combate ni se cambian valores de progresión.

## Dirección visual

Ilustración 2D pintada, con bordes suaves y pincel visible. Piedra gastada, madera oscura, cobre, cuerda y paños cosidos. Luz de faroles ámbar contra niebla azul petróleo. Colores minerales y de tierra; acentos acotados según capítulo. Ornamentos de sol, brasero y sendero, coherentes con Brasa. Sin fotorrealismo, pixel art ni iconos planos ajenos al mundo.

El rival domina el encuentro a la derecha en escritorio; información y acciones mantienen contraste a la izquierda. La ruta se representa mediante hitos conectados, con números y estados nativos. En móvil la composición se apila y conserva scroll y pie de acciones. Los jefes usan más escala, luz y un marco/insignia propios.

## Plan de assets

| Asset | Uso |
| --- | --- |
| `assets/ui/story/journey-v1.png` | Camino de faroles y patio de entrenamiento: capítulo inicial y variantes templadas. |
| `assets/ui/story/storm-v1.png` | Patio de raíces, hierro y lluvia: identidad del capítulo 2 y variantes de tormenta. |
| `assets/ui/workshop/workshop-v1.png` | Taller y equipo de entrenamiento: Mejoras/Movimientos. |
| `assets/ui/companions/camp-v1.png` | Refugio alrededor de un fuego: Compañeros. |
| `assets/ui/legacy/archive-v1.png` | Archivo y pedestales de recuerdos: Legado. |
| `assets/ui/shared/surfaces-v1.png` | Atlas reutilizable de superficies y marcas: botón primario/secundario, marco estándar/jefe, hito y separador. |
| `assets/ui/shared/props-v1.png` | Atlas transparente: pertenencias de luchadores, recuerdos de jefes, mochila y medalla de Arena. |

Todos los recursos se generan sin texto, cifras ni etiquetas. Sus regiones se registran una vez y se consumen con AtlasTexture y StyleBoxTexture/nine-slice. El arte no contiene estado del juego.

## Sistema y secuencia

Un registro de temas enlaza IDs estables con fondos, superficies, acentos y props. Condiciones de datos eligen como máximo unos pocos objetos según personaje, apariencia, objetos poseídos y encuentros superados. Los props ignoran el ratón, se mantienen detrás del contenido y nunca conceden logros.

Primero se integra la Ruta y se comprueban escala del rival, lectura y navegación; después se aplica la misma familia al taller, refugio y legado dentro de Historia. No se rediseña el resto del juego en esta entrega. Los fondos se cargan al abrir la sección y se libera la referencia anterior; no se precargan todos los capítulos. Movimiento ambiental, si se añade, debe respetar la preferencia de movimiento reducido.

La entrega requiere capturas nativas, comparación con la pantalla anterior, estados normal/hover/pressed/focus/disabled, siete tamaños, navegación/acciones originales y guardados intactos. Los snapshots de código y hashes iniciales están en `work/world-ui/before.json`.
