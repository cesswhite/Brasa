# Tu compañero · Controles compactos y vista ampliada

## Jerarquía y proporciones

| Antes | Después |
| --- | --- |
| Cancelar y Guardar ocupaban el ancho completo del pie. | Botones de hasta 132 y 200 px, alineados a la derecha, con 12 px entre ellos. Se conserva el área táctil y el foco de teclado. |
| El aumento de la figura tenía un límite fijo de 1,90 aunque sobrara espacio. | La figura aprovecha el espacio de su cámara común. Cada cuerpo mantiene sus proporciones físicas; no se igualan alturas. |
| «Combinaciones…» ocupaba toda la fila y no explicaba su función. | «Aplicar estilo…» ocupa una fila acotada junto a «Al azar». Al abrirlo aparece «Color, efectos y gestos»; la ayuda explica que conserva cuerpo y nombre. |
| Texto cercano a los remates del selector y a su flecha. | Márgenes interiores propios para el texto y espacio reservado para la flecha, usando los mismos materiales compartidos. |
| «Al azar» tenía una explicación genérica. | Explica que prueba cuerpo, colores y efectos de la colección; sólo se guardan al confirmar. |

Cambio de presentación en `customization_panel.gd`. Se mantienen los estilos pintados, el borrador independiente, los requisitos de desbloqueo y las acciones existentes. En móvil se conserva el encuadre limitado por el espacio disponible; la ampliación aprovecha especialmente las ventanas grandes.

## Verificación

- Distribución y comportamiento: **2432 comprobaciones, 0 fallos**, siete tamaños, creación/edición, borrador, cancelar, confirmar, cosméticos bloqueados y selección aleatoria.
- Encuadres: **61289 comprobaciones, 0 fallos**. Las 21 apariencias comparten cámara por acción en tres tamaños; se recorren reposo, golpe, entrada y victoria para comprobar límites y ausencia de cambios de escala durante cada animación.
- Foco y cierre de ventanas: **74 comprobaciones, 0 fallos**.
- Capturas integradas desde Main: **13 comprobaciones, 0 fallos**, escritorio y móvil.
- Capturas nativas adicionales: Ónix, Mugo, Tepa y Nima; selector abierto. Las capturas son fixtures locales o en memoria y no modifican partidas del usuario.

[Revisión visual](customization-ui/index.html). Logs, métricas y PNG originales: `work/customization-ui/`.
