# Desarrollo reproducible

## Requisitos y rutas

Godot 4.7.2 estándar es la versión de referencia del proyecto. Usa `godot` en PATH o sustituye el comando por tu binario. Godot importa assets y reconstruye `.godot/`; ese directorio no se versiona.

```sh
godot --headless --editor --path . --import
# Prueba breve de lógica, con guardado de prueba:
godot --headless --path . --script res://tests/test_core.gd
# Comprobación específica de la edición pública sin audio:
godot --headless --path . --script res://tests/test_public_source.gd
# Regresiones del sistema visual (estructura; no valida píxeles en headless):
godot --headless --path . --script res://tests/test_game_visual_system.gd
```

Inspecciona cada test antes de lanzarlo y utiliza sus perfiles de prueba. No borres ni migres el perfil real del usuario. Para revisar capturas necesitas renderer visible; compara escritorio (1360×880), móvil vertical (390×844) y una ventana corta/horizontal. No atribuyas resultados visuales a una ejecución headless.

## Backend local

Node 22+ y npm. Desde `backend/`:

```sh
npm ci
npm run build
npm run db:migrate
npm run db:seed
npm run account:create
npm run dev
```

Los comandos locales usan D1 en `.local/state`. El generador escribe la credencial de prueba en un archivo privado sin imprimirla. Consulta [backend/README.md](../backend/README.md) para usarla. `npm run build` sincroniza catálogos: revisa el diff resultante.

```sh
# Desde backend/: prueba local; no despliega.
npm test
npm run catalog:check
```

Los tests remotos y las herramientas administrativas requieren un entorno autorizado específico. No los ejecutes por una petición de refactor o al instalar dependencias. `wrangler.staging.jsonc` describe el staging del titular; para un fork crea configuración independiente.

## Audio y variantes del checkout

La versión pública conserva `data/audio_events.json`, el director de audio y el manifiesto, pero no los archivos sonoros ni videos. La búsqueda de streams existentes evita cargar rutas ausentes; la ejecución pública debe seguir funcionando en silencio. Las suites que verifican muestras físicas, metadatos o reproducción completa necesitan el pack autorizado y deben identificarse como no aplicables al checkout público; no inventes WAV vacíos para hacerlas pasar.

## Keychain de macOS

El helper nativo tiene código fuente en `native/macos/session_store.swift`. Para recompilarlo en macOS usa `native/macos/build.sh` con las herramientas de desarrollo instaladas. La persistencia mediante Keychain es específica de macOS; no afirmes soporte equivalente en otros sistemas sin implementarlo y probarlo.

## Qué comprobar según el cambio

| Cambio | Evidencia relevante |
| --- | --- |
| Reglas/progresión | Tests de lógica y migración; paridad del backend si afecta al online |
| UI/layout | Tests de componentes + capturas reales en varios tamaños |
| Sprites/heridas | Anclajes, volumen, tono, transparencia y daño visible entre poses |
| Auth/API | Tests de identidad, propietario, revocación y validación |
| Escritura de resultados | Idempotencia, revisión, concurrencia y rollback |
| Documentación/licencia | Enlaces, alcance de permisos, referencias de skills y procedencia |

No ejecutes toda la batería antigua a ciegas: selecciona pruebas acordes al cambio y reporta fallos previos sin ocultarlos ni modificar el balance para acomodar un test.
