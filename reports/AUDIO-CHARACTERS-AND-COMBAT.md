# Audio: personajes y combate — auditoría del código actual

Fecha: 21 de septiembre de 2026. Alcance: lectura del motor, catálogos, presentación y reproducción; sin generación, cambios de runtime, ejecución de perfiles ni pruebas amplias. **Los perfiles son dirección sonora propuesta; las reglas y los puntos de disparo son hechos del código.** Este documento complementa la arquitectura y el inventario general de audio de la tarea principal.

Se contrastó el catálogo exportado con los SHA-256 actuales de sus ocho fuentes: todos coinciden. Contiene **15 compañeros, 75 técnicas jugables, dos cuerpos de jefe con diez técnicas propias y once encuentros de jefe**. Hay cinco técnicas por identidad; desbloqueos jugables en niveles 1, 1, 5, 12 y 20 y seis opciones de talento por compañero. El JSON adjunto conserva las 85 definiciones completas, talentos, parámetros, perfiles y referencias. [scripts/character_catalog.gd:5](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:5) · [scripts/move_catalog.gd:5](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:5)

Datos auditables: [characters-combat.json](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/work/audio/audit/characters-combat.json). Hash del catálogo: `6f8007bd7059b142b166e630455449d180a7ceffb2c0ff2e0307799f1eea86e1`. No se ejecutaron combates nuevos ni se modificaron guardados para este informe.

## Identidad física y poderes

La apariencia puede escoger un cuerpo distinto del arquetipo jugable. La futura selección sonora debe componer **movimiento/material/voz del cuerpo visible** y **técnica/Firma/poder del descriptor de combate**; nunca identificarlo por el nombre personal. Ascua puede llegar como character_id=mugo con story_boss_id/visual propios, y Véspera como sira. Un replay conserva sus identidades y apariencias históricas, no las actuales del inventario. [scripts/fighter_view.gd:144](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:144) · [scripts/battle_identity.gd:6](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/battle_identity.gd:6) · [scripts/story_catalog.gd:220](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/story_catalog.gd:220)

Los primeros nueve registros no incluyen `species`/`biography`; sus especies aquí proceden de la documentación de los sprites. **Duna es un armadillo, no una tortuga**. Los títulos “jade”, “luna” o “bruma” inspiran timbre; no prueban una mecánica de agua, magia o un arma adicional.

## CharacterAudioProfiles propuestos

Cada perfil conserva una base seca y cercana. El peso sonoro se comunica por transitorio, material y movimiento, no por aumentar volumen según nivel/estadísticas. Motivos y vocalizaciones son propuestas por producir, no archivos existentes. No se requiere una canción completa por personaje.

### Nima (`nima`)

**Identidad:** Lince del desierto. **Movimiento:** Apoyos ligeros y secos; carreras cortas, salto y carga felinos. **Ataque/peso:** Roce de pelo y aire corto; tercer intento acentuado solo cuando conecta; Ligero/medio, sin graves de tanque. **Material:** Pelaje y contacto corporal; grano de suelo en capa independiente.

**Energía:** Arena como textura temática; slow real en Firma. **Voz:** Exhalaciones felinas breves, registro medio, sin palabras. **Motivo:** Tres acentos de percusión seca.

**Habilidad real:** Paso de tres (`combo`): Cada tercer ataque hace ×1.3 de daño si conecta. **Firma:** Cometa de arena: Golpe certero ×1.6 y velocidad rival −22% durante 3 turnos.

**Cinco técnicas:** Zarpazo fugaz (`nima_zarpazo`, quick); Paso de arena (`nima_arena`, dash); Salto de duna (`nima_salto`, jump); Acecho felino (`nima_acecho`, counter); Cometa del desierto (`nima_cometa`, charge).

**Firma sonora:** Cometa de arena: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; slow separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:19](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:19) · [scripts/move_catalog.gd:43](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:43) · [assets/sprites/PROMPTS.md:9](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PROMPTS.md:9).

### Luma (`luma`)

**Identidad:** Ajolote. **Movimiento:** Apoyos suaves, desplazamiento fluido y salto contenido. **Ataque/peso:** Palma blanda con cuerpo firme; gesto de enfoque claramente separado del daño; Medio redondo. **Material:** Piel anfibia; evitar chapoteo permanente en suelo seco.

**Energía:** Agua/remanso como color tímbrico; precisión, debilitamiento y curación reales. **Voz:** Respiración suave y esfuerzo corto de registro medio. **Motivo:** Dos notas fluidas y resonancia de madera suave.

**Habilidad real:** Aprender del río (`adapt`): Tras fallar, gana 10 puntos de precisión durante 2 turnos. **Firma:** Marea de luna: Golpe certero ×1.6 y precisión rival −15 puntos durante 3 turnos.

**Cinco técnicas:** Palma del río (`luma_palma`, quick); Ojo del remanso (`luma_enfoque`, technique); Ola contenida (`luma_ola`, heavy); Arco del agua (`luma_arco`, jump); Remanso protector (`luma_remanso`, guard).

**Firma sonora:** Marea de luna: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; accuracy_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:30](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:30) · [scripts/move_catalog.gd:112](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:112) · [assets/sprites/PROMPTS.md:10](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PROMPTS.md:10).

### Mugo (`mugo`)

**Identidad:** Gólem de piedra. **Movimiento:** Apoyo pesado, repliegue lento y arranque de carga con fricción. **Ataque/peso:** Golpe denso de piedra, junta mineral corta, caída de gravilla localizada; Pesado, transitorio ancho y cola controlada. **Material:** Piedra/jade; nada de espada metálica.

**Energía:** Resonancia mineral; no habilidad de fuego ni transformación jugable. **Voz:** Resonancia corporal grave sin diálogo ni rugido continuo. **Motivo:** Pulso lento de piedra y tambor grave.

**Habilidad real:** Corazón de cantera (`fortify`): Reduce un 45% el daño adicional de los críticos recibidos. **Firma:** Abrazo de montaña: Golpe certero ×1.6 y ataque rival −20% durante 3 turnos.

**Cinco técnicas:** Nudillo de jade (`mugo_nudillo`, quick); Muro paciente (`mugo_muro`, guard); Abrir la grieta (`mugo_grieta`, heavy); Paso de montaña (`mugo_montana`, charge); Eco de piedra (`mugo_eco`, counter).

**Firma sonora:** Abrazo de montaña: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; attack_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:41](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:41) · [scripts/move_catalog.gd:189](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:189) · [assets/sprites/PROMPTS.md:11](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PROMPTS.md:11).

### Sira (`sira`)

