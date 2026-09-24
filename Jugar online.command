#!/bin/zsh
set -eu
BRASA_LAUNCH_DIR="${0:A:h}"
exec "$BRASA_LAUNCH_DIR/Jugar.command" -- --online
