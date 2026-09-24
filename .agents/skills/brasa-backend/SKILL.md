---
name: brasa-backend
description: "Crear o corregir API, autenticación, persistencia o motor autoritativo online de Brasa en Cloudflare Workers y D1."
---

# Mantener backend de Brasa

La raíz del repositorio está en `../../..` desde esta carpeta. Lee `AGENTS.md` y `docs/LLM-GUIDE.md`; resuelve las rutas siguientes contra esa raíz.

Lee backend/README.md y el contrato pertinente en backend/docs/AUTH.md u ONLINE.md. Conserva sesión validada y propietario en cada operación; usa consultas parametrizadas, revisiones, transacciones y resultados idempotentes. Una migración nueva no debe reescribir la aplicada a otras bases.

Para lógica de combate lee backend/battle-engine/README.md y verifica paridad. Los tokens no van en logs, JSON de presentación ni ejecutable. Passkeys y device authorization dependen de Better Auth y de origen/RP coherentes; no inventes una ceremonia biométrica completada.

Prueba con Miniflare/bases aisladas y scripts locales documentados. backend/wrangler.staging.jsonc y los informes históricos se refieren al entorno del titular; no autorizan operaciones remotas. Si la tarea pide un despliegue propio, configura recursos/secretos propios y verifica los flujos realmente habilitados.

Revisa catálogos generados tras build. Reporta código, pruebas, migraciones y estado local/remoto por separado.
