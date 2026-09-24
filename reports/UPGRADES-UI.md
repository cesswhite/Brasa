# Historia · Mejoras

| Antes | Después |
| --- | --- |
| Introducción extensa, personaje decorativo pequeño y atributos dispersos. | Puntos disponibles, coste y ocho tarjetas legibles con los materiales compartidos. |
| Comparaciones idénticas, como 832 → 832. | Valor actual, resultado real de invertir un punto o “Máximo alcanzado”. |
| Explicaciones largas siempre visibles. | Una descripción breve y ayuda individual con el botón “?”. |
| Redistribuir y navegación a todo el ancho. | Acciones compactas, con altura táctil de 48 px. |
| Poco contexto después de gastar puntos. | Confirmación breve y foco de teclado conservado tras actualizar. |

La cuadrícula usa cuatro columnas en escritorio, dos en vistas intermedias y una en teléfono. En ventanas bajas y teléfonos se desplaza el contenido; las acciones inferiores permanecen accesibles. Las ayudas también pueden abrirse sin puntos o en atributos al máximo.

La vista previa del siguiente valor usa las estadísticas reales de Historia. Se impide gastar desde esta vista cuando el atributo ya no puede crecer. Redistribuir conserva su confirmación existente y permite cancelar sin cambios. El progreso, los costes y las fórmulas no se modifican.

## Verificación

- **2590 comprobaciones nativas, 0 fallos**: siete tamaños, 35 capturas y cinco estados (atributos, ayuda, mejora aplicada, sin puntos y confirmación de redistribución). Incluye gasto real de puntos en memoria, topes, foco, protección de guardado y límites de texto/botones.
- **436 comprobaciones de StoryPanel, 0 fallos**: navegación y estados de Historia.
- **337 comprobaciones de integración de campaña, 0 fallos**: redistribución, cancelación, persistencia y recuerdos de capítulos con archivos desechables.

Las capturas usan perfiles de prueba en memoria. No se editaron partidas personales ni backend. Se reutilizaron los fondos y materiales existentes. [Galería nativa](upgrades-ui/index.html).
