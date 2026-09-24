#!/bin/sh
set -eu
cd "$(dirname "$0")"
/usr/bin/swiftc -O session_store.swift -framework Security -o brasa-session-store
/usr/bin/codesign --force --sign - --identifier game.brasa.session-store brasa-session-store
chmod 755 brasa-session-store