**Identidad:** Mantis duelista. **Movimiento:** Apoyos secos precisos; dash y salto articulados. **Ataque/peso:** Corte corto de antebrazo natural con chasquido de quitina; Ligero y incisivo; crítico añade filo, no explosión. **Material:** Quitina y hoja natural del brazo, no espada transportada.

**Energía:** Cristal/obsidiana como timbre; penetración crítica real. **Voz:** Esfuerzo mínimo aireado, sin voz robótica. **Motivo:** Notas altas cortas sobre pulso preciso.

**Habilidad real:** Grieta perfecta (`precision`): Sus críticos ignoran el 45% de la defensa rival. **Firma:** Destello de obsidiana: Golpe certero ×1.6 y defensa rival −25% durante 3 turnos.

**Cinco técnicas:** Aguja de jade (`sira_aguja`, quick); Corte rasante (`sira_corte`, dash); Romper el vidrio (`sira_vidrio`, heavy); Media luna (`sira_media_luna`, jump); Réplica del filo (`sira_replica`, counter).

**Firma sonora:** Destello de obsidiana: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; defense_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:52](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:52) · [scripts/move_catalog.gd:260](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:260) · [assets/sprites/PERSONAJES-V3.md:9](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PERSONAJES-V3.md:9).

### Iria (`iria`)

**Identidad:** Rana botánica. **Movimiento:** Apoyos húmedos discretos; salto y postura arraigada. **Ataque/peso:** Puño orgánico y fricción de hoja; aplicación de veneno separada del golpe; Ligero/medio amortiguado. **Material:** Piel/hoja; sin atribuir lluvia a cada ataque.

**Energía:** Veneno y reducción de curación; textura vegetal corta sin burbujeo continuo. **Voz:** Exhalación breve de anfibio, registro medio-bajo. **Motivo:** Semillas/percusiones de madera y dos notas suspendidas.

**Habilidad real:** Jardín secreto (`poison`): 35% al conectar de envenenar: 3 × Ataque / 19 PV durante 3 turnos, hasta 2 cargas. **Firma:** Flor de medianoche: Golpe certero ×1.6 y curación rival −40% durante 4 turnos.

**Cinco técnicas:** Puño de hoja (`iria_hoja`, quick); Espora amarga (`iria_espora`, technique); Salto de bruma (`iria_bruma`, jump); Raíces firmes (`iria_raices`, guard); Savia cortante (`iria_savia`, heavy).

**Firma sonora:** Flor de medianoche: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; healing_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:63](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:63) · [scripts/move_catalog.gd:327](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:327) · [assets/sprites/PERSONAJES-V3.md:10](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PERSONAJES-V3.md:10).

### Duna (`duna`)

**Identidad:** Armadillo guardián. **Movimiento:** Apoyo firme, recogimiento defensivo, rodar/carga y frenada. **Ataque/peso:** Placas con golpe mate y roce corto, escudo con resonancia diferenciada; Pesado/compacto. **Material:** Placas de armadillo; no caparazón de tortuga ni yunque metálico.

**Energía:** Escudo periódico y slow; sin invulnerabilidad. **Voz:** Esfuerzo grave corto y respiración contenida. **Motivo:** Dos pulsos estables de madera/piedra.

**Habilidad real:** Muralla del patio (`shield`): Cada 4 turnos obtiene un escudo de 12 PV que dura hasta 3 turnos. **Firma:** Sello del guardián: Golpe certero ×1.6 y velocidad rival −25% durante 3 turnos.

**Cinco técnicas:** Golpe de placa (`duna_placa`, quick); Cerrar caparazón (`duna_caparazon`, guard); Rodar la duna (`duna_rodar`, charge); Martillo de cantera (`duna_cantera`, heavy); Retorno de arena (`duna_retorno`, counter).

**Firma sonora:** Sello del guardián: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; slow separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:74](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:74) · [scripts/move_catalog.gd:417](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:417) · [assets/sprites/PERSONAJES-V3.md:11](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PERSONAJES-V3.md:11).

### Kiro (`kiro`)

**Identidad:** Jabalí. **Movimiento:** Apoyos potentes; martillo, ariete y caída con peso. **Ataque/peso:** Cuerpo denso y aire áspero de embestida; Pesado y áspero, sin disparos ni explosiones. **Material:** Pelaje/cuerpo y colmillos como identidad, no arma nueva.

**Energía:** Furia según vida perdida; quemadura real solo cuando se aplica. **Voz:** Resoplidos de jabalí, rugido breve reservado para Firma. **Motivo:** Percusión grave que estrecha el pulso al crecer la presión.

**Habilidad real:** Última brasa (`berserk`): Su daño aumenta según la vida perdida, hasta un 40% adicional. **Firma:** Rugido del horno: Golpe certero ×1.6 y quemadura de 4 PV durante 3 turnos.

**Cinco técnicas:** Puño del colmillo (`kiro_colmillo`, quick); Martillo cobrizo (`kiro_martillo`, heavy); Ariete rojo (`kiro_ariete`, charge); Avivar la brasa (`kiro_brasa`, technique); Caída del jabalí (`kiro_caida`, jump).

**Firma sonora:** Rugido del horno: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; burn separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:85](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:85) · [scripts/move_catalog.gd:492](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:492) · [assets/sprites/PERSONAJES-V3.md:12](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PERSONAJES-V3.md:12).

### Neris (`neris`)

**Identidad:** Garza blanca. **Movimiento:** Apoyos finos; carrera y vuelo/salto con roce de pluma. **Ataque/peso:** Golpe fino, aire de ala y entrada suave; Ligero/medio; aterrizaje legible sin peso de gólem. **Material:** Pluma y apoyo fino; agua solo en textura mágica o suelo apropiado.

**Energía:** Remontada/curación y reducción de precisión; agua como motivo, no proyectil. **Voz:** Exhalación aérea muy breve, evitar graznidos frecuentes. **Motivo:** Dos notas de aliento con respuesta ascendente al sanar.

**Habilidad real:** Otra primavera (`comeback`): Una vez por combate, al bajar de 35% de vida cura un 16% de su vida máxima. **Firma:** Eclipse del río: Golpe certero ×1.6 y ataque rival −22% durante 3 turnos.

**Cinco técnicas:** Punta del ala (`neris_ala`, quick); Seguir la corriente (`neris_corriente`, dash); Vuelo sereno (`neris_vuelo`, jump); Velo del lago (`neris_velo`, technique); Refugio de plumas (`neris_refugio`, guard).

