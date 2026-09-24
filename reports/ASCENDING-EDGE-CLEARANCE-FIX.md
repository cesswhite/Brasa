# Ascua: bordes y separación de peleadores

Se corrigieron los dos defectos señalados en las capturas del usuario. La aprobación visual anterior no los detectó; se conserva su evidencia histórica y se añade esta revisión.

| Antes | Después |
| --- | --- |
| Línea blanca en las variantes dañadas de Ascua | Restos de fondo eliminados en los cuatro bancos de daño, 56 poses |
| Separación basada sólo en centros | Cada silueta respeta una línea de contacto común, incluida su rotación y la pose caída |
| KO largo bajo los pies del ganador | La figura se desplaza hacia su propio lado sin mover el origen de combate |

La limpieza usa la autorización previa del usuario para quitar fondos mediante código. Sólo cambia el contorno de transparencia: el interior, el lienzo, la anatomía, el pivote y la escala se conservan. No se regeneró el personaje. Los PNG anteriores están en `work/edge-spacing-fix/before/`.

La separación se aplica en Main y en las repeticiones online/locales. El encuadre es común para los dos personajes y estable por tamaño de pantalla. El ajuste por pose es una traslación visual, nunca un cambio de tamaño, estadística, alcance del motor o resultado. Sombras y efectos adjuntos siguen la figura corregida. El rectángulo real de las variantes dañadas se lee de sus metadatos.

Se sustituyó la antigua comprobación móvil sobre un rectángulo genérico de 166 unidades por una comprobación sobre la altura pintada canónica. La primera reserva de cámara era excesiva; se redujo tras medir todas las secuencias. Se revisaron las capturas móviles con las figuras y el espacio de separación visibles.

Validación: 23 cuerpos, ambas orientaciones, siete tamaños, ataques y reacciones, victoria y KO; 185472 comprobaciones de límites y estabilidad sin fallos. Regresión: Battle Layout 2139/0, Replay 821/0, continuidad visual 2215/0, animación 1288/0, daño/familias 128/0 y audio Replay 44/0. Las capturas son fixtures sin partidas ni cuentas personales.

[Victoria y KO corregidos](../../../work/edge-spacing-fix/native/1360x780-victory-ko.png) · [Ataque corregido](../../../work/edge-spacing-fix/native/1360x780-attack.png) · [Móvil](../../../work/edge-spacing-fix/native/390x844-attack.png) · [Comparación del borde](../../../work/edge-spacing-fix/edge-comparison.png).

Cambios sólo en el cliente y sus assets; no requieren modificaciones de Cloudflare. Las instancias del juego ya abiertas necesitan reiniciarse para cargar las texturas y scripts nuevos.
