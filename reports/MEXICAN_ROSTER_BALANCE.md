# Balance de Balam, Tepa, Xuna y Copal

La ampliación añade cuatro identidades al final del catálogo: **Balam (jaguar), Tepa (teporingo), Xuna (xoloitzcuintle) y Copal (cacomixtle)**. Xoloitzcuintle identifica una raza mexicana de perro. Los índices 0–8, las definiciones originales, los primeros 16 encuentros y todos los pools de campaña conservan su contenido previo.

**Resultado final: 48/48 campañas completas y 14,082 combates simulados**, sin modificar los guardados reales. La prueba de dominio añade **816 comprobaciones, 0 fallos**. Los datos de entrada quedan registrados con SHA-256 en [mexican_roster_balance.json](mexican_roster_balance.json).

## Método

- Liga: 8,320 duelos a niveles de héroe 1, 10, 25 y 50, contra las 13 identidades, sin entrenamiento ni talentos. Cada pareja usa 20 semillas y se prueba en ambos lados. La identidad enfrentada a sí misma también forma parte de la muestra.
- Historia: cuatro personajes × cuatro prioridades de inversión × tres semillas = 48 recorridos naturales de 100 encuentros. Se usa el adaptador real de progresión, incluidos XP por derrotas, límites, hitos, cinco técnicas, mejoras y selección de tres talentos entre seis.
- Las prioridades se mantienen durante todo el recorrido; se gastan los puntos legales disponibles y no se usa redistribución, recompensas ficticias, Firma forzada, repetición con XP ni selección manual del movimiento. Se limita cada encuentro a 24 intentos y cada campaña a 500 combates.
- `tests/simulate_mexican_roster.gd` contiene las semillas, prioridades y comandos reproducibles. El guardado está desactivado en su adaptador en memoria. La prueba de persistencia usa directorios de prueba independientes; el baseline portable está en `tests/fixtures/roster-before-mexican.json`.

## Liga a igual nivel

Porcentaje de victorias sobre todos los rivales; cada celda contiene 520 duelos. Las especialidades y los emparejamientos permanecen distintos: no se exige 50% frente a cada rival.

| Personaje | Nivel 1 | Nivel 10 | Nivel 25 | Nivel 50 | Total |
|---|---:|---:|---:|---:|---:|
| Balam | 60.4% | 54.6% | 57.5% | 57.1% | 57.4% |
| Tepa | 41.2% | 50.6% | 48.7% | 50.2% | 47.6% |
| Xuna | 55.6% | 40.0% | 49.8% | 44.2% | 47.4% |
| Copal | 50.0% | 46.5% | 53.8% | 61.2% | 52.9% |

El primer ensayo encontró a Balam demasiado fuerte en todos los niveles, a Copal especialmente fuerte al inicio y a Xuna débil antes de disponer de su repertorio completo. Se ajustaron únicamente sus bases y crecimientos. Tepa conserva sus valores iniciales. La segunda pasada fijó los datos antes de la muestra final; no cambian constantes del motor, antiguos personajes ni enemigos de Historia.

## Campañas naturales

Cada celda de personaje y prioridad contiene tres recorridos. “Derrotas” es la media de intentos perdidos; las victorias de una campaña completa son siempre 100.

