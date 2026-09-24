# Personajes con sprites propios · Validación

La actualización aporta siete diseños originales y 56 poses: Sira (mantis), Iria (rana botánica), Duna (armadillo), Kiro (jabalí), Neris (garza), Taro (tejón) y Ascua (guardián volcánico). El plantel tiene nueve apariencias distintas y el jefe tiene una exclusiva.

![Diez identidades renderizadas por Godot](personajes-v3.png)

## Integración

`character_catalog.gd` y `story_catalog.gd` declaran el atlas propio mediante `visual.atlas`. `fighter_view.gd` utiliza ese archivo en todas las vistas; conserva orientación, escala común entre poses, animación, destellos y compatibilidad con la API anterior. Las regiones de los siete JSON describen cada silueta completa sin retocar los PNG generados.

La comparación con las copias anteriores confirma que los catálogos no cambiaron fuera de sus campos visuales. No se modificaron estadísticas, habilidades, identificadores, motor, recompensas ni el formato de las partidas.

## Pruebas de esta actualización

Godot 4.7.2: **4555 comprobaciones, cero fallos**.

| Prueba | Comprobaciones |
| --- | ---: |
| `test_distinct_sprites.gd` | 3165 |
| `test_sprites.gd` | 258 |
| `test_story_panel.gd` | 362 |
| `test_core.gd` | 185 |
| `test_roster.gd` | 283 |
| `test_story_integration.gd` | 85 |
| `test_story_progression.gd` | 217 |

El test de sprites distintos comprueba los diez archivos y su contenido único, la carga real del atlas esperado, las 80 poses totales, transparencia, anclaje al suelo, escala, orientación, animación y compatibilidad con atlas ausentes. Las regiones nuevas conservan cada píxel visible (alfa ≥ 31/255) exactamente una vez. Se verifican siete tamaños: 1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 y 844×390.

Se revisaron capturas nativas de las diez identidades, ocho poses por personaje y el ajuste en los siete tamaños. Son 18 capturas en `work/characters/native-qa`, respecto a la raíz del espacio de trabajo. Las colas, alas, puños y poses altas se muestran completos y sin fragmentos de otras celdas.

La aplicación se reinició desde `Jugar.command`. Se verificaron la arena con un rival nuevo, Sira en Legado y los seis diseños nuevos en Compañeros de Historia. Los dos archivos reales de guardado conservaron exactamente sus SHA-256 durante el reinicio y la navegación final. Las pruebas automatizadas utilizaron fixtures independientes.

## Arte y reproducción

[PNG, metadatos, prompts exactos y método de generación](../assets/sprites/PERSONAJES-V3.md).

Desde la carpeta del proyecto:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/test_distinct_sprites.gd
```

Para las capturas se usa el mismo test con un renderizador gráfico y `-- --capture-dir=/ruta/de/salida`. No requiere cargar una partida.
