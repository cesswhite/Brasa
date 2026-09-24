# Ficha · Atributos y detalles a demanda

| Antes | Después |
| --- | --- |
| Bloque extenso de texto con grandes separaciones. | Nueve atributos en cuadrícula y dos tarjetas de habilidad. |
| Valores actuales, crecimiento, fórmulas y rangos juntos. | Valores actuales por defecto; crecimiento opcional y detalle al seleccionar un atributo. |
| Decimales sin significado visual. | Se eliminan ceros finales: 19, 94%, 1.5×. El detalle conserva la precisión del formato original. |
| Biografía y reglas siempre expuestas. | Apartados desplegables “Perfil y estilo” y “Cómo progresa”. |
| Probabilidad de Golpe Firma repetida. | Se conserva la descripción real de la habilidad una sola vez. |
| Texto de estado temporal en el subtítulo. | Rol breve; explicación temporal en las reglas opcionales. |

El tamaño, encuadre y escala del personaje se conservan. La ficha usa el componente de vista previa existente y la misma geometría responsive. Materiales, tipografía y foco proceden del sistema visual compartido. El texto tiene ancho máximo de 720 px; en pantallas estrechas la cuadrícula pasa a dos columnas y las habilidades a una.

## Verificación

- **1260 comprobaciones nativas, 0 fallos**, en siete tamaños (1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 y 844×390). Incluye regresión de Entrenamiento, atributos reales, áreas táctiles, límites de tarjetas, desplazamiento por foco, fórmulas desplegables e inmutabilidad del perfil al consultar.
- **86 comprobaciones de identidad, 0 fallos**.
- **94 comprobaciones de Historia, 0 fallos**: valores de campaña, pausa al consultar la ficha y persistencia/recompensas existentes. Se actualizó la expectativa antigua del botón Historia: el acceso fue ocultado en la revisión previa de combate. El primer pase de esta suite conserva esos siete fallos de expectativa en `work/profile-ui/story.log`; el pase final está en `story-final.log`.

28 capturas de ficha con perfiles desechables; las ocho capturas adicionales de Entrenamiento pertenecen a su regresión. No se modifican los guardados personales, las reglas de combate ni el backend. La ficha de mejoras fuera del combate de Historia conserva su navegación previa.

[Ver capturas](profile-ui/index.html).