**Firma sonora:** Eclipse del río: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; attack_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:96](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:96) · [scripts/move_catalog.gd:563](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:563) · [assets/sprites/PERSONAJES-V3.md:13](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PERSONAJES-V3.md:13).

### Taro (`taro`)

**Identidad:** Tejón. **Movimiento:** Base baja estable, guardia y réplica con pequeño avance. **Ataque/peso:** Puño compacto de cuerpo, roce de pelo y respuesta seca; Medio/pesado compacto. **Material:** Pelaje y suelo; campana breve solo como motivo, no armadura metálica.

**Energía:** Jade/campana como Firma; sangrado real sin gore sonoro. **Voz:** Esfuerzo de registro bajo, muy breve. **Motivo:** Llamada y respuesta en percusión de madera.

**Habilidad real:** Eco de jade (`counter`): 24% de responder a un golpe recibido con un contraataque de ×0.45 de daño. **Firma:** Campana del cañón: Golpe certero ×1.6 y sangrado de 4 PV durante 3 turnos.

**Cinco técnicas:** Puño de tierra (`taro_puno`, quick); Espera del tejón (`taro_espera`, counter); Guardia de jade (`taro_jade`, guard); Golpe de cansancio (`taro_cansancio`, heavy); Cruzar el umbral (`taro_umbral`, charge).

**Firma sonora:** Campana del cañón: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; bleed separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:107](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:107) · [scripts/move_catalog.gd:635](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:635) · [assets/sprites/PERSONAJES-V3.md:14](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/assets/sprites/PERSONAJES-V3.md:14).

### Balam (`balam`)

**Identidad:** Jaguar. **Movimiento:** Acecho silencioso, carga con liberación potente y salto. **Ataque/peso:** Garra/pata y aire contenido, impacto felino denso; Medio/pesado atlético. **Material:** Pelaje/pata, sin espada ni electricidad.

**Energía:** Noche como color tímbrico; precisión y defensa reducida reales. **Voz:** Exhalación/gruñido de jaguar corto, no rugir en cada golpe. **Motivo:** Pulso espaciado con caída grave al liberar carga.

**Habilidad real:** Mirada entre las hojas (`precision`): Sus críticos ignoran el 30% de la defensa rival. **Firma:** Noche moteada: 1% por combate, una sola vez: golpe certero ×1.65 y defensa rival −20% durante 3 acciones del objetivo.

**Cinco técnicas:** Garra contenida (`balam_garra`, quick); Peso del jaguar (`balam_roca`, heavy); Embestida del monte (`balam_emboscada`, charge); Acecho paciente (`balam_acecho`, technique); Caída moteada (`balam_salto`, jump).

**Firma sonora:** Noche moteada: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; defense_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:118](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:118) · [scripts/move_catalog.gd:858](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:858).

### Tepa (`tepa`)

**Identidad:** Teporingo. **Movimiento:** Apoyos muy ligeros, despegue y aterrizaje repetidos, carreras cruzadas. **Ataque/peso:** Roce de pata y aire veloz, sin silbido caricaturesco; Ligero, ataques fuertes conservan tamaño corporal. **Material:** Pelaje corto y suelo granular separado.

**Energía:** Sol/polvo como motivo; slow real sin magia de fuego automática. **Voz:** Esfuerzo pequeño aireado, no voz infantil ni chillido agudo. **Motivo:** Cuatro acentos de madera suave.

**Habilidad real:** Cuatro brincos (`combo`): Cada cuarto intento de ataque hace ×1.3 de daño si conecta. **Firma:** Salto del sol: 1% por combate, una sola vez: golpe certero ×1.55 y velocidad rival −22% durante 3 acciones del objetivo.

**Cinco técnicas:** Patita fugaz (`tepa_patita`, quick); Salto del zacatón (`tepa_zacaton`, jump); Carrera cruzada (`tepa_carrera`, dash); Brinco del volcán (`tepa_volcan`, jump); Polvo del sendero (`tepa_polvo`, technique).

**Firma sonora:** Salto del sol: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; slow separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:178](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:178) · [scripts/move_catalog.gd:934](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:934).

### Xuna (`xuna`)

**Identidad:** Xoloitzcuintle. **Movimiento:** Guardia firme, paso pesado moderado y carga contenida. **Ataque/peso:** Contacto corporal seco y cercano, respiración estable; Medio/compacto resistente. **Material:** Piel y contacto corporal; la raza no implica armadura de piedra.

**Energía:** Brasa persistente aplica burn; Faro reduce curación, no cura propia. **Voz:** Respiración canina serena y esfuerzo corto, sin ladrido repetitivo. **Motivo:** Pulso grave estable con pequeño acento cálido.

**Habilidad real:** Serenidad del camino (`fortify`): Reduce un 30% el daño adicional de los críticos recibidos. **Firma:** Faro del camino: 1% por combate, una sola vez: golpe certero ×1.6 y curación rival −35% durante 4 acciones del objetivo.

**Cinco técnicas:** Colmillo sereno (`xuna_colmillo`, quick); Guardia del umbral (`xuna_umbral`, guard); Brasa persistente (`xuna_brasa`, technique); Paso de piedra (`xuna_piedra`, heavy); Carga de vigilia (`xuna_vigilia`, charge).

**Firma sonora:** Faro del camino: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; healing_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:239](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:239) · [scripts/move_catalog.gd:1498](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:1498).

### Copal (`copal`)

**Identidad:** Cacomixtle. **Movimiento:** Fintas rápidas, dash, salto y espera antes de responder. **Ataque/peso:** Roce de pelo ligero y whoosh lateral corto; Ligero/medio elástico. **Material:** Pelaje y cola; no sonorizar cada oscilación de cola.

**Energía:** Sombra/luna como motivo; reducción de precisión y réplica reales. **Voz:** Exhalación pequeña y seca, no chirrido penetrante. **Motivo:** Dos acentos asimétricos y respuesta corta.

**Habilidad real:** Respuesta entre ramas (`counter`): 20% de responder a un golpe recibido con un contraataque de ×0.4 de daño. **Firma:** Ronda de la luna: 1% por combate, una sola vez: golpe certero ×1.6 y precisión rival −14 puntos durante 3 acciones del objetivo.

**Cinco técnicas:** Finta anillada (`copal_finta`, quick); Paso entre ramas (`copal_rama`, dash); Espera del cacomixtle (`copal_espera`, counter); Sombra inquieta (`copal_distraccion`, technique); Rodeo de la rama (`copal_rodeo`, jump).

**Firma sonora:** Ronda de la luna: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; accuracy_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:299](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:299) · [scripts/move_catalog.gd:1093](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:1093).

