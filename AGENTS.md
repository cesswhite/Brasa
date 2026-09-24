# Brasa · instrucciones para agentes

Lee [README.md](README.md), [docs/LLM-GUIDE.md](docs/LLM-GUIDE.md) y el área relevante antes de editar. Skills locales: [SKILLS.md](SKILLS.md).

## Alcance y comprobación

- Godot/GDScript presenta el juego; Workers/D1 calcula y persiste resultados online. Conserva autoridad, autorización por propietario, idempotencia y migraciones.
- Para comandos reproducibles consulta `docs/DEVELOPMENT.md`. Trabaja con perfiles/bases desechables; no modifiques guardados del usuario para validar.
- Los informes son evidencia fechada. Diferencia pruebas locales, capturas, pruebas remotas y despliegue real.
- Una petición de código no autoriza operar la cuenta Cloudflare del titular. Si el usuario ya autorizó una acción concreta, completa su preparación y ejecución sin pedir la misma aprobación otra vez.
- Código propio y documentación técnica: MIT; arte/audio reservados; PCG/Godot conservan sus avisos. Consulta `LICENSING.md` y `THIRD_PARTY_NOTICES.md`.
- La edición pública omite audio y videos intencionalmente. No los recuperes del historial privado ni los subas a Git LFS/releases/CI sin permiso de distribución.
- No publiques secretos, credenciales, perfiles, bases locales, node_modules ni cachés. Usa configuración del entorno destino, no IDs remotos copiados por defecto.

## Personajes y UX

Mantén escala relativa por especie/volumen, anclajes consistentes y transparencia real. Las heridas deben ser visibles y localizadas sin cambiar tono, brillo u opacidad del cuerpo completo. Personajes legibles y de tamaño moderado tanto en móvil como en escritorio. No añadas contornos de foco recortados; conserva una indicación accesible integrada en el botón.

# Brasa visual authority

The approved Story Mode is the visual authority for this game. Read `reports/VISUAL-STYLE-BIBLE.md` and `reports/VISUAL-SCREEN-AUDIT.md` before changing a screen.

- Reuse `scripts/ui/game_visual_system.gd`, `data/game_visual_tokens.json`, the `WorldVisuals` material registry and `WorldBackdrop` layers. Extend their named roles when a feature needs a new state; do not introduce another local Theme, font stack or unrelated button/panel family.
- Use shared components in `scripts/ui/components/` for fighter presentation, section headers, badges and modals. Keep game logic, network actions, identity and progression outside visual components.
- Different locations may supply a background, contextual accent and eligible props. All inherit Story's painted bronze/leather materials, typography, legibility overlays and interaction states.
- Environmental memories must use the manifest's eligibility rules, never random rewards or fabricated ownership. Preserve the complete fighter appearance in previews and records.
- Keep text native and readable, keyboard focus visible, controls accessible in narrow/short windows, and decorative nodes non-interactive. Respect pause and reduced motion. Do not restore circular fire/energy FX.
- Migrate one screen at a time after the shared system exists. Compare native desktop/mobile captures with Story, validate navigation and real interaction states, then update the screenshot wall and screen audit. Clearly distinguish fixtures from live/server data.
- Do not modify gameplay balance, user saves or backend state for a visual change. Validate with disposable test profiles.
