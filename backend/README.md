# Brasa · servicio de juego

Cloudflare Worker + D1 para identidad, autenticación con passkeys, luchadores persistentes, Arena asíncrona, 100 encuentros de Historia, progresión, rating, historial y resultados defensivos.

Godot presenta los eventos guardados por el servidor. El combate conserva el formato automático del juego: eliges luchador, build, estrategia y rival. Arena e Historia online comparten un perfil. Liga e Historia locales siguen disponibles y sus guardados no se importan como progreso confiable.

**Nota para forks:** el siguiente párrafo es evidencia histórica de septiembre de 2026, no una garantía de disponibilidad o permiso para operar el servicio. Usa recursos propios para tu despliegue.

El [staging de Cloudflare](https://brasa-api-staging.acessloop.workers.dev/health) está publicado y pasó la verificación remota de acceso, Arena e Historia. El usuario activó Workers Paid, confirmado como plan actual en Cloudflare. La repetición pasó 32/32 comprobaciones de acceso y 60/60 de juego y revocación, con límite de CPU de 1000 ms por solicitud. Ese límite no es un presupuesto mensual ni un tope de facturación. [Estado, pruebas y mediciones](../reports/CLOUDFLARE-STAGING.md).

## Documentación

- [Auditoría y plan previos](docs/ARCHITECTURE-AUDIT.md).
- [API, persistencia, concurrencia y alcance online](docs/ONLINE.md).
- [Autenticación, sesiones y passkeys](docs/AUTH.md).
- [Motor determinista, corpus y simulaciones](battle-engine/README.md).
- [Despliegue y validación de staging](docs/DEPLOYMENT.md).

## Desarrollo local

Node 22 o posterior. Desde este directorio:

```sh
npm ci
npm run build
npm run db:migrate
npm run db:seed
npm run account:create
npm run dev
```

`wrangler.jsonc` mantiene `AUTH_MODE=local_dev`, loopback `127.0.0.1:8787` y D1 independiente en `.local/state`. No requiere sesión Cloudflare. `account:create` genera una credencial de siete días para desarrollo; escribe el token en un archivo 0600 y almacena sólo su hash en D1. No imprime el token. Para renovar la misma cuenta, usar `npm run account:create -- --account UUID`.

```sh
npm run api -- --credential .local/credentials/ARCHIVO.json --path /v1/fighters
npm run token:revoke -- --credential .local/credentials/ARCHIVO.json
```

Las herramientas `inventory:grant` y credenciales locales nunca actúan sobre la base remota. Los fixtures de tests usan bases temporales y no tocan `.local/state` ni las partidas de Godot.

## Jugar online

1. Abre `Jugar online.command` desde Brasa o **Arena online** en el menú del juego.
2. Pulsa **Iniciar sesión en el navegador** y usa **Crear cuenta con passkey** en la primera visita, o **Entrar con mi passkey** si ya tienes cuenta. Confirma con tu dispositivo.
3. Compara el código con Godot y pulsa **Autorizar este dispositivo**.
4. Vuelve al juego, elige base de combate y nombre, y pulsa **Crear luchador**. Puedes comenzar **Historia** aunque aún no haya rivales públicos.

La passkey personal la crea el usuario en su dispositivo. El token del juego permanece en memoria; cerrar sesión lo revoca. El [acceso web directo](https://brasa-api-staging.acessloop.workers.dev/auth) no conecta Godot sin iniciar y aprobar su código. El [flujo completo](docs/AUTH.md#entrar-desde-godot) explica cada paso.

La URL pública está en `data/online_config.json` del juego. D1, el secreto y los resultados del despliegue se documentan en [DEPLOYMENT.md](docs/DEPLOYMENT.md).

## Validación reproducible

```sh
npm test
npm run catalog:check
node tests/engine-benchmark.mjs
npx wrangler deploy --dry-run --config wrangler.staging.jsonc
```

La suite incluye paridad numérica con Godot, passkeys con firmas criptográficas reales, autorización por cuenta, intención idempotente, revisiones, carreras, rollback, snapshots inmutables y límites de recompensas. Las pruebas remotas son explícitas y separan cuentas de validación del matchmaking ordinario.

El backend y sus dependencias están excluidos de Godot mediante `.gdignore`. `.local`, `.wrangler`, `dist`, `node_modules` y secretos se excluyen mediante `.gitignore`. No colocar secretos en `online_config.json` ni en el ejecutable.