### Ónix (`onix`)

**Identidad:** Gato doméstico negro, ojos amarillos. **Movimiento:** Pasos muy ligeros, dash de tejado y salto ágil. **Ataque/peso:** Pata corta, whoosh fino y tercer intento con acento contenido; Ligero/frágil; pesado no debe sonar como Mugo. **Material:** Pelaje/pata; sin cascabel no documentado.

**Energía:** Sombra/medianoche como timbre; precisión rival reducida real. **Voz:** Exhalación felina corta, maullido reservado opcional de resultado. **Motivo:** Tres notas muy cortas con final seco.

**Habilidad real:** Tres pasos de sombra (`combo`): Cada tercer intento de ataque hace ×1.22 de daño si conecta. **Firma:** Medianoche amarilla: 1% por combate, una sola vez: golpe certero ×1.6 y precisión rival −16 puntos durante 3 acciones del objetivo.

**Cinco técnicas:** Roce de sombra (`onix_roce`, quick); Carrera del alero (`onix_alero`, dash); Salto del tejadillo (`onix_tejadillo`, jump); Parpadeo amarillo (`onix_parpadeo`, technique); Caída de azotea (`onix_azotea`, heavy).

**Firma sonora:** Medianoche amarilla: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; accuracy_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:360](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:360) · [scripts/move_catalog.gd:1167](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:1167).

### Bruma (`bruma`)

**Identidad:** Gato doméstico gris, ojos verdosos. **Movimiento:** Apoyo sereno, escucha/guardia y réplica puntual. **Ataque/peso:** Pata firme y breve aire de respuesta; Medio compacto equilibrado. **Material:** Pelaje/pata; sin campanilla ni capa no documentadas.

**Energía:** Niebla como motivo; ataque reducido y pequeña cura de guardia reales. **Voz:** Respiración felina suave; esfuerzo medio corto. **Motivo:** Pregunta-respuesta de dos notas amortiguadas.

**Habilidad real:** Respuesta del silencio (`counter`): 20% de responder a un golpe recibido con un contraataque de ×0.42 de daño. **Firma:** Quietud de niebla: 1% por combate, una sola vez: golpe certero ×1.6 y ataque rival −20% durante 3 acciones del objetivo.

**Cinco técnicas:** Tacto certero (`bruma_tacto`, quick); Escucha paciente (`bruma_escucha`, counter); Peso de la calma (`bruma_peso`, heavy); Guardia de ovillo (`bruma_ovillo`, guard); Paso de niebla (`bruma_niebla`, technique).

**Firma sonora:** Quietud de niebla: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; attack_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/character_catalog.gd:423](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/character_catalog.gd:423) · [scripts/move_catalog.gd:1245](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:1245).

### Ascua (`ascua` · jefe)

**Identidad:** Guardián de armadura volcánica y núcleo encendido. **Movimiento:** Paso pesado mineral, carga con frenada y salto de cráter. **Ataque/peso:** Piedra caliente/cobre mate más chispa localizada, no explosión; Muy pesado pero mezcla controlada. **Material:** Armadura volcánica, juntas minerales y núcleo; capa de brasa solo donde aparece.

**Energía:** Burn en Carga del brasero; dos fases reales; ember_core visual. **Voz:** Resonancia grave de cuerpo y esfuerzo no verbal breve. **Motivo:** Pulso mineral grave con motivo de farol de tres notas.

**Habilidad real:** Núcleo del farol (`phase_shift`): Por encima del 60% de vida: combate normal. Al 60%: ataque +8%. Al 30%: conserva ese ataque y velocidad +15%. Sin curación ni invulnerabilidad. **Firma:** La noche encendida: 1% por combate, una sola vez: golpe certero ×1.7 y ataque rival −18% durante 3 acciones propias del objetivo.

**Cinco técnicas:** Garra de cobre (`ascua_cobre`, quick); Puño de la forja (`ascua_forja`, heavy); Carga del brasero (`ascua_brasero`, charge); Obsidiana cerrada (`ascua_obsidiana`, guard); Golpe del cráter (`ascua_crater`, jump).

**Firma sonora:** La noche encendida: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; attack_down separado si status_applied. **Transformación:** Secuencia mineral/energía .72 s; cama de núcleo hasta fin visual (máximo 8 s), fases y forma separadas.

Fuentes: [scripts/story_catalog.gd:220](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/story_catalog.gd:220) · [scripts/move_catalog.gd:709](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:709).

### Véspera (`vespera` · jefe)

**Identidad:** Polilla lunar. **Movimiento:** Pasos finos, desplazamiento veloz, salto orbital y espera evasiva. **Ataque/peso:** Aire de ala/polvo fino, contacto rápido definido; Ligero/medio; no hacer débil su impacto por tener alas. **Material:** Ala/quitina ligera; no metal pesado ni levitación permanente.

**Energía:** Eclipse reduce precisión; dos fases reales, sin forma transformada registrada. **Voz:** Aliento leve de registro medio, no zumbido permanente de mosquito. **Motivo:** Figura circular musical corta con pulso de viento.

**Habilidad real:** Danza del vendaval (`phase_shift`): Por encima del 60% de vida: combate normal. Al 60%: velocidad +10%. Al 30%: conserva esa velocidad y ataque +8%. Sin curación ni invulnerabilidad. **Firma:** Polvo de eclipse: 1% por combate, una sola vez: golpe certero ×1.65 y precisión rival −12 puntos durante 4 acciones propias; la resistencia puede acortar su duración.

**Cinco técnicas:** Toque de polvo lunar (`vespera_polvo`, quick); Paso del vendaval (`vespera_vendaval`, dash); Órbita lunar (`vespera_orbita`, jump); Velo del eclipse (`vespera_eclipse`, technique); Espera de la luna (`vespera_luna`, counter).

**Firma sonora:** Polvo de eclipse: motivo propio en anticipación de Firma; impacto físico + acento raro al contacto; accuracy_down separado si status_applied. **Transformación:** N/A: no transformación activa registrada. transform_* de Firma no añade nueva forma ni poder.

Fuentes: [scripts/story_catalog.gd:220](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/story_catalog.gd:220) · [scripts/move_catalog.gd:787](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:787).

## Mapa de eventos y sincronización

Los ataques automáticos tienen preparación, desplazamiento y recuperación; el motor decide resultado y el cliente presenta. `move_started.move` contiene la técnica resuelta (incluye mejoras), `impact_delay=windup+travel` y `duration` su duración total. Usar esos valores por evento, no recalcarlos desde el catálogo actual. `attack` moderno lleva move_id; el retraso legado de .21 s de Main solo corresponde a eventos sin ese ID. [scripts/combat_engine.gd:241](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:241) · [scripts/main.gd:1010](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1010)

