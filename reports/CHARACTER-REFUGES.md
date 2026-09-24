# Cada quien, su refugio

El menú utiliza 21 ilustraciones originales: los 15 cuerpos jugables y los seis individuos desbloqueables. El cuerpo elegido en Personalizar tiene prioridad sobre el arquetipo de combate. Cada personaje aparece integrado en su ambiente, ocupado en una rutina cotidiana; no hay un luchador animado superpuesto.

[Galería de escenas y capturas nativas](character-refuges/index.html) · [Prompts completos](../../../work/menu-refuge/prompts-v2.json) · [Procedencia, dimensiones y hashes](../../../work/menu-refuge/art-acceptance.json).

## Cambios visuales

| Antes | Después |
| --- | --- |
| Botones casi iguales en una única cuadrícula. | Historia es la acción principal; Arena y Arena online son secundarias; crecimiento y colección forman un segundo grupo; ajustes, ayuda y registro son discretos. Se conservan las doce rutas. |
| Fondo genérico y figura animada encima. | Ilustración completa elegida por `appearance.body_style_id`, incluidos los seis individuos. Sin props decorativos pegados encima. |
| Primera propuesta con montañas, vegetación y encuadres demasiado parecidos. | Hábitats propios: chinampas, cantera, matorral, mercado desértico, cocina, costa, bosque, selva nocturna, patio, zacatonal, copa de árbol, tejados, talleres y cabaña nevada. Solo Nima conserva el cañón original. |
| Gestos y poses repetidos. | Comer, lavar una taza, plantar una flor, podar, recolectar hongos, ordenar mercancía, cocinar, reparar una red, partir bellotas, rastrear, encender un farol, desenterrar raíces, recoger fruta, dormir, tender ropa, reparar una bolsa, leer, modelar barro, pulir un escudo, amasar y coser. |
| Navegación siempre en el mismo lado. | Columna a izquierda o derecha según la composición; distinto punto de recorte por escena. En móvil la ilustración ocupa la zona superior y las opciones siguen debajo con scroll de foco. |
| Foco inicial en cerrar. | Foco inicial en la primera acción disponible. Se mantienen Esc, Tab, controles de 48 px, estados deshabilitados durante combate, pausa y movimiento reducido. |
| Pie genérico. | Título y frase propios del lugar, con velo inferior para conservar contraste en escritorio. |

## Arte y selección

Los PNG finales están en `assets/ui/refuges/` y se registran en `data/ui_visual_manifest.json`. `data/character_refuges.json` define título, frase, foco y lado de menú. `WorldBackdrop` conserva su registro compartido y carga solo el fondo activo; `GameHomePanel` sigue usando tipografía, cuero/bronce, tarjetas, cabecera y foco de Historia. El cambio de composición del menú responde a la solicitud explícita del usuario.

Las imágenes se generaron con la herramienta integrada **image_gen**, usando el sprite canónico como referencia de identidad. No se seleccionó un modelo por nombre. Los PNG finales son copias exactas de los originales generados, sin retoques de píxeles. La primera tanda repetitiva queda archivada fuera del juego en `work/menu-refuge/rejected-v1/`; no se usa como arte final. Son escenas estáticas por cuerpo, no variaciones aleatorias ni una simulación dinámica de tareas.

## Verificación

- 21 fondos: dimensiones verificadas, fuentes originales y hashes registrados.
- `test_character_refuges.gd`: **4581 comprobaciones, 0 fallos**. Selección por apariencia, 21 cuerpos × cuatro tamaños, doce destinos, navegación de teclado, scroll completo, carga del fondo correcto y perfil inmutable. Doce capturas nativas de seis personajes, incluidas composiciones a ambos lados y una variante familiar.
- `test_visual_menu_navigation.gd`: **294 comprobaciones, 0 fallos**. Rutas reales de Main, pausa, disponibilidad, Esc, ciclo de foco y conservación de guardados desechables.
- `test_world_visuals.gd`: **1453 comprobaciones, 0 fallos**. Registro compartido, materiales, decoraciones y contextos existentes.
- Componentes compartidos: **68/0**. Auditoría final de Main con dos capturas nativas adicionales: **15/0**. Total de las cinco suites finales: **6411 comprobaciones, 0 fallos**.

[Capturas nativas](../../../work/menu-refuge/native-final/) · [Log de refugios](../../../work/menu-refuge/refuges-final.log) · [Log de navegación](../../../work/menu-refuge/navigation-final.log) · [Log de entornos](../../../work/menu-refuge/world-final.log).

La evidencia procede de fixtures aisladas. No se modificaron partidas personales, reglas de combate, progreso ni estado del servidor.


## Ajuste posterior: menú directo

A petición del usuario se retiraron la cabecera, nombre/nivel, «El camino continúa» y «El refugio». El botón muestra **Empezar historia** cuando ese personaje no ha avanzado y **Continuar historia** si ya tiene intentos o avance, incluso al inicio de otro capítulo. No consulta el nivel de Arena ni la campaña de otro personaje. Al pulsarlo se abre la historia del personaje seleccionado, conservando las demás campañas; un fallo de guardado restaura la selección anterior.

El contorno blanco del botón principal se sustituyó por una variación del cuero dorado al recibir foco. Las doce rutas, Tab, Esc y los objetivos táctiles se conservan. Las capturas de la galería corresponden a este ajuste; las anteriores siguen en `work/menu-refuge/native-final/` como evidencia histórica.

[Captura actual de Main](../../../work/menu-cleanup/native/menu-1360x880.png) · [Móvil](../../../work/menu-cleanup/native/menu-390x844.png) · [Pruebas de navegación](../../../work/menu-cleanup/navigation.log) · [Pruebas de fondos](../../../work/menu-cleanup/refuges.log).
