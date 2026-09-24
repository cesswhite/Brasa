# Brasa · Revisión de claridad y uso

22 de septiembre de 2026. Cambios aplicados al juego.

La revisión parte de las **37 vistas más recientes** de escritorio y móvil. Añadí cinco estados de detalle para cubrir Color, Efectos, Estilo y las nuevas subsecciones online: **42 estados y 84 capturas nativas finales**. Los cambios se concentran en entender qué hacer, encontrar cada opción y leer solo el detalle necesario.

El menú, la identidad ilustrada, los materiales de bronce/cuero y los controles de volumen ya tenían una base útil. Se conservaron. Las mejoras principales están en la ayuda por temas, la ficha online por secciones, la distribución móvil, las acciones con coste explícito y los resultados de combate.

[Comparador visual por pantalla](ux-review/index.html) · [Muro escritorio](../../../work/ux-review/after/wall-1360x880.png) · [Muro móvil](../../../work/ux-review/after/wall-390x844.png)

## Análisis por pantalla

**Antes** describe el problema o la razón para conservar la vista. **Después** distingue cambios nuevos de funciones que ya existían y fueron verificadas. No se presentan las cinco capturas adicionales como cinco funciones recién creadas.

| Pantalla | Antes / diagnóstico | Después / decisión aplicada |
|---|---|---|
| Menú principal | La acción de Historia ya domina y las opciones secundarias están agrupadas. Añadir más texto volvería a competir con el paisaje. | **Conservado.** Conservo la jerarquía, el fondo del personaje y Empezar / Continuar historia según su progreso. |
| Ajustes | Ritmo ×1 / ×2 no explicaba con claridad qué aceleraba. Los sliders ya tienen pista, relleno y valor legibles. | **Ajustado.** La opción se llama Combate rápido y muestra su multiplicador. Conservo los sliders visibles y simplifico el subtítulo. |
| Cómo jugar | El manual exigía recorrer una pared de texto para encontrar una respuesta. | **Rediseñado.** Cuatro pasos para comenzar, seguidos de temas desplegables. Toda la explicación detallada sigue disponible al abrir cada tema. |
| Crear tu primer compañero | En móvil, la previsualización dejaba poco espacio para elegir y leer las opciones. | **Ajustado.** El editor compartido equilibra la altura de la previsualización y la lista. El botón Crear compañero y el nombre se conservan. |
| Entrenamiento de Liga | Mejorar no indicaba el coste en la propia acción. Las tarjetas y la ayuda contextual ya organizaban bien la información. | **Ajustado.** Cada acción dice Mejorar · 1 punto. Conservo puntos disponibles, valores y ayuda junto a cada atributo. |
| Ficha del compañero | Los atributos eran interactivos, pero no se indicaba que se podían consultar. | **Ajustado.** Una indicación breve invita a tocar un atributo. Se conserva la cuadrícula numérica y Ver crecimiento para consultar el siguiente nivel. |
| Elegir compañero | Usar a… era ambiguo cuando ese compañero ya estaba activo. | **Ajustado.** Para el compañero activo aparece Volver con…; para otro sigue Usar a…. La selección mantiene su progreso y previsualización. |
| Personalizar · Cuerpo | En móvil, la zona superior dejaba pocas opciones visibles y el selector de combinaciones no nombraba claramente su alcance visual. | **Ajustado.** Más altura útil para elegir, previsualización proporcionada y selector Conjunto visual…. Los avisos inferiores pueden ocupar varias líneas. |
| Personalizar · Color y skins | La misma distribución reducía el espacio de las muestras y las condiciones de desbloqueo. | **Ajustado.** El nuevo reparto de espacio también se aplica a Color. Se mantienen las muestras grandes, la sección Skins y la prueba de opciones bloqueadas sin poder equiparlas. |
| Personalizar · Efectos | La explicación bajo las opciones se recortaba en ventanas estrechas. | **Ajustado.** La ayuda se ajusta a varias líneas y hay más espacio para Auras / Estelas. Se conservan sus vistas previas y los requisitos de desbloqueo. |
| Personalizar · Entrada y victoria | En móvil la demostración y las opciones competían por la altura. | **Ajustado.** Redistribuyo ese espacio y conservo Entrada / Victoria, Repetir, reproducción automática y la explicación del momento en que se usa cada animación. |
| Arena · Preparación | Entrar a la arena ya señala la acción principal; Menú y el HUD están separados. | **Conservado.** Conservo esa estructura, la identidad de los luchadores y sus barras de vida. |
| Arena · Combate | El gran botón desactivado Combate automático parecía una acción disponible y distraía de la pelea. | **Ajustado.** Se oculta durante la pelea. Permanecen las acciones utilizables; el botón principal vuelve cuando hay una decisión que tomar. |
| Rendirse | La confirmación podía explicar antes el estado de la pelea y concentrar las consecuencias. | **Ajustado.** Indico que el combate está en pausa y resumo qué sucede al rendirse, manteniendo las dos decisiones y la información de XP. |
| Resultado · Victoria | En móvil el bloque central tapaba parte de los luchadores. | **Ajustado.** Coloco resultado y acción por encima de sus siluetas en móvil; el conjunto conserva el centrado horizontal. En escritorio se mantiene la composición central. |
| Resultado · Derrota | El mismo solapamiento afectaba a la lectura de la derrota y del siguiente paso. | **Ajustado.** La misma regla despeja a los personajes y mantiene el resultado unido a la acción correspondiente. |
| Resumen del combate | Un bloque de texto largo mezclaba resultado, experiencia y estadísticas; mostraba cambios de nivel aunque fueran iguales. | **Rediseñado.** Resultado primero, información de cada luchador en secciones plegables y acceso directo a Ver acciones del combate. Los niveles solo muestran una subida cuando ocurrió. |
| Historial vacío | Un diálogo grande, casi vacío, sugería desplazarse y no ofrecía un siguiente paso directo. | **Ajustado.** Diálogo más compacto con Volver a la arena. Cierra el historial sin iniciar una pelea por sorpresa. |
| Registro vacío | La ausencia de acciones de combate se presentaba en un contenedor innecesariamente alto. | **Ajustado.** Estado vacío compacto, explicación y Volver a la arena. Se elimina la instrucción de desplazarse sin contenido. |
| Historial de Liga | Los diálogos de lectura tenían demasiado ancho en escritorio y una instrucción de desplazamiento incluso cuando no hacía falta. | **Ajustado.** Ancho de lectura limitado a 800 px y sin la indicación universal. Se conservan las entradas y el acceso a repeticiones. |
| Acciones del combate | El espaciado entre líneas hacía el registro más largo de lo necesario. | **Ajustado.** Una línea por acción, separación menor y subtítulo que explica el orden de los turnos. No se eliminan eventos. |
| Repetición local | Recuerdos de la arena era menos identificable que el nombre de la función; el texto inicial hablaba de la implementación. | **Ajustado.** Título Repeticiones y aviso Sin nuevas recompensas. Conservo reproducción, pausa, reinicio y la apariencia guardada del combate. |
| Historia · Ruta | Actual era una etiqueta ambigua para volver al progreso del personaje; el pie móvil usaba La liga como verbo implícito. | **Ajustado.** El acceso se llama Mi ruta y la salida móvil Volver. Conservo el rival, el mapa y la acción Entrar / Repetir según el encuentro. |
| Historia · Mejoras | La comparación del atributo ocupaba demasiado alto y +1 exigía deducir qué se gastaba. | **Ajustado.** Valor actual → siguiente en una línea, explicación Al invertir 1 punto y botón Mejorar · 1 punto. No se dibuja una falsa comparación al llegar al límite. |
| Historia · Redistribuir | La confirmación ya muestra los recursos recuperados y ofrece Cancelar / Redistribuir. | **Conservado.** Conservo la confirmación y sus consecuencias. Se beneficia de la navegación simplificada y de la ayuda de teclado oculta en móvil. |
| Historia · Técnicas | En móvil, Golpes no describía bien una vista que también contiene Talentos. | **Ajustado.** La pestaña se llama Técnicas y conserva sus dos subsecciones, costes y detalles bajo demanda. |
| Historia · Talentos | La captura anterior etiquetada Talentos mostraba el final de Técnicas; no permitía revisar la pantalla real. | **Verificado.** Corrijo la navegación de la captura y verifico Talentos: elecciones disponibles, talentos activos, acción y ayuda. No atribuyo el cambio de contenido a una mejora visual inexistente. |
| Historia · Compañeros | La composición ya prioriza el compañero activo y su ruta; la salida móvil podía nombrarse mejor. | **Ajustado.** Conservo el resumen, el progreso individual y la selección. Unifico la salida como Volver y mantengo la acción de continuar la campaña. |
| Logros · Por conseguir | Una partida de prueba importada podía mostrar 8/8 encuentros sin un cierre de capítulo registrado, lo que parecía contradictorio. | **Ajustado.** Cuando falta ese registro, la tarjeta lo explica. Conservo Por conseguir / Conseguidos / Colección, avance y siguiente objetivo; no invento un logro. |
| Logros · Capítulo completado | La vista ya distingue lo conseguido del siguiente capítulo; la salida usaba la etiqueta ambigua de Historia. | **Ajustado.** Conservo logros, progreso y Comenzar capítulo. Simplifico la navegación de salida y verifico que se diferencia del estado pendiente. |
| Online · Arena | La cabecera ocupaba demasiado espacio y Desafiar no identificaba al rival. La explicación podía confundirse con una invitación en vivo. | **Ajustado.** Cabecera compacta y contextual, Desafiar a… y explicación de combate automático contra el luchador del otro jugador, incluso si no está conectado. |
| Online · Historia | La identidad y la navegación desplazaban demasiado el siguiente encuentro en móvil. | **Ajustado.** La cabecera compartida libera espacio; el título indica Historia online y conserva encuentro, dificultad y acción de entrar. |
| Online · Atributos | La ficha acumulaba atributos, técnicas, talentos y estilo en una sola lista extensa. | **Rediseñado.** Divido la ficha en cuatro secciones. Atributos muestra los puntos disponibles y el coste; las tarjetas agrupan valor, efecto y acción. |
| Online · Técnicas | Las técnicas quedaban enterradas después de los atributos de la ficha. | **Rediseñado.** Se accede directamente desde Técnicas. Conserva fichas, nivel requerido, grado y acción de mejorar en cada tarjeta. |
| Online · Talentos | Había que recorrer toda la ficha para encontrar las decisiones de talento. | **Rediseñado.** Sección Talentos independiente, cantidad de elecciones y estado Elegido visibles. El foco y el desplazamiento vuelven al inicio al cambiar de sección. |
| Online · Estilo de combate | El estilo estaba al final de la ficha y se describía con lenguaje técnico. | **Rediseñado.** Sección propia que explica cómo pelea el luchador cuando recibe desafíos. La elección activa se distingue visualmente. |
| Online · Actividad | La acción de reconocimiento de notificaciones era poco explícita y la cabecera competía con la actividad. | **Ajustado.** Título Actividad online, cabecera compacta y botón Marcar como vistos. Conservo recompensas y eventos existentes. |
| Online · Sin rivales | El estado vacío ya explicaba la ausencia de rivales, pero ocupaba la misma cabecera sobredimensionada. | **Ajustado.** Conservo la explicación y Actualizar rivales dentro de la nueva cabecera compacta. No se fabrican rivales para llenar la pantalla. |
| Online · Crear luchador | La navegación de modos competía con la tarea de creación. | **Ajustado.** Título Crear luchador online y pestañas de modos ocultas mientras se completa el formulario; se conserva el regreso al luchador existente. |
| Online · Repetición y resultado | El texto inicial de repetición describía detalles técnicos y podía no corresponder a la reproducción automática. | **Ajustado.** Mensaje neutral Repetición · Sin nuevas recompensas, válido tanto al pausar como al empezar automáticamente. Conservo los controles y el resultado recibido. |
| Online · Iniciar sesión | Continuar no anticipaba que se abriría el navegador. | **Ajustado.** La acción dice Entrar con el navegador y explica que sirve para entrar y guardar el progreso online. |
| Online · Autorizar dispositivo | Faltaba separar claramente lo que se hace en el navegador de lo que ocurre al regresar al juego. | **Ajustado.** Dos pasos: confirmar el código en el navegador y volver al juego. La sesión se abre al autorizar; sigue disponible reabrir el navegador o cancelar. |

