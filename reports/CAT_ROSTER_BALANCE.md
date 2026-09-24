# Ónix y Bruma · datos y balance

Se añaden `onix` (Ónix, índice 13) y `bruma` (Bruma, índice 14) al final del plantel: **15 compañeros jugables**. Ambos son gatos domésticos con atlas propio. Las definiciones, técnicas y talentos de los 13 anteriores conservan exactamente su texto; tampoco cambian los primeros 16 encuentros, los 100 pools de Historia, las fórmulas ni los esquemas de progresión de Liga e Historia. El sidecar de identidad sí migra de v1 a v2 para incorporar los nuevos cuerpos, con [validación separada](CAT_IDENTITY_MIGRATION.md).

## Identidad y valores

Ónix es negro, de ojos amarillos: rápido y evasivo, con poca vida y armadura. Bruma es gris, de ojos verdosos: preciso, sereno y capaz de protegerse y responder. No son recolores de otro compañero.

| Estadística | Ónix inicial | Crecimiento | Bruma inicial | Crecimiento |
|---|---:|---:|---:|---:|
| Vida | 212 | 6.8 | 255 | 8 |
| Ataque | 19 | 0.64 | 20 | 0.62 |
| Defensa | 11 | 0.42 | 23 | 0.75 |
| Velocidad | 12 | 0.14 | 5.8 | 0.09 |
| Precisión | 94% | 0.08 pp | 101% | 0.1 pp |
| Evasión | 20% | 0.07 pp | 10% | 0.05 pp |
| Crítico | 13% | 0.07 pp | 11% | 0.07 pp |
| Daño crítico | 1.5× | 0.0025 | 1.55× | 0.0025 |
| Resistencia | 6% | 0.1 pp | 18% | 0.15 pp |

Crecimiento por nivel hasta el 20; después se aplica el 45% de ese incremento hasta el límite 50. Entrenamiento inicial de Liga (Vida/Fuerza/Agilidad/Velocidad): Ónix 5/6/8/9; Bruma 7/6/5/6. Historia mantiene sus ocho inversiones independientes y los presupuestos existentes.

- **Ónix — Tres pasos de sombra:** Cada tercer intento de ataque hace ×1.22 de daño si conecta.
- **Bruma — Respuesta del silencio:** 20% de responder a un golpe recibido con un contraataque de ×0.42 de daño.

Firmas: **Medianoche amarilla** aplica precisión −16 puntos por 3 acciones; **Quietud de niebla** aplica ataque −20% por 3 acciones. Ambas usan ×1.6, acierto garantizado y las reglas existentes de resistencia. El armado sigue siendo una tirada del **1% por combatiente y combate**, como máximo una ejecución.

## Técnicas y talentos

Cada gato tiene cinco técnicas, desbloqueadas a niveles **1/1/5/12/20**, y seis talentos entre los que se eligen como máximo tres. Mejoras, fichas y redistribución siguen las reglas actuales.

| Compañero | Técnica | Tipo | Nivel | Multiplicador base |
|---|---|---|---:|---:|
| Ónix | Roce de sombra | `quick` | 1 | 0.81× |
| Ónix | Carrera del alero | `dash` | 1 | 0.9× |
| Ónix | Salto del tejadillo | `jump` | 5 | 1.08× |
| Ónix | Parpadeo amarillo | `technique` | 12 | 0.81× |
| Ónix | Caída de azotea | `heavy` | 20 | 1.24× |
| Bruma | Tacto certero | `quick` | 1 | 0.88× |
| Bruma | Escucha paciente | `counter` | 1 | 0× |
| Bruma | Peso de la calma | `heavy` | 5 | 1.25× |
| Bruma | Guardia de ovillo | `guard` | 12 | 0× |
| Bruma | Paso de niebla | `technique` | 20 | 0.87× |

El cero de guardias y respuestas significa que la postura no golpea inmediatamente. Escucha paciente reduce 22% el daño y ofrece 42% de réplica ×0.55 durante una acción; Guardia de ovillo reduce 32% y cura 2.5% de vida. Parpadeo amarillo tiene 55% de aplicar −8 puntos de precisión por dos acciones; Paso de niebla, 50% de aplicar −12% de ataque por dos acciones. Estos estados son resistibles.

