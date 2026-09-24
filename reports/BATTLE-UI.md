# Combate · HUD pintado y resultado central

| Antes | Después |
| --- | --- |
| Marca BRASA / ARENA y acceso Historia encima del combate. | Se eliminan ambos elementos. Menú queda centrado arriba; Historia sigue accesible desde el menú. |
| Texto “Ataques y habilidades automáticos” en el margen inferior. | Se retira del combate. |
| Nombres, niveles y vida sin material propio. | Dos marcos pintados de cuero oscuro y bronce, tipografía del sistema, vida jade/coral y cifras compactas. Barras de igual ancho, reflejadas por lado. |
| Victoria separada de la acción, al pie. | Resultado y botón forman un grupo centrado vertical y horizontalmente. La escena terminada permanece detrás con un velo, deliberadamente subordinada al resultado. |
| Copia y acciones dispersas. | Victoria/derrota/rendición, XP y continuación agrupadas. Menú, Entrenar, Compañeros y Resumen mantienen sus acciones. Los avisos de espera/guardado aparecen junto al botón cuando hacen falta. |
| Online presentado como selector de repeticiones. | En el combate online se ocultan título y selector; Menú centrado, HUD compartido y resultado según el lado del usuario. El botón vuelve a Arena online. Las repeticiones históricas conservan su distribución. |

## Continuación real

- Arena: **Volver a pelear** conserva el controlador existente.
- Historia: **Siguiente encuentro**, **Preparar reintento** o **Ver legado**, según el estado de la campaña.
- Online: **Volver a Arena online** cierra la presentación y vuelve a la sección existente. XP y rating se suministran desde la respuesta del servidor, sin recalcularlos.

El componente `game_combatant_hud.gd` reutiliza las superficies originales y los carriles de vida de `GameVisualSystem`. No fueron necesarias nuevas imágenes: el atlas pintado existente aporta los bordes y textura; nombres y cifras siguen siendo texto nativo. No hay cambios en reglas de combate, estadísticas, posiciones físicas, inventario o recompensas.

## Validación

- Layout: **2 107 comprobaciones**, siete tamaños y tres estados, sin fallos.
- Visibilidad de resultados: **1 782 comprobaciones**, victoria y derrota en siete tamaños; recompensa única, persistencia y callbacks conservados. El criterio anterior de mantener toda la silueta fuera del resultado se sustituye expresamente por la superposición central solicitada.
- Repeticiones: **821 comprobaciones**, sin fallos; geometría histórica, salud/eventos registrados y navegación conservados.
- Componente de resultado: **160 comprobaciones**, sin fallos.
- Menú: **327 comprobaciones**, sin fallos.
- Pase nativo específico: **385 comprobaciones, 0 fallos; 49 capturas** en siete tamaños, Arena, Historia y Online, ambas perspectivas del resultado online, controles y registros inmutables. Resultado en `work/battle-ui/native-final.log`.

[Capturas nativas](battle-ui/index.html). Todas usan perfiles desechables y combates reales del motor con vida inicial reducida del rival para obtener resultados rápidos y reproducibles. Online usa el formato de registro autorizado, reproducido localmente; **no es una partida de red ni una prueba de Cloudflare**. Las capturas de resultado ya muestran el arte herido existente. No se modificaron partidas personales ni se publicó ningún cambio de servidor.
