# Compañeros · Figura, atributos y progreso

| Antes | Después |
| --- | --- |
| Retratos pequeños y escala fija diferente entre tarjetas. | Tarjetas más altas, retratos ajustados al espacio mediante el componente compartido y una cámara común a toda la colección. Se conserva el volumen relativo de cada cuerpo. |
| Vista principal de 300 px, 260 en teléfono y 144 en pantalla corta. | Reserva de 400 / 320 / 200 px, respectivamente. El encuadre no recorta ni estira al personaje. |
| Marca, subtítulo, consejos de teclado y explicación de persistencia repetidos. | Cabecera “Tus compañeros”, acciones estables y menos texto periférico. |
| Nivel en tarjetas, experiencia sólo en ficha. | Cada tarjeta conserva su nivel y muestra su propia barra de XP; la ficha muestra XP exacta y puntos para entrenar cuando existen. |
| Biografía, especie y fortalezas por delante de las estadísticas. | Nombre, nivel, especialidad y progreso primero; nueve atributos ordenados en una cuadrícula de valores actuales. |
| Ganancias futuras mezcladas con todos los valores. | “Ver crecimiento” expone las ganancias del próximo nivel; se puede volver a ocultar. Al nivel máximo se informa ese estado. |
| Habilidades y descripción siempre desplegadas. | “Habilidades y perfil” permite consultar fortalezas, debilidades, habilidad, Golpe Firma y biografía sin saturar la vista inicial. |
| Personalizar ocupaba una franja amplia. | Acción secundaria compacta al pie, separada de “Usar a…”. Ambas permanecen accesibles durante el desplazamiento. |

## Alcance y datos

La pantalla conserva sus callbacks de selección, creación, nombre, personalización y cierre. Los datos de la Liga se leen del perfil de cada compañero; no se agregan victorias, XP ni campañas. La apariencia y el nombre personalizados permanecen independientes del estilo de combate. Los apartados de crecimiento y perfil conservan el foco de teclado al actualizarse.

La cámara de las tarjetas usa el menor espacio disponible de la cuadrícula. Esto evita que el redondeo de anchos a píxeles dé una escala diferente a los personajes de otra columna. El componente de vista previa mantiene su comportamiento predeterminado en las otras pantallas; sólo la colección fija ese límite común.

## Verificación

- Pase nativo: **406 comprobaciones, 0 fallos**; siete tamaños, 35 capturas, encuadres de los 15 cuerpos base, escala común, XP por tarjeta, nueve atributos, foco de desplegables y perfiles inmutables.
- Selección y responsive: **375 comprobaciones, 0 fallos**. Nombre, primera selección, scroll, acciones y acceso real a Golpe Firma.
- Sistema visual: **365 comprobaciones, 0 fallos**. Apariencia alternativa y paleta conservadas, cierre, navegación y foco contenido.
- Integración de identidad: **86 comprobaciones, 0 fallos**. Perfiles desechables, selección y personalización sin alterar estadísticas.

[Capturas nativas](roster-ui/index.html). Los perfiles de la galería son fixtures en memoria con niveles y XP preparados para comparar el progreso; no representan partidas personales. No hay cambios de reglas, guardados de usuario, backend ni publicación.