| Compañero | Talento | Efecto |
|---|---|---|
| Ónix | Pulso del tejado | Sus ataques rápidos ganan +6% al multiplicador y 2 puntos de prioridad. |
| Ónix | Paso ligero | Sus carreras y saltos ganan 3 puntos de prioridad y recuperan 0.025 s antes. |
| Ónix | Ojos en la noche | Sus ataques ganan 2.5 puntos de precisión. |
| Ónix | Salto silencioso | Sus saltos ganan 3.5 puntos de crítico y 1.5 puntos de evasión aérea. |
| Ónix | Temple de ónix | Reduce un 10% del daño adicional de los críticos recibidos. |
| Ónix | Última sombra | Bajo el 35% de vida gana 2.5 puntos de evasión, dentro del límite. |
| Bruma | Réplica serena | Sus posturas de respuesta ganan 5 puntos de probabilidad de réplica. |
| Bruma | Pata firme | Sus golpes pesados ganan +6% al multiplicador y 2 puntos de precisión. |
| Bruma | Observación verde | Sus ataques ganan 2.5 puntos de precisión. |
| Bruma | Reposo atento | Su guardia cura 1 punto porcentual adicional de vida y recupera 0.025 s antes. |
| Bruma | Temple de niebla | Reduce un 10% del daño adicional de los críticos recibidos. |
| Bruma | Eco apacible | El debilitamiento de su técnica dura una acción adicional, dentro del límite. |

## Verificación

**721 comprobaciones de dominio, 0 fallos.** Se cargaron copias portables de guardados anteriores con los 13 perfiles, se seleccionaron y entrenaron ambos gatos y se recargaron los 15 perfiles. Los anteriores permanecieron iguales; cargar los archivos no reescribió sus bytes. También se verificaron límites, IDs, propiedad de técnicas, copias profundas, uso de los cinco movimientos, determinismo frente a particiones de delta y Firma única.

La simulación final contiene **6,768 combates**, con semillas registradas: 4800 duelos de Liga (20 semillas por enfrentamiento y por lado, contra los 15 compañeros en cuatro niveles) y 1968 combates de campaña.

| Compañero | Liga nivel 1 | Nivel 10 | Nivel 25 | Nivel 50 |
|---|---:|---:|---:|---:|
| Ónix | 50.3% | 51.7% | 48.7% | 44.8% |
| Bruma | 50.7% | 58.5% | 58.7% | 58.7% |

Liga compara perfiles del mismo nivel sin entrenamiento ni talentos. La menor tasa de Ónix en niveles altos mantiene su fragilidad; Bruma favorece los intercambios largos. No se pretende que todos los cruces tengan 50% de victorias.

**16/16 campañas completaron los 100 encuentros**, dos semillas por gato y por prioridad de inversión. Se gastó el presupuesto legal completo, sin redistribución ni resultados forzados. Todas terminaron en nivel de héroe 50, entre 113 y 152 combates.

| Prioridad fija | Ónix: peleas medias | Bruma: peleas medias |
|---|---:|---:|
| balanced | 130.0 | 139.5 |
| aggressive | 123.0 | 121.0 |
| durable | 116.5 | 121.0 |
| tempo | 115.0 | 118.0 |

El mayor atasco fue de 12 intentos en el jefe 80 con Bruma equilibrado; el jefe 100 requirió entre 1 y 9. Es una muestra acotada y no garantiza la misma dificultad para cualquier distribución. Se registró uso natural de **las diez técnicas nuevas**, sin técnicas sin utilizar.

Duración media: 29.75 s; 17 desempates por tiempo. Hubo 118 ejecuciones de Firma (0.87% por plaza de combatiente); esta frecuencia observada no cambia la tirada configurada del 1% y una pelea puede terminar antes de ejecutarla.

Fuentes completas: [datos y semillas](cat_roster_balance.json), [validación y hashes](cat_roster_validation.json), [prueba de dominio](../tests/test_cat_roster.gd), [simulador](../tests/simulate_cat_roster.gd). Los hashes del catálogo, motor y progresión siguen iguales al finalizar la simulación.

Se usaron únicamente fixtures o perfiles en memoria. No se accedió a partidas reales. Arte, integración visual y exportación del catálogo online pertenecen a verificaciones separadas; este informe no afirma que Cloudflare esté publicado.
