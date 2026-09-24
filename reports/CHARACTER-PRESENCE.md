# Brasa · Tamaño y presencia de los personajes

22 de septiembre de 2026. Ajuste posterior a la revisión de UI/UX.

Los personajes ganan presencia en las vistas donde se veían pequeños. La escala se adapta al espacio disponible; se conserva una cámara común entre especies para que Mugo siga siendo más voluminoso que Tepa u Ónix. No se modifica ninguna imagen ni su tonalidad.

| Vista | Antes | Después |
|---|---|---|
| Personalizar en móvil | Previsualización de 332 px de alto a 390×844 | 371 px; se elimina el subtítulo redundante para recuperar espacio y se mantienen las opciones y acciones |
| Entrenamiento en móvil | Hasta 155 px para el retrato | Hasta 205 px; crecimiento moderado según la altura disponible |
| Ficha en móvil | Hasta 260 px | Hasta 280 px |
| Rival de Historia | 180 px móvil / 300 px escritorio | 224 px móvil / 350 px escritorio |
| Compañero de Historia | 280 px móvil / 360 px escritorio | 300 px móvil / 390 px escritorio |
| Ficha de selección | 320 px móvil / 400 px escritorio | 340 px móvil / 430 px escritorio |
| Tarjetas de compañeros | Margen horizontal interno de 24 px en el retrato | 12 px, conservando el espacio de seguridad común entre especies |
| Rival online | 188 px móvil / 350 px escritorio | 220 px móvil / 390 px escritorio |
| Combate en escritorio | Escala máxima 1.8 | Máximo 2.05, limitado por ancho y altura; suelo 24 px más abajo para conservar espacio respecto al HUD |
| Combate en móvil vertical | Encuadre limitado por el ancho para dos luchadores | Se mantiene el límite seguro de las animaciones completas: ampliar más recortaría poses. Las previsualizaciones individuales sí aumentan |

Las medidas de la tabla son espacios reservados, no una altura idéntica forzada sobre cada cuerpo. En Personalizar a 390×844, las alturas visibles de reposo medidas son aproximadamente 148 px para Nima, 177 para Mugo, 132 para Tepa y 139 para Ónix. Comparten exactamente la misma escala de cámara. En ventanas muy bajas se conserva el encuadre compacto.

## Comprobación

- 11 suites pasan: encuadre de retratos, componentes, personalización, selección, compañeros de Historia, Ruta, documentos, disposición y UI de batalla, Online y contacto de luchadores.
- El encuadre prueba todos los cuerpos y las acciones Reposo, Golpe, Entrada y Victoria a 390×844, 1360×880 y 1920×1080: **61,240 comprobaciones sin fallos**. Verifica que la cámara no cambia durante la acción y que la silueta queda dentro de su espacio.
- Contacto de combate: **1,933 casos de movimientos emparejados, 40,882 comprobaciones sin fallos** en siete tamaños. Se corrigió el espacio respecto al HUD para las poses grandes de Ascua.
- [Resultados de las 11 suites](../../../work/character-presence/results.json).
- [Muro móvil actualizado](../../../work/character-presence/after/wall-390x844.png) · [Muro escritorio actualizado](../../../work/character-presence/after/wall-1360x880.png).
- Capturas nativas con perfiles desechables y Online simulado. No se usan ni modifican partidas reales.

[Personalizar en móvil](../../../work/character-presence/after/customization-390x844.png) · [Entrenamiento en móvil](../../../work/character-presence/after/training-390x844.png) · [Arena en escritorio](../../../work/character-presence/after/arena-idle-1360x880.png)
