# Efectos · Partículas visibles y colección con pruebas

## Presentación e interacción

| Antes | Después |
| --- | --- |
| Partículas dibujadas por el padre, detrás del sprite opaco. | Capa de partículas encima de la ilustración, repartidas por los flancos y alrededor del torso/pies, sin círculos de energía. |
| Farol tenía pocas chispas; los efectos compartían una apariencia muy parecida. | Mayor densidad y contraste, núcleos luminosos, halos suaves y formas diferenciadas: chispas, luciérnagas, pétalos, lluvia, ceniza, hojas y cristales. Nacen y desaparecen gradualmente. |
| La estela dependía del breve fotograma de sombra del golpe. | Mantiene una cola de partículas que se desvanece durante aproximadamente medio segundo después del movimiento. |
| Auras y estelas mezcladas en una lista de texto. | Secciones Auras / Estelas y tarjetas con muestras del renderer real, nombre, selección y requisito. Dos o tres columnas según el espacio. |
| Un efecto bloqueado sólo mostraba un aviso. | Puede probarse sobre el compañero. Guardar queda desactivado y Volver recupera el borrador sin conceder propiedad. También se conservan las pruebas de colores y skins. |
| La estela podía desaparecer antes de apreciarse. | Elegirla demuestra un golpe inmediatamente y la sección repite el gesto cada 2,2 segundos cuando el personaje está en reposo. |
| Movimiento reducido suprimía la muestra de estela. | En el editor ofrece una muestra estática de cinco partículas como máximo, sin golpes automáticos. En combate no añade estelas en movimiento reducido. |

Hay **7 auras y 5 estelas activas**, además de las opciones Sin aura / Sin estela. Se conservan las formas y tiempos del combatiente, sin cambios en reglas, daño, iniciativa o estadísticas.

## Nuevos efectos

| Tipo | Efecto | Requisito |
| --- | --- | --- |
| Aura | Pétalos de cempasúchil | Nivel 3 |
| Aura | Llovizna lunar | Nivel 6 |
| Aura | Ceniza viva | Encuentro 12 de Historia |
| Aura | Cristales de amatista | 6 victorias de Liga |
| Estela | Cometa azul | Encuentro 30 de Historia |
| Estela | Hojas al viento | Nivel 8 |
| Estela | Polvo de cobre | 5 victorias de Liga |

Los niveles y victorias se alcanzan con un luchador; las recompensas siguen perteneciendo al inventario compartido. Las condiciones antiguas no se cambiaron. La vista previa utiliza una apariencia temporal independiente: ni el botón ni el controlador permiten confirmar una prueba bloqueada.

## Validación

- **3167 comprobaciones de personalización, 0 fallos:** siete tamaños, propiedad, borrador, confirmación, pruebas bloqueadas y encuadres.
- **303 comprobaciones de partículas, 0 fallos:** muestras deterministas, máximo de 28 partículas por emisor, delante de la ilustración, persistencia/desvanecimiento de estelas, pausa, movimiento reducido y demostración automática sin equipar.
- **1046 comprobaciones de identidad, 0 fallos:** desbloqueos, integridad y persistencia mediante archivos desechables.
- **172 comprobaciones de FX y repetición, 0 fallos.** La muestra técnica antigua colocaba la transformación de Ascua 3 px fuera del margen móvil. Se comprobó que la geometría anterior y la actual eran idénticas y se ajustó 8 px exclusivamente la posición de esa muestra, sin cambiar la cámara ni los personajes del juego.
- **74 comprobaciones de foco, 0 fallos.**
- **11 pruebas del servidor local, 0 fallos:** efectos nuevos, paletas y operaciones de identidad. Se comprueban umbrales, rechazo de equipamiento no poseído y estadísticas intactas.

[Revisión visual y video](effects-ui/index.html). Dieciséis capturas nativas finales y video de cuatro segundos, generado a partir de 64 fotogramas del juego con reloj de presentación manual. Fixtures en memoria; no se modificaron partidas personales ni datos remotos. `work/effects-ui/demo/` es la evidencia visual final; `native/` conserva la matriz de interfaz previa al ajuste final del contorno de pétalos y fundido.

Catálogo versión 4 exportado y sincronizado con el backend local. **Los siete efectos nuevos, al igual que los nuevos colores, todavía requieren publicar el catálogo en Cloudflare para desbloquearlos online.** La mejora de representación de los efectos existentes pertenece al cliente del juego.
