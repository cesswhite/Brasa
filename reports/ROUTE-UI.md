# Historia · Una ruta más clara

| Antes | Después |
| --- | --- |
| Nombre y título del rival repetidos, emblema vacío, textos de práctica duplicados. | Encuentro y estado, un nombre, nivel y una explicación breve. |
| Todos los detalles de combate expuestos. | “Conocer al rival” despliega fortaleza, debilidad, habilidad y técnicas. |
| Rival de hasta 470 px y extensa introducción. | Reserva de 300 px en escritorio, 180 en vista apilada y 160 en ventana baja. Se conserva su proporción. |
| Marca y XP competían con la decisión inmediata. | Capítulo, personaje, nivel y puntos disponibles; la XP sigue en sus vistas de progreso. |
| Selector repetía el título completo del capítulo. | Selector compacto de capítulo y rango de encuentros; mapa y una sola barra de avance. |
| Repetir ocupaba casi todo el pie y continuar requería buscar otra pestaña. | Botones compactos: repetir como acción secundaria y continuar como principal, alineados a la derecha. |
| Objetos decorativos sobre el mapa. | Se conservan paisaje y materiales, se omiten los objetos superpuestos en Ruta. |

## Acciones

El combate actual tiene su acción habitual de entrar o reintentar. Al consultar encuentros anteriores aparece “Repetir” junto a “Continuar historia”: repetir emite la práctica del encuentro seleccionado; continuar vuelve al encuentro actual. Si el capítulo está completado, continuar solicita el siguiente mediante el controlador existente. Tras el último capítulo lleva a Logros.

Los encuentros futuros muestran “Bloqueado” y una acción para volver a la campaña actual. Los tiempos de espera y la protección de guardado siguen aplicándose. Las repeticiones conservan la advertencia de que no entregan XP ni recompensas.

Los botones conservan 48 px de altura táctil; tienen anchos acotados de hasta 240 px. En teléfono se acortan las etiquetas (“Repetir 30”, “Continuar”) para evitar recortes y solapamientos. El pie sigue accesible al desplazarse.

## Verificación

- **1498 comprobaciones nativas, 0 fallos**, siete tamaños y 28 capturas: encuentro actual, ayuda abierta, encuentro bloqueado y capítulo superado. Se validaron límites y separación de botones, texto legible, detalles opcionales, eventos separados para repetir/continuar, guardado protegido y perfiles inmutables.
- **436 comprobaciones de StoryPanel, 0 fallos**. Se actualizó la expectativa de la etiqueta antigua “Personaje nv.” a “Nivel”; navegación, mapas, enfriamientos y capítulos conservados.
- **94 comprobaciones de integración de Historia, 0 fallos**. Persistencia y recompensas existentes.

Los datos de la galería son fixtures en memoria. No se modificaron partidas personales, balance, recompensas ni backend. Reutiliza el arte y los materiales existentes. [Capturas](route-ui/index.html).