| Familia | Windup / travel / recovery base, segundos | Contacto y tratamiento |
|---|---|---|

| `charge` | 0.40 / 0.15 / 0.34 | Impacto condicionado al resultado; valores base, la técnica/mejoras pueden cambiarlos |

| `counter` | 0.10 / 0.00 / 0.18 | Postura, no golpe; valores base, la técnica/mejoras pueden cambiarlos |

| `dash` | 0.05 / 0.13 / 0.17 | Impacto condicionado al resultado; valores base, la técnica/mejoras pueden cambiarlos |

| `guard` | 0.12 / 0.00 / 0.22 | Postura, no golpe; valores base, la técnica/mejoras pueden cambiarlos |

| `heavy` | 0.36 / 0.11 / 0.30 | Impacto condicionado al resultado; valores base, la técnica/mejoras pueden cambiarlos |

| `jump` | 0.15 / 0.30 / 0.23 | Impacto condicionado al resultado; valores base, la técnica/mejoras pueden cambiarlos |

| `quick` | 0.07 / 0.08 / 0.13 | Impacto condicionado al resultado; valores base, la técnica/mejoras pueden cambiarlos |

| `technique` | 0.18 / 0.12 / 0.21 | Impacto condicionado al resultado; valores base, la técnica/mejoras pueden cambiarlos |

| Firma | .34 / .16 / .35 | Contacto +.50; una vez si fue armada |

| Réplica automática | .05 / .08 / .15 | Contacto +.13, garantizado y sin crítico |

Fuente: [scripts/move_catalog.gd:20](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_catalog.gd:20) y [scripts/combat_engine.gd:425](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:425). La prioridad y velocidad modifican la cadencia; no convierten una técnica en otra ni justifican alterar tono de voz.

- **`battle.enter`** — `presentation lifecycle / validated snapshot`. Al cargar actores/arena; no esperar primer golpe. Introducción/ambiente y cama musical; UI confirmar separada. **Límite:** No existe evento engine battle_started; arranque local y Replay.restart son puntos de integración. [scripts/main.gd:886](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:886)

- **`move.anticipation`** — `move_started`. event.time; move.windup/travel/recovery resueltos. Cuerpo, preparación y poder si corresponde; Firma identificable antes del contacto. **Límite:** Guardar move por acción/ID. Mismo move_id se repite: no deduplicar por ID solamente. [scripts/combat_engine.gd:272](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:272)

- **`move.foot`** — `presentation marker left_foot_impact/right_foot_impact`. phase.start + phase.duration*at. Apoyo corporal + suelo; elegir variante sin RNG de combate. **Límite:** La misma landing puede tener marcador de pie/debris: una entrada física, capas limitadas. [scripts/move_visual_profile.gd:14](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:14)

- **`move.charge`** — `marker charge_start / attached_fx_start`. Inicio windup; attached_fx al 25% del windup. Preparación corta, posible cama de energía; salir en travel/terminal/cancelación. **Límite:** Heavy también usa charge_start por presentación; no implica nueva mecánica de carga ni control manual. [scripts/move_visual_profile.gd:25](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:25)

- **`move.dash_slide`** — `marker slide_start/dash_start/slide_end`. travel 0; frenada recovery .18. Aire/cuerpo y fricción de suelo, cola corta. **Límite:** Charge/Signature incluyen dash visual; no contarlos como segunda técnica. [scripts/move_visual_profile.gd:31](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:31)

- **`move.jump`** — `marker jump_takeoff/landing`. Takeoff windup .60; landing recovery .40. Despegue, aire corto y aterrizaje por peso/suelo. **Límite:** Impacto de ataque viene antes desde attack; landing no hace daño. No aterrizaje fallido mecánico. [scripts/move_visual_profile.gd:41](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:41)

- **`combat.contact`** — `attack result=hit`. event.time = inicio + impact_delay. Whoosh de salida + golpe físico/material del objetivo; voz selectiva. **Límite:** No usar un retraso fijo .21 s en ataques modernos ni volver a reproducir anticipación. [scripts/combat_engine.gd:401](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:401)

- **`combat.miss`** — `attack result=miss`. event.time. Whoosh sin golpe ni voz de daño. **Límite:** No confundir fallo de precisión con esquiva; hoy Main usa el mismo tono. [scripts/combat_rules.gd:33](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_rules.gd:33)

- **`combat.dodge`** — `attack result=dodge`. event.time. Evasión corporal y whoosh que pasa; sin golpe. **Límite:** Probabilidad real ya resuelta; no otro roll de evasión en audio. [scripts/combat_rules.gd:33](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_rules.gd:33)

- **`combat.critical`** — `attack result=critical`. Contacto, junto al hit-stop visual. Impacto base + acento crítico corto con prioridad. **Límite:** No duplica el impacto base ni inventa crítico en Firma/counter. La cola de audio sigue durante hit-stop. [scripts/fighter_animation_set.gd:105](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_animation_set.gd:105)

- **`combat.guard_enter`** — `defensive_stance`. Resolución del move guard/counter (windup, travel=0). Postura/apoyo protector discreto. **Límite:** No golpe ofensivo. Guard/counter aún puede fallar como respuesta posterior; no parry garantizado. [scripts/combat_engine.gd:328](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:328)

- **`combat.guard_contact`** — `attack con postura defensiva vigente del objetivo`. Mismo contacto; relacionar defensive_stance/stance_expired por lado. Capa mate amortiguada sobre impacto; mantener daño audible. **Límite:** No result=block ni evento de bloqueo perfecto. attack.absorbed solo mide escudo, NO reducción de guardia. [scripts/combat_engine.gd:516](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:516)

- **`combat.shield`** — `shield / status_applied(effect=shield) / attack.absorbed>0`. Entrada al otorgar; absorción al contacto. Una entrada de escudo y respuesta corta proporcional, sin falso dolor al daño cero. **Límite:** Grant emite ability+status_applied+shield: agrupar. No shield_break explícito; no inferir rotura sin evidencia. [scripts/combat_engine.gd:479](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:479)

- **`combat.counter`** — `move_started counter=true → attack counter=true,result=hit`. Reacción programada .05 windup + .08 travel = .13 s. Preparación de réplica y contacto preciso; acento de respuesta. **Límite:** No result=counter. Counter de postura sin daño es preparación; réplica posterior garantizada sin crítico ni cadena de réplicas. [scripts/combat_engine.gd:425](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:425)

