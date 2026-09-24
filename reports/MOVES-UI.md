# Historia · Movimientos

| Antes | Después |
| --- | --- |
| Técnicas y talentos mezclados en una lista extensa. | Dos secciones, Técnicas y Talentos, con recursos y acciones diferenciados. |
| Capítulo, marca, XP e introducciones compitiendo con las decisiones. | Movimientos, personaje y nivel; instrucciones breves para la sección activa. |
| Párrafos técnicos siempre visibles. | Ventaja resumida y riesgo de cada técnica; cifras exactas y ayuda en “?”. |
| Elecciones de talento poco claras. | Recursos disponibles, talentos activos de un máximo de tres y coste de elegir. |
| Botones de ancho completo. | Acciones compactas con objetivos táctiles de 48 px y pie persistente. |
| Detalles y acciones sin superficies que los agrupen. | Tarjetas del material compartido, tres columnas en escritorio, dos intermedias y una en teléfono. |
| Poco contexto después de una elección. | Confirmación de técnica mejorada o talento activo, foco y desplazamiento hacia el control utilizado. |
| Estados de disponibilidad difíciles de distinguir. | Bloqueada, Al máximo, Sin fichas, Elegido, Sin elecciones y Cupo completo. |
| Redistribución y adquisición de recursos poco explicadas. | Ayuda para cambiar talentos desde Mejoras y requisitos reales de fichas/elecciones. |

Las técnicas siguen siendo seleccionadas automáticamente por el combate. Las fichas mejoran sus grados; las elecciones activan talentos. Las cifras exactas se conservan en la ayuda. Leer detalles o cambiar entre secciones no gasta recursos.

Se eliminan los objetos decorativos en esta vista y se reutilizan fondo, tarjetas, tipografía, materiales y foco compartidos. En ventanas bajas el contenido se desplaza; el pie sigue accesible.

## Verificación

- **1652 comprobaciones nativas, 0 fallos**, siete tamaños y 42 capturas: técnicas, ayuda, talentos, elegido, sin fichas e inicio con técnicas bloqueadas. Uso real de la progresión en memoria, gasto de recursos, límite de grado, elecciones únicas, protección de guardado, foco y geometría.
- **436 comprobaciones de StoryPanel, 0 fallos**: navegación y estados de Historia.
- **337 comprobaciones de integración, 0 fallos**: señales conectadas a la progresión, persistencia y redistribución.

Datos de prueba en memoria y archivos de integración desechables. Sin cambios de balance, partidas personales o backend. [Galería nativa](moves-ui/index.html).
