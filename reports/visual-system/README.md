# Tablero de revisión visual

Abra [index.html](index.html) directamente; no requiere servidor ni red. Historia es una referencia congelada. Antes y Después muestran sólo capturas de su propia fase; Pendiente significa que todavía no existe una captura After.

Regenerar desde la raíz del workspace: `python3 work/visual-system/build_review.py`. Tras la captura global validada, añadir `--require-final` para excluir toda fase provisional. Configuración: `work/visual-system/review-screens.json`. El manifiesto [review-data.json](review-data.json) conserva ruta, fixture, dimensiones y SHA-256. Los PNG se copian byte por byte; el HTML sólo cambia su tamaño de presentación.
