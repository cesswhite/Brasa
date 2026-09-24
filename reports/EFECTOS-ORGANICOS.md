# Efectos integrados en los personajes

Se sustituyen los círculos de fuego y energía por partículas pequeñas que nacen junto al cuerpo, se desprenden con el movimiento y desaparecen gradualmente. El color, la dirección y la duración distinguen un impacto, una carga y cada estado.

| Antes | Ahora |
|---|---|
| Anillos grandes en cargas y transformación | Brasas ascendentes y chispas próximas a manos y torso |
| Estallidos radiales sobre el personaje | Chispas direccionales desde el punto de contacto |
| Destello blanco intenso sobre toda la ilustración | Iluminación breve que conserva el detalle del personaje |
| Auras con contorno circular bajo los pies | Motas cálidas, luciérnagas y polvo dorado alrededor del cuerpo |
| Onda circular al entrar | Un pequeño desprendimiento de brasas |
| Estelas pintadas y nubes fijas | Partículas que se separan del actor, frenan y se desvanecen |
| Anillo del personaje activo | Luz de contacto difusa y el pequeño marcador de turno |

Fuego usa brasas cálidas; veneno, motas verdosas apagadas; curación, luz verde suave; defensa, destellos fríos cortos. Los efectos nacen en zonas de la pose actual —mano, pecho, espalda o pies— y respetan su orientación, inclinación y salto. La luz reflejada se aplica dentro de la transparencia de la ilustración.

El mismo sistema se utiliza en los combates y en las repeticiones. Hay un límite de 20 emisores, 12 emisiones pendientes y 320 partículas; las partículas extinguidas se liberan. La pausa congela sus relojes. Movimiento reducido suprime las ráfagas y las sacudidas, y conserva una indicación estática del turno.

Las partículas se dibujan con un pequeño grano suave generado en memoria por Godot. Los atlas de personajes y escenarios mantienen sus píxeles originales. Las ocho identificaciones de efectos siguen funcionando con las técnicas, los eventos y los historiales existentes; el antiguo atlas de efectos queda disponible para compatibilidad y para la comparación anterior.

## Muestras y validación

Las comparaciones se capturan directamente en Godot, con igual encuadre y reloj manual. Se distinguen de los combates reales y no generan recompensas ni guardados del jugador.

La revisión final se realizó en 1360×880 y 390×844. Las brasas tienen un núcleo pequeño y un borde suave para seguir siendo visibles al reducir el tamaño; el impacto conserva los detalles del rostro y la ropa. Se revisaron también salto, desplazamiento, veneno, curación, defensa, pausa y movimiento reducido.

Vídeos del muestrario: [escritorio](organic-fx/organic-fx-desktop.mp4) · [móvil](organic-fx/organic-fx-mobile.mp4). Cada uno reúne cuatro escenas en 3,2 segundos a 30 FPS, sin audio.

| Muestra | Antes | Después |
| --- | --- | --- |
| Fuego y transformación, escritorio | [PNG](organic-fx/before/2-1360x880.png) | [PNG](organic-fx/after/2-1360x880.png) |
| Carga, impacto y auras, escritorio | [PNG](organic-fx/before/1-1360x880.png) | [PNG](organic-fx/after/1-1360x880.png) |
| Fuego y transformación, móvil | [PNG](organic-fx/before/2-390x844.png) | [PNG](organic-fx/after/2-390x844.png) |
| Estados, móvil | [PNG](organic-fx/before/3-390x844.png) | [PNG](organic-fx/after/3-390x844.png) |

Además del muestrario, se iniciaron ocho combates de Liga e Historia desde la interfaz de producción con perfiles desechables. Las capturas se tomaron al observar eventos reales, sin imponer poses: [escritorio](organic-fx/live/league-battle-onix-1360x880.png), [móvil](organic-fx/live/battle-bruma-390x844.png), [observaciones](organic-fx/live/observations.json).

| Validación | Resultado |
| --- | --- |
| Emisores, límites, anclajes, eventos tardíos y memoria | 129 comprobaciones, 0 fallos |
| Anclajes y repeticiones, sin ventana | 172 comprobaciones, 0 fallos |
| Renderizado nativo, pausa, movimiento reducido y 20/60/120 FPS | 185 comprobaciones, 0 fallos |
| Distribución del combate en siete tamaños | 2.139 comprobaciones, 0 fallos |
| Relojes, KO, personalización, secuencias, identidad e interfaz online | 10.164 comprobaciones, 0 fallos |
| Ocho combates desde Main | 153 comprobaciones, 0 fallos |
| Catálogo e inventario del backend local | 9 pruebas, 0 fallos; compilación correcta |

Las comprobaciones de 20/60/120 FPS verifican estados, límites y extinción; no son una medición de rendimiento del dispositivo. Los registros y las huellas de los archivos se guardan en [validation.json](organic-fx/validation.json). Las descripciones de Farol y Corona se actualizaron para corresponder a su apariencia, conservando sus IDs y condiciones de desbloqueo.
