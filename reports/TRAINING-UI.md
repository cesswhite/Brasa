# Entrenamiento: claridad y ayuda contextual

La composición ahora agrupa personaje y entrenamiento en un bloque de anchura limitada, con tarjetas legibles y más separación. Los puntos disponibles destacan junto al nombre; experiencia y coste quedan en segundo plano. Se conservan los valores y las reglas de progreso existentes.

[Comparación y estados nativos](training-ui/index.html).

| Antes | Después |
| --- | --- |
| Estadísticas extendidas por media pantalla sin agrupación clara. | Composición centrada, columna de hasta 620 px, cuatro tarjetas con fondo translúcido y espacios de 20 px. |
| Efectos mezclados con frases explicativas permanentes. | Efecto actual y vista previa calculada del siguiente punto; explicación breve solo al pulsar `?`. Una explicación abierta a la vez. |
| Número de puntos pequeño y alejado. | Puntos destacados, estado sin puntos y texto que explica cómo obtenerlos. Coste indicado una sola vez. |
| Botones deshabilitados sin ayuda utilizable. | La ayuda permanece activa al agotar puntos; mejorar sigue bloqueado cuando corresponde. |
| Foco y hover poco conectados con el atributo. | Tarjeta y material del botón responden a hover/foco. El foco de mejora utiliza el color, sin contorno blanco exterior. |
| Pocas señales tras mejorar. | Valor y vista previa se actualizan; confirmación de mejora y puntos restantes. Aviso explícito si el cambio no pudo guardarse. |
| Dos columnas estrechas en móvil. | Una columna cuando faltan 560 px; botones y ayuda de 48 px, scroll de teclado y desplazamiento a la explicación al abrirla. |
| Subtítulo y pie instructivos permanentes. | Título breve, sin instrucciones redundantes. El personaje mantiene las proporciones del sistema compartido. |

## Verificación

- Documentos/entrenamiento: **756 comprobaciones, 0 fallos en siete tamaños**. Ayuda desplegable, foco, texto, límites, coste exacto de un punto, persistencia en archivos desechables y conservación de la campaña separada.
- Navegación real desde el menú: **327 comprobaciones, 0 fallos**.
- Ocho capturas nativas: con puntos, ayuda, mejora aplicada y sin puntos, a 1360×880 y 390×844. Usan Ónix de prueba; sus números no corresponden a una cuenta real.
- Los cálculos de vista previa proceden de la misma función de estadísticas del juego. No hay nuevas reglas, recompensas ni cambios de balance.

[Log funcional y nativo](../../../work/training-ui/final.log) · [Log de navegación](../../../work/training-ui/navigation.log).

La comparación utiliza la captura proporcionada por el usuario. El primer intento automatizado de capturar el estado anterior encontró scripts de daño en transición y no se usa como evidencia. Las capturas finales se obtuvieron sin errores de compilación ni ejecución. No se generó ni modificó arte para esta tarea.
