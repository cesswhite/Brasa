# Edición pública y respaldo privado

Decisión del titular el 24 de septiembre de 2026: publicar código bajo MIT, reservar arte/audio y conservar un respaldo privado con el contenido completo.

- Público: `cesswhite/Brasa`, con historial nuevo que no incluye archivos sonoros ni videos.
- Respaldo privado: `cesswhite/Brasa-private-backup`, con el historial original y el pack de audio.
- El proyecto local original conserva sus archivos. La edición pública se prepara en un checkout independiente.

No publiques el respaldo ni mezcles todas sus referencias con `push --mirror` o `push --all`. Para trasladar una mejora, revisa el diff y aplica solo archivos distribuibles en la edición pública.

Los archivos de procedencia permanecen como documentación. Algunas referencias en informes históricos apuntan a archivos locales no publicados. Una prueba del pack de audio completo no es reproducible con el checkout público; esto debe indicarse, no ocultarse creando muestras falsas.

## Revisión de esta publicación

Se revisan archivos/historial por patrones de credenciales, exclusión de audio/video, avisos de terceros, enlaces de entrada, skills y arranque sin pack sonoro. Estas comprobaciones no equivalen a una auditoría integral de seguridad ni a validar todos los proveedores/planes de generación.

Conserva [LICENSING.md](../LICENSING.md) como definición de alcance. El aviso MIT de Brasa no reemplaza Apache-2.0/MIT de las partes derivadas ni concede derechos sobre los assets.