- **`combat.ability`** — `ability (combo/adapt/fortify/precision/poison/shield/comeback/counter/stance/phase_shift/stun)`. Según evento, a veces antes de attack o de heal/status. Acento de identidad agrupado con acción material. **Límite:** Berserk usa modificador continuo/texto de ataque, no nuevo evento por tick. No emitir audio por cada lectura del estado. [scripts/combat_engine.gd:485](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:485)

- **`combat.status_apply`** — `status_applied`. Solo aplicación confirmada. Entrada corta de veneno, brasa, debilitamiento o buff. **Límite:** No sonar porque una técnica pueda aplicarlo. source puede diferir de side/target. [scripts/combat_engine.gd:446](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:446)

- **`combat.status_resist`** — `status_resisted / status_applied.turns_resisted`. Una tirada base impedida por resistencia / duración reducida. Respuesta tenue y distinguible, sin gran bloqueo. **Límite:** Ausencia de estado no prueba resistencia: puede fallar la tirada base. [scripts/combat_engine.gd:455](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:455)

- **`combat.status_tick`** — `status_tick poison/burn/bleed`. Inicio de acción propia afectada; no bucle de pared. Pulso breve de estado, daño/vocal selectivos; KO si target_hp<=0. **Límite:** DoT atraviesa escudo/guardia; no ataque ni puñetazo fantasma. ticks simultáneos posibles. [scripts/combat_engine.gd:500](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:500)

- **`combat.heal`** — `heal amount>0`. Evento confirmado. Ascenso breve orgánico/limpio, sin golpe. **Límite:** No anunciar curación positiva si amount=0; evitar duplicar ability comeback y heal. [scripts/combat_engine.gd:490](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:490)

- **`combat.status_end`** — `status_expired / stance_expired`. Evento confirmado. Normalmente silencio; salida suave solo si había cama persistente. **Límite:** No golpe ni reward; limpiar loops del estado correspondiente. [scripts/combat_engine.gd:122](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:122)

- **`reaction.body`** — `FighterAnimationSet.reaction_for + FighterView.play_reaction`. Contacto inmediato; animación puede diferirse al terminar ataque saliente. Voz corta al daño; caída/fricción al marcador de reacción real. **Límite:** KO/miss/dodge tienen prioridad. Falta un canal de marcadores de reacción para caída/getup: no seguir sólo time de attack. [scripts/fighter_view.gd:629](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:629)

- **`reaction.knockdown_ko`** — `Reacción visual knockdown/ko; target_hp<=0 / finished`. Knockdown .92 s; KO .66 s; grounded es último tramo. Golpe final/caída/apoyo; cierre de KO distinto a hit ordinario. **Límite:** No nuevo estado de stun: derribo de Firma es presentación. No body-ground marker público todavía. [scripts/fighter_animation_set.gd:41](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_animation_set.gd:41)

- **`fighter.low_hp`** — `Snapshot/event HP ratio + FighterView health state`. Cruce del umbral, no cada frame. Respiración opcional muy espaciada; sin depender de audio para informar. **Límite:** Pose low_health <.28; no evento semántico low_health. Habilidades Neris .35, fases .60/.30 son otros umbrales. [scripts/fighter_view.gd:609](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:609)

- **`boss.phase`** — `ability ability_id=phase_shift,phase_index`. 0 al inicio; 1/2 tras cruzar .60/.30 vivo. Cambio musical y resonancia de poder al índice nuevo. **Límite:** Si un golpe salta ambos umbrales solo llega fase final alcanzada; no reproducir fase omitida. [scripts/combat_engine.gd:575](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:575)

- **`fighter.form`** — `play_transformation ember_core aceptada, Ascua visible`. Entrada visual diferida si atacaba; clip .72, lifetime8. Preparación→núcleo→pico→estable; salida al terminar forma/cambiar escena. **Límite:** Solo Ascua. No cambiar stats. Firma y phase events pueden solicitarla mientras ya activa: no reiniciar bucle/intro. [scripts/fighter_view.gd:678](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:678)

- **`combat.signature`** — `move_started.signature / signature / attack.signature`. Anticipación al move_started, acento al contacto +.50. Motivo raro del personaje; quién dispara debe tener prioridad. **Límite:** signature y attack son dos registros del mismo golpe: un paquete sonoro, no dos Firman completas. 1%/combatiente; puede morir antes. [scripts/combat_engine.gd:257](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:257)

- **`combat.finished`** — `finished reason normal/timeout/surrender`. Terminal autoritativo; resultado local llega tras .30 s de presentación salvo rendición. Cierre win/lose desde perspectiva del espectador; detener cargas/voz/loops de combate. **Límite:** Surrender y timeout pueden tener HP>0: no inventar impacto mortal. Premio guardado no se repite al oír replay. [scripts/main.gd:1161](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1161)

## Qué existe y qué falta para sincronizarlo bien

**Marcadores de movimiento disponibles:** apoyos izquierdo/derecho, despegue, aterrizaje, comienzo/final de deslizamiento, paso atrás, carga, FX adherido, dash, continuación del golpe y fin de recuperación. Son metadatos puros calculados sobre las fases. `sound_event` existe en MoveVisualProfile, pero no hay consumidor de audio. CombatFX conserva cursor, edad y deduplicación propios; **no conectar audio a `_draw`, al número de partículas ni a su historial de depuración**: reduced_motion omite esos FX y sus marcadores. El audio debe compartir las definiciones y mantener su propio ciclo de vida. [scripts/move_visual_profile.gd:7](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:7) · [scripts/move_visual_profile.gd:78](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:78) · [scripts/combat_fx.gd:227](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_fx.gd:227)

**Reacciones:** light .28 s, body .36, heavy .48, critical .55, knockback .60, knockdown .92, getup .48, KO .66 y victory .62. Head/low/airborne/guard/status/stagger también son variantes de presentación configurables, no zonas de daño ni nuevas reglas. Un golpe durante un ataque saliente conserva su cronología y difiere la pose de reacción; KO la interrumpe. Falta exponer marcadores de caída→suelo→levantarse desde la reacción realmente mostrada: calcularlos solamente desde `attack.time` sonaría antes de la caída diferida. [scripts/fighter_animation_set.gd:29](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_animation_set.gd:29) · [scripts/fighter_view.gd:629](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:629)