| Personaje | Prioridad | Completas | Combates medios | Rango de combates | Derrotas medias |
|---|---|---:|---:|---:|---:|
| Balam | Equilibrio | 3/3 | 118.7 | 117–120 | 18.7 |
| Balam | Ataque | 3/3 | 112.0 | 111–113 | 12.0 |
| Balam | Aguante | 3/3 | 108.7 | 105–111 | 8.7 |
| Balam | Movilidad | 3/3 | 112.7 | 111–116 | 12.7 |
| Tepa | Equilibrio | 3/3 | 128.7 | 125–134 | 28.7 |
| Tepa | Ataque | 3/3 | 122.7 | 120–127 | 22.7 |
| Tepa | Aguante | 3/3 | 119.3 | 114–124 | 19.3 |
| Tepa | Movilidad | 3/3 | 113.0 | 110–116 | 13.0 |
| Xuna | Equilibrio | 3/3 | 134.3 | 126–144 | 34.3 |
| Xuna | Ataque | 3/3 | 118.7 | 117–120 | 18.7 |
| Xuna | Aguante | 3/3 | 116.3 | 115–118 | 16.3 |
| Xuna | Movilidad | 3/3 | 121.7 | 116–125 | 21.7 |
| Copal | Equilibrio | 3/3 | 126.3 | 124–128 | 26.3 |
| Copal | Ataque | 3/3 | 128.0 | 122–138 | 28.0 |
| Copal | Aguante | 3/3 | 116.3 | 112–125 | 16.3 |
| Copal | Movilidad | 3/3 | 123.3 | 117–127 | 23.3 |

Las 48 campañas sumaron **5,762 combates y 962 derrotas**: media 120.04, rango 105–144. El mayor atasco de una misma etapa fue de **24 intentos**, con Copal, prioridad ataque, repetición 3, encuentro 100. Ningún caso necesitó cambiar de personaje o redistribuir la inversión.

Las prioridades son secuencias repetidas, no multiplicadores de atributos:

- Equilibrio: vida, ataque, defensa, velocidad, precisión, evasión, crítico y resistencia.
- Ataque: ataque, ataque, vida, velocidad, crítico, precisión, defensa y vida.
- Aguante: vida, defensa, vida, ataque, velocidad, evasión y precisión.
- Movilidad: velocidad, precisión, evasión, ataque, vida, crítico y defensa.

Los talentos y el orden de mejora de técnicas también varían por prioridad. El JSON conserva cada asignación final, sus tres talentos y los niveles de las técnicas; no se comparan builds con puntos ficticios o presupuestos diferentes.

## Jefes y escalones de dificultad

La tasa corresponde al primer intento de cada jefe; el nivel del héroe se mide tras resolver ese encuentro.

| Encuentro | Victoria al primer intento | Nivel del héroe (mín.–máx.) | Intentos medios |
|---|---:|---:|---:|
| 8 | 52.1% | 11–12 | 2.04 |
| 16 | 66.7% | 20–23 | 1.44 |
| 20 | 64.6% | 24–26 | 1.60 |
| 30 | 54.2% | 30–32 | 2.65 |
| 40 | 83.3% | 36–38 | 1.19 |
| 50 | 54.2% | 42–43 | 2.17 |
| 60 | 100.0% | 47–48 | 1.00 |
| 70 | 89.6% | 50–50 | 1.10 |
| 80 | 43.8% | 50–50 | 2.19 |
| 90 | 58.3% | 50–50 | 1.77 |
| 100 | 39.6% | 50–50 | 3.35 |

Encuentros con menor tasa al primer intento (incluyen élites y rivales comunes):

| Encuentro | Primer intento | Combates / victorias |
|---|---:|---:|
| 4 | 35.4% | 102 / 48 |
| 100 | 39.6% | 161 / 48 |
| 11 | 41.7% | 104 / 48 |
| 3 | 43.8% | 102 / 48 |
| 80 | 43.8% | 105 / 48 |
| 9 | 50.0% | 79 / 48 |
| 8 | 52.1% | 98 / 48 |
| 30 | 54.2% | 127 / 48 |

## Técnicas, habilidades y Firmas

| Personaje | Habilidad | Firma (1% por combate, una vez) |
|---|---|---|
| Balam | Mirada entre las hojas: Sus críticos ignoran el 30% de la defensa rival. | Noche moteada: golpe certero ×1.65 y defensa rival −20% durante 3 acciones del objetivo. |
| Tepa | Cuatro brincos: Cada cuarto intento de ataque hace ×1.3 de daño si conecta. | Salto del sol: golpe certero ×1.55 y velocidad rival −22% durante 3 acciones del objetivo. |
| Xuna | Serenidad del camino: Reduce un 30% el daño adicional de los críticos recibidos. | Faro del camino: golpe certero ×1.6 y curación rival −35% durante 4 acciones del objetivo. |
| Copal | Respuesta entre ramas: 20% de responder a un golpe recibido con un contraataque de ×0.4 de daño. | Ronda de la luna: golpe certero ×1.6 y precisión rival −14 puntos durante 3 acciones del objetivo. |

