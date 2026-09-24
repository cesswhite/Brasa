---
name: brasa-visual
description: "Modificar o revisar pantallas, componentes, sprites, heridas y escala responsive de Brasa conforme a su sistema visual existente."
---

# Mejorar UI y sprites de Brasa

La raíz del repositorio está en `../../..` desde esta carpeta. Lee `AGENTS.md` y `docs/LLM-GUIDE.md`; resuelve las rutas siguientes contra esa raíz.

Lee reports/VISUAL-STYLE-BIBLE.md y reports/VISUAL-SCREEN-AUDIT.md. Reutiliza GameVisualSystem, sus tokens y componentes; no crees un tema paralelo. Conserva navegación, foco de teclado, pausa y movimiento reducido.

Mantén personajes grandes pero moderados en escritorio y móvil, preservando volumen relativo, anclaje y proporción. Las heridas deben ser localizadas y perceptibles, sin cambiar la tonalidad, brillo u opacidad global del cuerpo. Mantén transparencia real; no confundas cuadrícula pintada con alfa.

Para assets nuevos conserva identidad y procedencia. No alteres reglas de combate ni propiedad/desbloqueos por una preview. Comprueba estados bloqueado, seleccionado, hover y focus sin bordes recortados.

Usa pruebas del área y capturas reales en 1360x880 y 390x844, además de ventana corta cuando afecte layout. Headless valida estructura, no apariencia. Consulta LICENSING.md antes de añadir o redistribuir medios.
