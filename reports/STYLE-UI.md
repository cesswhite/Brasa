# Estilo · Entradas y celebraciones

| Antes | Después |
| --- | --- |
| Dos listas sin contexto suficiente. | Entrada y Victoria tienen su propia sección y explican cuándo se muestran. |
| Cuatro opciones en total, descritas con términos técnicos. | Ocho opciones con descripciones de la acción y una muestra del personaje. |
| Había que encontrar los botones de demostración. | Elegir una tarjeta reproduce el gesto sobre el compañero. Repetir y Auto permiten controlar la presentación. |
| Combinaciones y azar ocupaban espacio en esta pantalla. | Se retiran de Estilo para dar prioridad a los gestos; siguen disponibles en las otras pestañas. |
| Opciones bloqueadas sin demostración. | Prueba temporal, requisito visible, Volver y guardado desactivado. Nunca se concede propiedad por previsualizar. |
| Listas con poca separación. | Tarjetas con nombre, descripción y estado. Dos columnas en espacio amplio, una en pantallas estrechas; vista previa y controles persistentes. |

## Opciones

**Entrada — antes de luchar:** Clásica (guardia), Pulso (chispas), Reverencia (inclinación breve; nivel 4), Bruma (nube en los pies; encuentro 6 de Historia).

**Victoria — al ganar:** Clásica (pequeño salto), Saludo (reverencia y pose final), Serena (pose tranquila; 4 victorias de Liga), Festival (pétalos dorados; encuentro 16 de Historia).

Las cuatro nuevas opciones se desbloquean mediante los sistemas existentes. Las anteriores conservan su propiedad y comportamiento. Las miniaturas son muestras estáticas; la figura principal reproduce la animación real. Auto repite cada cuatro segundos y se puede desactivar. Con movimiento reducido o pausa no hay reproducción automática; los efectos respetan sus ajustes de presentación.

## Verificación

- 13 476 comprobaciones de estilos: previsualización, bloqueo de guardado, restauración del borrador, repetición, pausa y movimiento reducido. También encuadre durante los cuatro estilos nuevos en los 21 cuerpos y dos tamaños. Sin fallos.
- Personalización final: 3 082 comprobaciones en siete tamaños, sin fallos. Captura nativa inicial: 3 174 comprobaciones. Las doce imágenes de `demo/` y el video reflejan el ajuste final de espacio y Bruma; la matriz `native/` es anterior a ese ajuste.
- Partículas existentes: 303 comprobaciones, sin fallos.
- Identidad: 1 054 comprobaciones; foco: 74. Sin fallos.
- Encuadres existentes: 61 240 comprobaciones, sin fallos.
- Servidor local: 12 pruebas, sin fallos. Umbrales exactos, rechazo de objetos no poseídos y estadísticas intactas.

[Capturas nativas y video](style-ui/index.html). Perfiles de prueba en memoria: no se modificaron partidas personales ni datos de producción. El video muestra ocho segundos de animaciones del renderer del juego con el reloj de presentación controlado para la captura.

Catálogo versión 5 exportado y sincronizado con el backend local. **Los estilos nuevos requieren publicar el catálogo para estar disponibles online.** No se publicó Cloudflare en esta tarea.
