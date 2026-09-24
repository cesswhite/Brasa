# Brasa · Liga de los Faroles

Juego de combate automático 2D en Godot: elige un compañero, desarrolla sus habilidades y avanza por Historia o Arena. Combina personajes ilustrados, progresión individual y un backend opcional de Cloudflare Workers + D1.

**Código propio: MIT. Arte e identidad: derechos reservados.** La edición pública no incluye audio ni videos. Lee [el alcance de las licencias](LICENSING.md) antes de reutilizar contenido.

## Ejecutar el juego

Versión de referencia comprobada: **Godot 4.7.2 estándar**. La entrega local se desarrolló en macOS; la UI tiene layouts de escritorio y móvil, pero este repositorio no es una app móvil exportada.

```sh
git clone https://github.com/cesswhite/Brasa.git
cd Brasa
# Si Godot está en PATH:
godot --editor --path .
```

También puedes importar `project.godot` desde Godot y ejecutar con **F5**. En macOS, `Jugar.command` espera Godot en `/Applications/Godot.app`.

En una partida nueva crea un compañero y entra en Historia. Los combates se resuelven automáticamente; entre encuentros puedes entrenar y personalizarlo. Las partidas se guardan fuera del repositorio, en el directorio de usuario `BrasaLiga`.

### Audio en el repositorio público

Los WAV/MP3 y videos se omiten por condiciones de distribución del proveedor. El código de audio y su catálogo permanecen; el juego omite sonidos ausentes. Las pruebas que exigen el pack completo requieren assets autorizados. Consulta [desarrollo](docs/DEVELOPMENT.md) y [procedencia](THIRD_PARTY_NOTICES.md). No se modificaron ni borraron los audios del proyecto privado del titular.

## Desarrollar

- [Guía de desarrollo y pruebas](docs/DEVELOPMENT.md).
- [Mapa del proyecto para LLMs](docs/LLM-GUIDE.md).
- [Instrucciones para agentes](AGENTS.md) y [skills locales](SKILLS.md).
- [Contribuciones](CONTRIBUTING.md) y [seguridad](SECURITY.md).
- [Backend: instalación local y API](backend/README.md).
- [Guía histórica del juego](docs/GAME-GUIDE.md).

`reports/` conserva evidencia histórica, no garantiza que la revisión actual haya pasado todas esas pruebas. Algunos informes enlazan archivos `work/` de la estación original, no incluidos aquí.

## Online y Cloudflare

El juego implementa Arena asíncrona e Historia online con sesiones, passkeys y resultados autoritativos. El repositorio conserva referencias al staging del titular; su disponibilidad y acceso no están garantizados. Clonar este código no concede permiso para administrar, probar carga, migrar o desplegar sobre esa cuenta.

Para desarrollo usa el backend **local**. Para tu propio despliegue crea recursos y secretos propios, adapta origen/RP/bindings y consulta [DEPLOYMENT.md](backend/docs/DEPLOYMENT.md). Los IDs de recursos no son credenciales. No pongas secretos en `data/online_config.json` ni en el ejecutable.

## Licencia

[MIT para código propio y documentación técnica](LICENSE), con las [excepciones de arte/audio y terceros](LICENSING.md). Consulta [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). El carácter público de este repositorio no concede una licencia abierta para los personajes, imágenes o audio de Brasa.
