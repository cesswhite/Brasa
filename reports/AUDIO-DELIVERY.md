# Brasa · revisión de realismo del audio

21 de septiembre de 2026. Esta revisión sustituye la V1 después del feedback del usuario: los sonidos se percibían como frecuencias y metal arrastrado. El alcance producido sigue siendo **Ascua + Patio de Faroles y los sonidos físicos compartidos**.

## Cambio integrado

- Golpes ligeros/pesados y guardia con dirección de cuerpo, cuero y tela. El crítico deja el bronce y usa un contacto físico breve.
- Movimiento de mangas, pisada y frenado sobre tierra; una sola fricción por desplazamiento. La Firma usa una toma de fuego distinta de las liberaciones ordinarias y acompaña el impacto corporal.
- Ambiente de patio nocturno: viento, hojas, grillos y fuego. Se conserva la pieza musical anterior a menor volumen.
- Todos los efectos seleccionados conservan velocidad y tono originales. Se retira `atempo`; los golpes/movimientos tampoco varían el pitch en reproducción. El importador antiguo ahora dirige al procesador natural de candidatos.
- Se descartan tomas débiles y contactos tardíos. La ganancia de preparación tiene techo de +12 dB y ninguna toma integrada depende de alcanzar ese techo para rescatarla.
- Whooshes −4 dB, pisadas −3 dB, carga/liberación −4 dB, música −5 dB y ambiente +3 dB respecto a V1. Se elimina la repetición de liberación en los ticks de quemadura; aplicación inicial, contacto y KO conservan su feedback.

**51 archivos activos en 22 familias:** 20 de nuevas generaciones, 30 originales anteriores reprocesados a velocidad natural y una pieza musical preservada byte por byte. Se descargaron **40 tomas nuevas en 10 generaciones** usando ElevenLabs en Google Chrome. Saldo observado: 44.692 → 44.175 créditos (517); sin comprar créditos ni compartir en Explore. Las variantes descartadas y todos los originales permanecen fuera de los bancos jugables, con hashes y procedencia.

## Escuchar la revisión

[Combate completo nuevo](audio-combat-demo.mp3) · [Golpes antes](audio-contact-before.mp3) · [Golpes ahora](audio-contact-after.mp3) · [Visor de los 51 archivos y bucles](audio-asset-review.html).

Los reels antes/ahora contienen cuatro golpes ligeros y cuatro pesados, separados por silencio, al nivel de archivo y sin normalización adicional. La nueva demo se codificó directamente desde el Master de Godot durante una pelea completa; no es una secuencia ensamblada de efectos aislados.

**No se declara aprobación por oído.** Esta sesión permite medir y grabar el juego, pero no escuchar su resultado. El feedback del usuario invalida la V1 como referencia sonora; las mediciones de V2 verifican integridad, envolvente, temporización y niveles, no prueban por sí solas naturalidad, ausencia de contenido accidental ni gusto artístico.

## Validación de esta revisión

| Comprobación | Resultado |
| --- | ---: |
| AudioDirector | 352 comprobaciones, 0 fallos |
| Repeticiones / presentación Online | 44 comprobaciones, 0 fallos |
| Dos combates nativos, pausa y movimiento reducido | 23 comprobaciones, 0 fallos |
| Archivos activos medidos | 51/51, 0 errores, 0 avisos del validador |

Importación de Godot limpia. Ambos combates reproducen los **38 contactos corporales**: ninguno se descarta. Entrega del marcador al reproductor: media 3,2/4,0 ms y máximo 8,3 ms; esto no mide latencia acústica del dispositivo. No faltan recursos, no hay duplicados ni eventos rechazados por llegar tarde. Cada corrida registra 179 reproducciones de 190 solicitudes; las supresiones son nueve pisadas por límite de simultaneidad, una pisada por cooldown y una liberación de quemadura por cooldown. El presupuesto evita acumular movimientos; el contacto se conserva.

Los dos resultados y el hash de eventos coinciden entre sí y con V1 (`01537ffe7d3b05658793cff31320342690874ecb7aa20f3a019529be2599ba4d`). No se cambian reglas, probabilidades, progresión, guardados del usuario ni backend. La fixture usa Mugo20/Ascua12 y fuerza una Firma sólo dentro del arnés, sin alterar el juego normal. Incluye cinco técnicas, Firma, fases 0/1/2, quemadura, crítico, fallo, esquiva, KO y derrota real del jugador.

| Captura | Duración WAV | LUFS-I | True peak (dBTP) |
| --- | ---: | ---: | ---: |
| normal_pause | 47.371 s | -26.5 | -6.4 |
| reduced_motion | 46.475 s | -26.5 | -6.9 |

Las mediciones corresponden al Master de Godot, con General 85%, Música 70% y Efectos 85% en la fixture. No se detecta clipping en la mezcla. Algunas fuentes generadas tienen muestras a escala completa, documentadas en su selección; este hecho aislado no aprueba ni invalida el timbre. Los sonidos de fase y los stings retenidos siguen sujetos a revisión auditiva.

## Fuentes, respaldo y reproducción

- [Procedencia activa](../assets/audio/SOURCE-MANIFEST.json), [sesión V2](../../../work/audio/revision-realism/generation-session.json), [selección V2](../../../work/audio/revision-realism/selections-v2.json).
- [Diagnóstico del procesamiento V1](../../../work/audio/audit/forensic-findings.md) y [comparación independiente de golpes](../../../work/audio/audit/impact-v2-independent.md).
- [Validación nativa](../../../work/audio/revision-realism/playtest/final/validation.json), [mezcla y hashes](../../../work/audio/revision-realism/playtest/final/mix-provenance.json), [entrega de eventos](../../../work/audio/revision-realism/playtest/final/delivery-validation.json).
- [Plan de promoción y archivos](../../../work/audio/revision-realism/promotion-plan.json). Respaldo completo: `work/audio/revision-realism/promotion-backups/20260921T171226464319Z-72651ee780f0/`. La entrega V1 se conserva en `revision-realism/before/reports/`.
- [Biblia vigente](AUDIO-BIBLE.md) y [catálogo de reproducción](../data/audio_events.json).

Para actualizar la evidencia: `python3 work/audio/measure_mix.py --playtest-dir work/audio/revision-realism/playtest/final` y `python3 work/audio/validate_assets.py --playtest-dir work/audio/revision-realism/playtest/final`. Para otra captura nativa, usar siempre un directorio de salida nuevo.

El banco propio de poderes/reacciones de los demás personajes, Tormenta y los motivos de otras secciones siguen en el backlog. Esta revisión corrige el paquete existente; no presenta ese backlog como producido.