La IA utilizó **20/20 técnicas nuevas**. El conteo siguiente excluye las Firmas y las réplicas automáticas; una guardia cuenta como técnica elegida, aunque ceda un ataque.

| Personaje | Usos por técnica |
|---|---|
| Balam | Garra contenida: 34,165; Peso del jaguar: 15,434; Embestida del monte: 7,753; Acecho paciente: 5,246; Caída moteada: 6,503 |
| Tepa | Patita fugaz: 40,981; Salto del zacatón: 17,013; Carrera cruzada: 16,889; Brinco del volcán: 7,589; Polvo del sendero: 6,189 |
| Xuna | Colmillo sereno: 55,586; Guardia del umbral: 6,865; Brasa persistente: 11,971; Paso de piedra: 13,497; Carga de vigilia: 7,962 |
| Copal | Finta anillada: 44,327; Paso entre ramas: 23,419; Espera del cacomixtle: 5,611; Sombra inquieta: 8,203; Rodeo de la rama: 8,473 |

La duración media del conjunto fue **30.22 s**; 67 combates (0.48%) llegaron al desempate normal de 60 s. Se ejecutaron 297 Firmas: **1.055% por participante**. Esta cifra mide Firmas ejecutadas, no sólo armadas: un combate puede terminar antes del turno de activación. La probabilidad de armado permanece exactamente en la tirada Bernoulli central del 1%.

## Compatibilidad y límites de la muestra

- Los nuevos IDs ocupan los índices 9–12: `balam`, `tepa`, `xuna`, `copal`. No se desplaza ningún índice anterior.
- Las definiciones de personajes antiguos se conservan byte por byte. Los datos de movimientos anteriores se conservan, con la coma de cierre necesaria para añadir entradas; los valores resueltos de todas sus técnicas y talentos se comparan exactamente contra el baseline.
- Los cuatro usan categorías de habilidades existentes con nombres y parámetros propios; no se añade otro dispatcher ni se cambia la tirada de Firma. Sus cinco técnicas siguen los desbloqueos 1, 1, 5, 12 y 20, los dos niveles de mejora y los límites habituales.
- La prueba recarga perfiles antiguos de Liga v2 e Historia v3, comprueba que la lectura no escribe los archivos, añade los cuatro perfiles y vuelve al progreso original y su Legado sin alterarlos. Los puntos, talentos, técnicas, selección y redistribución de los cuatro se comprueban en archivos de prueba.
- Las pruebas ejecutan combates con pasos temporales distintos y comparan resúmenes completos; verifican el uso de las veinte técnicas y una Firma real de cada identidad, siempre certera, con su debuff declarado y sin acciones posteriores al final.
- La Liga mide bases sin entrenamiento. Las campañas cubren cuatro prioridades fijas y tres semillas por combinación; no representan todas las asignaciones, parejas ni secuencias de azar. Los resultados muestran viabilidad y diferencias útiles, no invulnerabilidad ni ausencia de picos de dificultad.

## Reproducción

```sh
./Godot --headless --path outputs/Brasa --script tests/test_mexican_roster.gd
./Godot --headless --path outputs/Brasa --script tests/simulate_mexican_roster.gd
```

Sustituir `./Godot` por el ejecutable instalado. Validado con Godot 4.7.2. El informe JSON registra las definiciones finales completas, resultados por pareja, recorrido de cada campaña, builds, usos de técnicas y hashes de las seis fuentes de dominio que alimentaron la simulación.
