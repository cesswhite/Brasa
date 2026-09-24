# Entrar al mundo de Brasa

## Auditoría previa a la implementación

La inspección confirmó Better Auth 1.7.5 + @better-auth/passkey 1.7.5, SimpleWebAuthn en navegador y Worker/D1. Godot no implementa WebAuthn nativo: usa autorización de dispositivo y un bearer opaco. No hay contraseñas, correo real ni recuperación administrativa pública. Los secretos permanecían en memoria; cerrar Godot exigía repetir la vinculación. Las fuentes previas están en `work/auth-experience/before`.

| Paso anterior | Información / acción | Necesidad | Decisión |
|---|---|---|---|
| Abrir Online | Título, explicación extensa y botón de navegador | Elegir destino | SIMPLIFY: figura/mundo y Continuar |
| Obtener código | Estado técnico, código, volver a abrir y cancelar | Vincular el juego correcto | KEEP código; MERGE contexto y espera |
| Web inicial | Explicación biométrica, login, registro y advertencia juntos | Elegir entrar o empezar | SIMPLIFY: un estado y una acción primaria |
| Nombre de cuenta | Campo previo a crear credencial | Better Auth requiere una etiqueta, no identidad verificada | REMOVE campo obligatorio; etiqueta inicial Viajero, nombre de luchador en el juego |
| Ceremonia passkey | Prompt confiable del navegador/sistema | Prueba de posesión y verificación de usuario | KEEP; sin imitación biométrica |
| Éxito de acceso | Mensaje antes de autorizar código | No es un destino útil | MERGE con confirmación del juego |
| Confirmar código | Comparar y autorizar / rechazar | Consentimiento de vinculación, protección frente a otra solicitud | KEEP explícito; nunca aprobar al cargar o iniciar sesión |
| Éxito de vinculación | Mensaje y espera del polling | El navegador no puede enfocar Godot de forma garantizada | SIMPLIFY: volver al juego, sin otro Continuar |
| Carga de luchador | Peticiones de identidad, catálogo y luchadores | Servidor autoritativo | AUTOMATE |
| Nuevo luchador | Nombre, base y creación | Decisión de juego real | KEEP; separada de cuenta |
| Cerrar / abrir Godot | Repetir todo porque bearer sólo vive en memoria | Falta almacenamiento seguro | AUTOMATE en macOS con Keychain; memoria en plataformas sin adaptador |
| Segunda credencial | Siempre visible junto al login | Útil, no necesaria al entrar | MOVE a Cuenta / Seguridad |
| Recuperación | Advertencia larga en onboarding | No existe fallback de prueba de propiedad | SIMPLIFY ruta secundaria, usar passkey sincronizada/otro dispositivo; informar límite real |

## Seguridad inspeccionada

Se conservan origen/RP exactos, residentKey requerido, verificación criptográfica de la biblioteca y rechazo adicional en servidor de userVerified=false, nonce firmado de cinco minutos y consumo único en D1, aislamiento de cuenta, cookies protegidas, autorización explícita de dispositivo, caducidad/polling, revocación, D1 rate limiting y sesiones recientes para añadir passkeys. La API de juego no acepta cookies como sustituto del bearer. Ningún nombre, apariencia o hint local concede acceso. No se añaden contraseñas, OTP ni recuperación por datos personales.

El alcance es la UX y persistencia de la sesión existente, sin cambiar proveedor, esquema D1, secretos, economía o cuentas reales. El sistema operativo soportado y comprobable en este proyecto es macOS; otros sistemas conservan acceso por navegador y credenciales en memoria hasta incorporar almacenamiento seguro específico. La distribución sandboxed requiere incluir y firmar el helper como ejecutable integrado.

## Referencias verificadas

- [Better Auth passkeys](https://better-auth.com/docs/plugins/passkey): API de registro/login sin email y credenciales descubribles, contrastada con los paquetes fijados instalados.
- [Autorización de dispositivo](https://better-auth.com/docs/plugins/device-authorization) y [sesiones](https://better-auth.com/docs/concepts/session-management): se mantiene consentimiento explícito; el token es una sesión opaca, no se inventa refresh OAuth.
- [Cloudflare Node compatibility](https://developers.cloudflare.com/workers/runtime-apis/nodejs/): se conserva nodejs_compat y D1.
- [Apple Keychain](https://developer.apple.com/documentation/security/keychain-services) y [Godot OS pipes](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-execute-with-pipe): almacenamiento del sistema y comunicación sin argumentos que contengan secretos.
- [FIDO / Passkey Central](https://www.passkeycentral.org/design-guidelines/): contexto breve, experiencia del sistema y ayuda progresiva.

## Implementación y validación

| Antes | Después | Comprobación |
| --- | --- | --- |
| Registro con campo de cuenta y varias acciones | Empezar + prompt del sistema; identidad del luchador después | WebAuthn real con autenticador virtual |
| Repetir vínculo al abrir el juego | Keychain macOS, validación del servidor, restauración | 16 pruebas de sesión/IPC |
| Login parecido a formulario | Mundo, figura, Continuar y ayuda secundaria | Escritorio y 390×844; materiales de Historia |
| Errores técnicos visibles | Mensajes breves; cancelación silenciosa | Casos de cancelación, red y error de servidor |
| Seguridad mezclada con entrada | Cuenta / Seguridad y segunda passkey | Segundo autenticador y sesión reciente |

Validación: 8 grupos de seguridad del backend; 13 escenarios de navegador local con firmas WebAuthn; 16 comprobaciones de sesión y Keychain; 815 comprobaciones de UI Godot con capturas nativas. Los fixtures usan D1 temporal, Chrome nuevo y un namespace exclusivo de prueba en Keychain, que se borra al terminar. No se utilizaron cuentas personales. Las capturas no representan tasas de conversión reales.

Despliegue de UX en el Worker staging existente, sin migraciones ni cambios de cuentas. El código de dispositivo sigue exigiendo confirmación. No se promete recuperación si se pierden todas las passkeys. Persistencia segura implementada para macOS; las otras plataformas siguen usando memoria hasta tener su adaptador específico.

Evidencia: `work/auth-experience/browser/results.json`, `godot-session.log`, `native.log`, `backend-auth-tests.log`, `deploy.log`; PNG en `browser/` y `native/`.

Comprobación final de cancelación durante escritura segura: el token se publica como sesión activa sólo tras concluir la persistencia sin cancelación. API 27/0, sesión y Keychain 16/0. La posterior versión de staging `2761b4cc-373f-4dca-bb84-0074498447d3` conserva esta UX e incorpora el catálogo de familias.