**Guardia, escudo y contraataque:** la guardia reduce daño directo; un escudo absorbe PV y lo declara en `absorbed`. Ni uno garantiza inmunidad, ni existe `result=block`, parry, bloqueo perfecto o ventana de input de defensa. El counter de la lista de técnicas prepara una postura sin daño; la réplica automática posterior emite su propia preparación y contacto. Los derribos de Firma son animación, no aturdimiento mecánico; `stun` sí es soportado por el motor pero ninguna técnica/Firma base del catálogo auditado lo aplica. [scripts/combat_engine.gd:511](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:511) · [scripts/combat_engine.gd:434](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:434) · [scripts/combat_engine.gd:244](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:244)

**Estados/partículas:** distinguir heal, poison, burn, bleed, shield y debuffs, sin sonorizar cada mota. DoT ocurre al inicio de acciones y atraviesa guardia/escudo; puede terminar una batalla. El polvo de impacto/stone_debris se emite hoy al golpe, no a un marcador de cuerpo tocando suelo; no usarlo como prueba de aterrizaje de una caída. No hay colisión física ni tabla de superficies del motor: el material de suelo es contexto de presentación por arena. [scripts/combat_engine.gd:500](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:500) · [scripts/combat_fx.gd:203](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_fx.gd:203) · [scripts/combat_fx.gd:274](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_fx.gd:274)

## Firma, transformación y jefes

**Firma:** Bernoulli de 1% por combatiente al iniciar; turno elegido entre 2–5, consumo máximo una vez. Puede no ejecutarse si cae antes. Acierto garantizado, sin crítico adicional, multiplicador permitido 1.4–1.8 y estado real; resistencia puede acortar duración. Anticipación desde `move_started.signature`; contacto desde `signature` + `attack.signature` agrupados. La opción interna force_signature sirve solo para fixtures, nunca cambia la probabilidad publicada. [scripts/balance.gd:19](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/balance.gd:19) · [scripts/combat_engine.gd:61](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:61) · [scripts/combat_rules.gd:25](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_rules.gd:25)

**Única forma activa:** Ascua `ember_core`, entrada .72 s y vida visual máxima 8 s; `visual_only=true`, sin modificadores ni técnicas nuevas. Main/Replay la solicitan en fase>0 o Firma; si el actor está atacando, la entrada se difiere al idle. Su temporizador de vida corre desde la solicitud. Una petición repetida mientras está activa devuelve true, pero no reinicia forma: el audio no debe repetir la subida completa. Hacen falta notificaciones/estado de entrada efectiva, estable y salida para evitar fuga de loop o desajuste con una entrada diferida. No reescribir el reloj ni el motor. [scripts/fighter_animation_set.gd:47](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_animation_set.gd:47) · [scripts/fighter_view.gd:678](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:678) · [scripts/fighter_view.gd:413](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/fighter_view.gd:413)

**Secuencia propuesta de Ascua:** junta mineral/cuerpo → pulso cálido → resonancia creciente contenida → pico seco de núcleo → cama de brasas corta y estable → apagado suave. Un ataque durante esa forma conserva su base y puede añadir una capa leve del núcleo. Ninguna capa debe anunciar daño extra por la forma visual. Para los otros 16 cuerpos, las poses transform_start/peak/transformed_idle dentro de Firma son su gesto premium; no justifican un loop de transformación ni un nuevo estado de poder.

**Fases verdaderas:** Ascua: Brasa serena (>60%); Horno vivo (≤60%, ataque +8%); Última ascua (≤30%, conserva +8% y velocidad +15%). Véspera: Brisa lunar; Alas del vendaval (≤60%, velocidad +10%); Ojo de la tormenta (≤30%, conserva velocidad y ataque +8%). Ninguno se cura o se vuelve invulnerable. Fase 0 se anuncia al inicio; solo el índice nuevo alcanzado se emite y no se anuncia una fase tras HP≤0. Véspera tiene fases de juego, **ninguna forma visual registrada**. El audio de transición sí corresponde; una transformación corporal completa no. [scripts/story_catalog.gd:237](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/story_catalog.gd:237) · [scripts/combat_engine.gd:575](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/combat_engine.gd:575)

| Encuentro global | Identidad / título | Poder auditado | Fondo |
|---|---|---|---|

| 8 | Ascua | Núcleo del farol (`phase_shift`) | arena-faroles-v2.png |

| 16 | Véspera | Danza del vendaval (`phase_shift`) | arena-tormenta-v3.png |

| 20 | Taro · Juramento de jade | Eco de jade (`counter`) | arena-faroles-v2.png |

| 30 | Iria · Jardín de ecos | Jardín secreto (`poison`) | arena-faroles-v2.png |

| 40 | Luma · Las nueve sendas | Aprender del río (`adapt`) | arena-tormenta-v3.png |

| 50 | Ascua · Corazón del solsticio | Núcleo del farol (`phase_shift`) | arena-faroles-v2.png |

| 60 | Duna · Fortaleza del regreso | Muralla del patio (`shield`) | arena-tormenta-v3.png |

| 70 | Kiro · Rugido del relámpago | Última brasa (`berserk`) | arena-tormenta-v3.png |

| 80 | Neris · Círculo de los maestros | Otra primavera (`comeback`) | arena-faroles-v2.png |

| 90 | Sira · Filo de las estrellas | Grieta perfecta (`precision`) | arena-tormenta-v3.png |

| 100 | Véspera · El último eclipse | Danza del vendaval (`phase_shift`) | arena-tormenta-v3.png |

Los jefes 20/30/40/60/70/80/90 reutilizan su identidad jugable con perfil declarado y técnicas completas; no inventarles fases. Los hitos 50/100 reutilizan Ascua/Véspera con estadísticas mayores y técnicas mejoradas; ameritan intro/cierre musical de hito y una variación del motivo, no once bibliotecas ajenas. [scripts/story_catalog.gd:220](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/story_catalog.gd:220) · [scripts/campaign_config.gd:48](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/campaign_config.gd:48)

## Live, local, online y replay

**Local Liga/Historia:** Main avanza motor con delta y despacha eventos; un modal de combate pausa motor, actores y FX. Ritmo ×2 usa Engine.time_scale=2. Los golpes usan edad `combat.elapsed-event.time`. El audio necesita reloj de sesión y debe descartar transitorios ya vencidos en catch-up. Hit-stop congela solo presentación; deja sonar el tail. Normalizar pitch de música/voz por separado del intervalo entre acciones. [scripts/main.gd:936](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:936) · [scripts/main.gd:1218](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1218)

**Online asíncrono:** el servidor simula todo ante intención de desafiar; guarda eventos ordenados con `event_seq`, snapshot, engine/catalog version y resultado. OnlinePanel abre **el mismo BattleReplayPanel**, no una pelea nueva en Main. Un registro puede verse como defensor: victoria/derrota deben usar viewing_side, no asumir player. Ni oír ni repetir entrega XP. [backend/src/game/battles.js:62](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/backend/src/game/battles.js:62) · [backend/src/game/battles.js:68](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/backend/src/game/battles.js:68) · [scripts/ui/online_panel.gd:840](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/online_panel.gd:840)

