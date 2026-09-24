#!/bin/zsh
set -eu

BRASA_DIR="${0:A:h}"
BRASA_GODOT="/Applications/Godot.app/Contents/MacOS/Godot"

if [[ ! -x "$BRASA_GODOT" ]]; then
  printf '%s\n' \
    'No se encontró Godot en /Applications/Godot.app.' \
    'Instala Godot 4.7.2 estándar en Aplicaciones y vuelve a abrir Jugar.command.'
  read -r '?Pulsa Intro para cerrar…' || true
  exit 127
fi

cd -- "$BRASA_DIR"
exec "$BRASA_GODOT" --path "$BRASA_DIR" "$@"