## Criterios aplicados

- Las acciones dicen su resultado: Entrar con el navegador, Mejorar · 1 punto, Mi ruta y Volver con el compañero activo.
- Ayuda y resúmenes usan secciones desplegables. La información detallada se conserva, pero ya no domina la primera lectura.
- La ficha online separa cuatro decisiones; navegar entre ellas no realiza escrituras ni consume recursos.
- En móvil se reserva más altura para opciones. Las explicaciones inferiores envuelven el texto y no usan puntos suspensivos.
- Se conservan el foco visible mediante el material interior y los controles nativos de teclado. No se añaden contornos exteriores.
- Durante el combate desaparece el gran botón sin acción. Al terminar, la decisión vuelve junto al resultado; en móvil queda sobre las siluetas.
- Se usan las imágenes y materiales existentes. No se cambian sprites, tonos, heridas, escalas relativas, balance, guardado ni backend.

## Validación y límites

- **26 suites de aceptación: 28,718 comprobaciones, 0 fallos.** Incluyen navegación, pausa/audio, personalización bloqueada, costes de mejoras, documentos, Historia y UI online. [Resultados](../../../work/ux-review/checks/results.json).
- **153 comprobaciones de captura, 0 fallos; 84 capturas nativas** a 1360×880 y 390×844. Las pruebas de claridad también cubren 844×390. [Manifiesto](../../../work/ux-review/after/screens.json) · [Log nativo](../../../work/ux-review/native-audit.log).
- Las capturas se renderizan en Godot con perfiles desechables y datos de prueba. Online utiliza respuestas en memoria, sin HTTP: esta revisión no prueba el servicio desplegado ni una sesión real.
- Los resultados de combate usan HP inicial sintético para obtener victoria y derrota. La presentación se deja asentar; no se presenta como una partida natural.
- Antes corresponde a `work/performance-ui/screens`; no se reemplazan esas capturas. La vista anterior etiquetada Talentos era incorrecta, y se avisa en el comparador. Los cinco estados añadidos no tienen un Antes equivalente.
- En pruebas exploratorias, el antiguo `test_story_campaign_ui.gd` dio 28 fallos de 566 comprobaciones; la copia de scripts previa a estos cambios produjo exactamente los mismos 28 fallos. `test_story_chapter_integration.gd` agotó el tiempo de ejecución y no se cuenta como aprobado. Son limitaciones pendientes de esas suites antiguas; las suites actuales de Ruta, Mejoras, Técnicas, Logros y panel de Historia sí pasan. [Comparación previa](../../../work/ux-review/baseline-campaign.log) · [Ejecución exploratoria](../../../work/ux-review/checks.log).
- No se ha realizado una prueba con jugadores ni una certificación de accesibilidad. Las capturas permiten comprobar presentación; las pruebas de interacción comprueban el comportamiento descrito.

## Implementación

La refactorización queda en la capa de presentación. `GameReadingSections` es el componente compartido para documentos plegables. `OnlinePanel` divide su renderizado por subsección, reutilizando las acciones existentes. `BattleLayout` reserva el espacio del resultado móvil. Los demás cambios se limitan a contenido, disposición y navegación.

[Abrir Brasa](/Users/cess/Jugar%20Brasa.command) utiliza el proyecto actualizado.