**Replay:** tiempo y cursor ordenado; pausa, reinicio, cambio de registro y cierre deben parar/limpiar su audio. La clave propuesta es battle_id + generación de reproducción + event_seq (online) o índice del array (local) + side + marker. `time` solo no es único: DoT/counter/Signature pueden compartir tiempo. Nunca escribir audio IDs en el registro ni regenerar el combate. Los snapshots inválidos/legacy sin eventos no obtienen audio inventado. [scripts/ui/battle_replay_panel.gd:208](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/battle_replay_panel.gd:208) · [scripts/ui/battle_replay_panel.gd:178](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/battle_replay_panel.gd:178) · [scripts/battle_identity.gd:23](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/battle_identity.gd:23)

## Hallazgos de audio existente relevantes al combate

- **REPLACE** — Main synthesizes 9 mono tones: hit,critical,dodge,upgrade,start,win,lose,ability,signature; 5 AudioStreamPlayers at -10dB. [scripts/main.gd:1763](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1763)

- **REWORK** — Signature contact currently calls the same .75s tone in both signature and attack handlers, normally overlapping; ability+heal/shield can similarly stack. [scripts/main.gd:1077](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1077) · [scripts/main.gd:1010](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1010) · [scripts/main.gd:1045](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/main.gd:1045)

- **MISSING** — ReplayPanel does not play audio. Online battle display is this same ReplayPanel after server simulation; no direct online Main combat audio path. [scripts/ui/battle_replay_panel.gd:224](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/battle_replay_panel.gd:224) · [scripts/ui/online_panel.gd:840](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/ui/online_panel.gd:840)

- **KEEP** — Immutable recorded descriptors/events and shared pure move markers are suitable semantic inputs; sound_event metadata exists but is not consumed. [scripts/battle_identity.gd:23](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/battle_identity.gd:23) · [scripts/move_visual_profile.gd:52](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/outputs/Brasa/scripts/move_visual_profile.gd:52)

Al reemplazar los tonos, agrupar Firma + impacto, habilidad + escudo y habilidad + cura en paquetes controlados; no encadenar un archivo largo por cada evento. Mantener separación whoosh/resultado: Main hoy reproduce dodge también en miss. Los efectos no deben depender exclusivamente de reduced_motion ni del volumen de música. El inventario de buses/UI/configuración completo pertenece al documento de arquitectura de la tarea principal.

## Prueba vertical recomendada: Ascua + Patio de Faroles

**Una identidad específica: Ascua, jefe no seleccionable. Una arena: Patio de Faroles**, `last_lantern`, encuentro 8, fondo `res://assets/arena-faroles-v2.png`. Único cuerpo con transformación activa registrada; cinco técnicas completas incluyen quick/heavy/charge/jump/guard, burn, fases, Firma y carga con dash/slide. Identidad mineral y núcleo comparten vocabulario con el entorno de faroles. No introducir a Mugo como “transformable” para cumplir artificialmente el ejemplo. Si el objetivo se restringe a un seleccionable, la transformación real queda fuera: ninguno de los 15 la tiene.

Cinco técnicas de la prueba: Garra de cobre (quick), Puño de la forja (heavy), Carga del brasero (charge + posible burn), Obsidiana cerrada (guardia) y Golpe del cráter (jump). El rival recibe el paquete compartido de contacto/reacción; no exige producir una segunda identidad sonora.

**Cobertura:** confirmación/entrada; ambiente y música de patio; cuerpo/pies; quick/heavy/charge; desplazamiento dash y slide dentro de carga; salto y aterrizaje; contacto/fallo/esquiva/crítico; guardia; daño/derribo/KO; dos fases; forma visual; Firma; victoria/derrota. **N/A de Ascua:** técnica dash independiente, contraataque, parry/bloqueo perfecto, curación, escudo de PV y ataques transformados nuevos. Tampoco hay un derribo que impida acciones mecánicamente. No generar assets para fingirlos.

**Arena propuesta, pendiente del mapa global:** piedra exterior con polvo fino y brasa lejana de faroles; aire nocturno contenido; reflexión corta abierta. Inferencia artística del escenario, no atributo físico existente. Música con pulso mineral y motivo cálido común; aumentar una capa por fase, duck breve de Firma/KO y cierre de jefe. No incorporar público, maquinaria ni agua por inercia.

**Validación posterior:** una sesión natural con semilla fija y eventos reales para ritmo general; ramas raras mediante fixtures/replays explícitos del mismo kit. Firma, crítico, esquiva y ambos desenlaces no están garantizados juntos en un combate; usar controles de prueba internos sin tocar 1% normal. Revisar a ×1/×2, pausa, cierre a mitad de carga, catch-up/reinicio, reduced_motion, local y replay online. Escuchar contacto y aterrizaje separados; nunca un golpe en miss, ni golpe mortal inventado al rendirse/timeout. Esta auditoría no ejecutó esas pruebas ni generó audio.

**Criterio de salida antes del resto del plantel:** identificar quick/heavy/Firma y hit/miss sin mirar; guardia distinta de escudo; pies y fricción en su fase; transformación alineada a su entrada real; KO final; pausas sin loops huérfanos; ninguna recompensa nueva por replay. Después extender perfiles sin cambiar reglas ni registros históricos.

## Backlog P0/P1 completo (sin generar)

El JSON incluye **118 briefs y 416 variantes solicitadas**: foley/contactos compartidos, identidad de los 17 cuerpos, Firma de cada uno, preparación fuerte cuando su kit la tiene, estados reales y forma/fases de Ascua/Véspera. Cada entrada fija uso, duración, one-shot/loop, material, entorno, sequedad, intensidad, elemento tonal, variaciones, timing, exclusiones y prompt en inglés. Son pendientes, no entregables ya producidos. [Backlog extraído](/Users/cess/Documents/Codex/2026-09-19/auto-battler-2d/work/audio/audit/characters-combat-backlog.json).

La Audio Bible de la tarea principal concreta el suelo de Faroles como tierra compacta/terracota y la producción inicial de transformación como gesto y cola breves, sin cama permanente. Esas decisiones prevalecen sobre las opciones preliminares de superficie/loop descritas en la auditoría. El diagnóstico de los nueve tonos corresponde al snapshot anterior a la integración de AudioDirector; el código se integra después, en una tarea separada.
