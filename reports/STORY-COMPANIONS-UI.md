# Historia · Compañeros

| Antes | Después |
| --- | --- |
| Encabezado de capítulo ajeno a la selección y marca redundante. | Compañeros e instrucción breve: cada historia conserva su progreso. |
| Nombre, biografía y habilidades mezclados. | Ficha con nombre, rol, nivel, avance de campaña y XP. Detalles en “Conocer al compañero”. |
| Personajes pequeños y selección poco clara. | Vista principal ampliada, colección con cámara común y marca de selección. |
| Estado de campaña expuesto como datos dispersos. | Sin empezar, capítulo y encuentro actual, capítulo completado o historia completada; una barra de 100 encuentros. |
| Lista mezclaba rol, nivel y progreso con mucha información. | Tarjetas centradas en nombre, nivel y estado de Historia. El rol está en la ficha y en la ayuda contextual. |
| Grandes botones inferiores y Personalizar a todo el ancho. | Acciones compactas con 48 px de altura; Empezar historia o Continuar historia según progreso real. |
| Seleccionar una tarjeta no diferenciaba claramente consulta y uso. | Etiquetas En uso / Vista previa. Confirmar con la acción inferior conserva el flujo existente. |
| Objetos superpuestos y descripciones permanentes. | Fondo y materiales compartidos; decoraciones omitidas y lectura opcional de fortaleza, debilidad, habilidad y biografía. |
| Reordenación visual sin atención al teclado o nombres largos. | Foco vuelve a la ficha, tarjetas adaptan su altura y sus retratos comparten escala. |

La vista principal reserva 360 px en escritorio, 280 en teléfono y 180 en ventanas bajas. La colección usa tres columnas en escritorio y dos en ventanas más estrechas. Las diferencias físicas entre cuerpos se conservan mediante el componente de retrato compartido y una cámara común para las tarjetas.

Cada perfil muestra su propio progreso de Historia. La vista no cambia el compañero activo hasta que se confirma. Un perfil recién creado sin combates ni avance presenta Empezar historia. Personalizar dirige al compañero que se está consultando.

## Verificación

- **5917 comprobaciones nativas, 0 fallos**, en siete tamaños: 43 capturas, seis estados por tamaño y un caso adicional con nombre largo. Perfiles en memoria; selección, identidad, XP, foco, texto, escala común, límite del retrato y pie fijo verificados.
- **436 comprobaciones de StoryPanel, 0 fallos**: navegación, campañas vacías y acceso al último compañero.
- **337 comprobaciones de integración de campaña, 0 fallos**: persistencia y progresión existentes.

No se modificaron partidas personales, balance ni backend. Se reutiliza el arte existente. [Capturas nativas](story-companions-ui/index.html).
