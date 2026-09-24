# Familias y daño visual — entrega

> **Documento histórico.** El daño híbrido descrito aquí fue sustituido por [daño ilustrado completo para los 23 cuerpos](ILLUSTRATED-DAMAGE.md). Se conservan esta evidencia y las reglas de familias; la cobertura exclusiva de Ascua y el shader de desgaste ya no describen el render vigente.

Se completaron las dos primeras implementaciones solicitadas: daño híbrido con Ascua como piloto y tres familias con seis individuos adicionales. Se conservan los sprites canónicos originales, la progresión, el balance y las identidades existentes.

## Familias integradas

| Familia | Nuevos individuos | Descubrimiento y desbloqueo |
| --- | --- | --- |
| Taro / tejones | Roque, adulto experimentado; Sabino, maestro con barba plateada | Historia 21 y 61 |
| Duna / armadillos | Cora, coraza reforzada; Pedernal, veterano con broquel | Historia 22 y 62 |
| Bruma / gatos | Ámbar, atigrado naranja; Nieve, veterana crema y carbón | Historia 23 y 63 |

Cada individuo tiene 40 poses: ocho base, dieciséis de movimiento y dieciséis de reacción. Son 240 poses en 18 bancos. Pedernal conserva su broquel en guardia, golpe, reacción, victoria y KO. El equipo es apariencia: no cambia alcance, daño, defensa ni estadísticas.

Los encuentros posteriores de cada familia usan la experiencia correspondiente. Los jefes conservan sus diseños exclusivos. Las seis apariencias completas comparten catálogo entre Historia, personalización y Arena; se desbloquean al superar su encuentro. Se eligieron conjuntos completos para preservar la pintura y las animaciones: barba, ropa y armadura no son piezas que puedan mezclarse libremente. Las opciones existentes de paleta, aura, estela y celebraciones siguen disponibles.

La identidad de combate continúa separada del aspecto. El servidor comprueba propiedad y compatibilidad; el historial guarda la apariencia completa de cada batalla. Los jugadores que ya habían superado esos hitos reciben los nuevos cosméticos al resolver su siguiente combate autorizado, mediante el mecanismo de logros existente.

## Daño visual

Cuatro estados por personaje: preparado, desgastado, dañado y crítico. Los umbrales configurables iniciales son 72%, 45% y 22% de vida. La transición espera la reacción; los golpes continuos no pueden posponerla indefinidamente. Curarse no limpia la ropa durante la pelea. Pausa congela la presentación, los resultados conservan el desgaste y una nueva batalla lo reinicia.

Los 23 cuerpos visuales tienen perfiles de materiales y regiones de desgaste. Suciedad, abrasión y fatiga se conservan durante movimientos y poderes; no afectan estadísticas, inventario, RNG ni guardado. No se añadió sangre.

Ascua tiene además 56 poses con daño dibujado: reacciones dañadas y cobertura crítica completa de base, movimiento y reacciones. Las roturas no desaparecen durante carga, transformación, victoria ni KO. El resto del elenco usa desgaste de superficie y las poses de fatiga existentes; no se afirma haber generado bibliotecas de ropa rota para todos los personajes.

## Revisión visual

| Antes | Después |
| --- | --- |
| Repetición del individuo original por especie | Tres familias con edad, prendas, marcas y equipo reconocibles |
| Sin desgaste persistente | Cuatro estados conservados hasta terminar el combate |
| Pies cortados por una cuadrícula generada irregular | Separación en espacios transparentes, conservando las figuras completas |
| Fondo cuadriculado pintado | Transparencia real mediante la limpieza autorizada |

Se revisaron las 240 celdas de los individuos, las familias juntas y 23 referencias de cuatro estados dentro de Godot. La normalización usa un escalar por banco, lienzo 512×512, pivote 256/448 y densidad 1.5; nunca ajusta el tamaño por cuadro. Las diferencias entre dibujos no se presentan como igualdad píxel por píxel. Las regiones de superficie de bancos sin anatomía anotada usan una aproximación visual; no alteran anclajes de FX ni geometría.

Siete pases nativos a velocidad normal cubrieron seis individuos y Ascua: 32 poses utilizadas por personaje, 651 capturas y cero fallos. Las celdas restantes se revisaron en las hojas estáticas. No se aplicaron transformaciones no registradas a otras especies.

## Validación y servidor

- 10 861 comprobaciones de Godot en daño, identidad, personalización, campaña, interfaz online, replay y continuidad visual; cero fallos.
- 366 pruebas del servidor; cero fallos. Incluyen desbloqueo, rechazo de cosméticos sin propiedad, estadísticas invariantes, batalla de Arena e historial inmutable.
- Catálogo exportado desde Godot; corpus de paridad de 300 batallas y nueve secuencias RNG actualizado.
- Cloudflare staging actualizado: versión `2761b4cc-373f-4dca-bb84-0074498447d3`. Se verificó salud del servicio y seis apariencias en D1. La actualización remota escribió sólo definiciones y versiones del catálogo, sin cuentas, inventarios ni progresión personal.
- La API de catálogo sigue protegida por autenticación; una petición sin credenciales recibe 401, como corresponde.

[Revisión visual interactiva](../../../work/damage-families/review.html) · [Aceptación y hashes](../../../work/damage-families/acceptance.json) · [Fuentes y prompts de familias](../../../work/damage-families/final-sources.json).

Los originales generados y las fuentes de cada banco están en `work/damage-families/generated/`. La aceptación anterior de 17 cuerpos se conserva sin sobrescribir; esta entrega añade seis perfiles y su aceptación independiente.

## Acceso pendiente también cerrado

La experiencia de acceso se terminó y desplegó: entrada simplificada, passkeys, consentimiento de dispositivo, recuperación guiada y restauración segura mediante Keychain en macOS. Se corrigió la cancelación durante el guardado de sesión para que no vuelva a iniciar sesión después de cancelar. Validación adicional final: API 27/0 y sesión/Keychain 16/0. [Informe de acceso](AUTH-EXPERIENCE.md).
