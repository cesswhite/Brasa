# Ónix y Bruma · continuidad de identidad e inventario

La revisión encontró y corrigió dos bloqueos de cuentas anteriores: el archivo local de identidad exigía que los cuerpos recién añadidos ya estuvieran presentes, y la siembra D1 actualizaba el catálogo sin concedérselos a cuentas existentes. Las cuentas nuevas ya recibían ambos.

## Archivo local

Solo el **sidecar de identidad pasa de v1 a v2**. Los archivos y esquemas de progresión de Liga e Historia no cambian.

La carga valida primero la identidad anterior, sus 22 opciones y las apariencias contra su inventario original. Después agrega únicamente `body_style:onix` y `body_style:bruma` en memoria. Conserva el ID de cuenta, los IDs de cada luchador, nombres personalizados o heredados, cuerpos equipados, fechas y registros de inventario. No concede recompensas ni admite cosméticos desconocidos. Un archivo v2 al que falte un cuerpo obligatorio sigue siendo inválido.

Cargar no escribe. El siguiente guardado explícito persiste v2 y deja los bytes originales v1 en `.bak`; un guardado repetido sin cambios no rota esa copia. Fallos de escritura y escritores concurrentes conservan el archivo anterior. Una identidad corrupta sigue protegida incluso si existe una copia válida.

## Cuentas del servidor

La nueva migración **0005_starter_expansions.sql** crea un registro de expansiones aplicadas. La siembra del catálogo ejecuta `cats-v1`: entrega solo los dos cuerpos gratuitos a las cuentas existentes y registra la aplicación. Volver a sembrar no repone cuerpos revocados después, defaults anteriores ausentes ni premios de progreso. No cambia luchadores, nombres, estadísticas, XP o revisiones.

Las cuentas nuevas siguen recibiendo los 24 cosméticos iniciales por el flujo existente. No se añadieron consultas ni escrituras de migración por petición HTTP. Es necesario aplicar las cinco migraciones y sembrar el catálogo, siguiendo [DEPLOYMENT.md](../backend/docs/DEPLOYMENT.md); este trabajo no ejecutó acciones remotas.

## Evidencia

- **95 comprobaciones locales, 0 fallos:** fixture portable v1 con 13 identidades y 22 opciones, nombres heredados y cuerpo personalizado; migración, equipamiento de ambos gatos, identidad compartida entre modos, preservación exacta de los archivos de progresión copiados, corrupción, fallo de rename y concurrencia.
- **4 pruebas D1, 0 fallos:** cuentas antiguas con 22 opciones; antes de sembrar reciben 403 al crear gatos y después crean ambos correctamente; identidad y progreso entrenado permanecen iguales; revocación, reseed, rollback SQL y concurrencia comprobados.

[Validación y hashes](cat_identity_migration_validation.json) · [Prueba local](../tests/test_cat_identity_migration.gd) · [Prueba D1](../backend/tests/cat-inventory-migration.test.mjs).

Todas las verificaciones usaron fixtures propios. No se abrió ni escribió ninguna partida real, base remota o credencial personal.
