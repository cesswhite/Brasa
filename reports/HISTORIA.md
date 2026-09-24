# Modo Historia · Validación

Este informe corresponde a la primera entrega del capítulo 1. La corrección del segundo rival a nivel 2 y la ampliación a dos capítulos se documentan en [CAPITULO-2.md](CAPITULO-2.md).
Implementado y verificado con Godot 4.7.2 en macOS, el 20 de septiembre de 2026.

## Experiencia

El botón **Historia**, junto a Menú, abre la elección de campaña. Los nueve compañeros empiezan con su perfil normal en nivel 1, sin importar su progreso en la liga. Cada personaje conserva su propia ruta, nivel, XP, puntos, mejoras, derrotas, reintentos e insignia.

La ruta tiene ocho encuentros y dos élites. Cada oponente usa estadísticas explícitas del catálogo de Historia: velocidad y combos, armadura y escudos, críticos, veneno y resistencia, evasión y recuperación, contraataques y un jefe final. La vista previa muestra personaje, nivel, perfil, fortaleza, debilidad y habilidad. El perfil rival permanece idéntico entre reintentos.

Hay ocho opciones de mejora, con vista del valor actual y del siguiente: Vida, Ataque, Defensa, Velocidad, Precisión, Evasión, Crítico y Resistencia. Las decisiones conservan las diferencias entre arquetipos. La campaña entrega tres puntos iniciales, tres por nivel y dos por élite derrotada. El crecimiento natural sigue siendo propio de cada personaje.

Las derrotas conceden XP y no retroceden la ruta. Las pistas se basan en la proporción de ataques fallados, acciones realizadas, daño recibido, daño de estados y resistencia observada. La resistencia se identifica con la misma tirada del combate: una aplicación que falló su probabilidad base no se presenta falsamente como resistida.

**Ascua**, custodio del último farol, utiliza el motor común. Su habilidad anuncia las fases: al 60% de vida gana 8% de ataque; al 30% conserva ese ataque y gana 15% de velocidad. No recupera vida ni obtiene invulnerabilidad. Su firma mantiene la tirada del 1% por combate y el máximo de una activación; hace ×1.7 de daño y reduce el ataque un 18% durante tres acciones propias del objetivo.

Al terminar, el resultado conserva la arena. **Legado** muestra nivel final, estadísticas, diferencias desde nivel uno, batallas, derrotas, reintentos y asignaciones, y entrega la insignia **Guardián de los Faroles**. Una nueva campaña con otro personaje mantiene el recorrido completado.

## Persistencia y reglas

Historia usa `brasa_save.json.story.json`; la liga conserva `brasa_save.json`. El nuevo adaptador valida versión, modo, presupuesto de puntos, ruta secuencial e identidad de cada resultado antes de escribir. Usa archivo temporal, reemplazo atómico y respaldo. Las recompensas son idempotentes incluso después de recargar. Un archivo inválido se protege o recupera desde una copia conservando el original.

Los rivales se definen en `story_catalog.gd`; no hay un multiplicador oculto de dificultad por estar en Historia. La única habilidad nueva del motor es una habilidad declarada por fases, utilizada por Ascua. El combate normal conserva sus reglas y su secuencia de tiradas.

## Verificación

| Suite | Comprobaciones | Fallos |
| --- | ---: | ---: |
| Núcleo y compatibilidad | 185 | 0 |
| Combate de la liga | 396 | 0 |
| Progresión y guardado de la liga | 563 | 0 |
| Sprites | 258 | 0 |
| Plantel de la liga | 283 | 0 |
| Distribución de batalla | 2139 | 0 |
| Catálogo, combate, fases y pistas de Historia | 518 | 0 |
| Campañas completas con el adaptador real | 1575 | 0 |
| Progresión y persistencia de Historia | 217 | 0 |
| Panel de Historia | 362 | 0 |
| Integración de Historia con la interfaz real | 85 | 0 |
| **Total** | **6581** | **0** |

También pasó el recorrido integrado de la liga (`--smoke-test`). Se verificaron la ficha de solo lectura con combate pausado, la cuenta atrás de reintento tras rendición, el aviso ante un fallo real de guardado y la conservación del panel cuando una acción todavía no está disponible.

Las pruebas de Historia cubren selección, puntos, ocho atributos, límites, XP por victoria/derrota/rendición, avance secuencial, premios élite, jefe, final, campañas independientes, recarga, corrupción, protección de guardados, recompensa única, pistas y fases. El recorrido de integración usa la interfaz y el motor reales con archivos de prueba; verifica que la partida de la liga permanece idéntica byte por byte.

Se revisaron siete tamaños de viewport: 1360×880, 1224×792, 1920×1080, 768×1024, 390×844, 430×932 y 844×390. Los controles del panel miden al menos 48 px; el cuerpo tiene desplazamiento. En móvil, la vista previa precede al mapa. Las pruebas comprueban texto visible, no solo rectángulos, y usan también el tema real de la aplicación. La revisión móvil se realizó en viewports nativos de Godot, no en dispositivos físicos.

La [auditoría de balance](STORY_BALANCE.md) y los [datos de simulación](story_balance.json) contienen 20 197 combates: 432 de 432 campañas llegaron al final, con una media de 13.42 peleas y 5.42 derrotas. El jefe cayó al primer intento en el 46.8%. Aguante resultó la prioridad más eficiente de las cuatro probadas; las demás también completaron todas las campañas. La muestra no agota todas las distribuciones posibles.

Se reabrió el juego real y se dejó a pantalla completa en la elección de personaje de Historia. El guardado de la liga quedó idéntico byte por byte: Mugo, nivel 3, 65 XP, 2 puntos, 5 victorias y 0 derrotas. No se inició una campaña ni se eligió un personaje por el jugador.

Capturas de perfiles de prueba (los escenarios forzados para revisar resultados no se utilizan como evidencia de balance):

- [Ruta y vista previa](historia-ruta.png)
- [Vista móvil](historia-movil.png)
- [Mejoras](historia-mejoras.png)
- [Legado](historia-legado.png)
