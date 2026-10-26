#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
native_root="$repo_root/ios-native"

if [[ "$(uname -s)" != "Darwin" ]]; then
    printf '%s\n' 'Este comando abre Xcode en macOS. En Windows solo se edita el codigo.' >&2
    exit 1
fi

if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf '\nRama: '
    git -C "$repo_root" branch --show-current
    printf 'Commit: '
    git -C "$repo_root" log -1 --oneline
    if ! git -C "$repo_root" merge-base --is-ancestor f9afc46 HEAD; then
        printf '%s\n' 'Esta copia no incluye los ocho arreglos. Actualizala desde la raiz:' \
            'git switch feat/native-ui' 'git pull --ff-only' >&2
        exit 1
    fi
fi

if [[ ! -f "$native_root/Sources/Components/AutoAdjustmentCard.swift" ]]; then
    printf '%s\n' 'Faltan fuentes de la actualizacion. Descarga la rama feat/native-ui completa.' >&2
    exit 1
fi

if ! command -v xcodegen >/dev/null 2>&1; then
    printf '%s\n' 'Instala XcodeGen y vuelve a ejecutar este comando:' 'brew install xcodegen' >&2
    exit 1
fi

if ! xcodebuild -version >/dev/null 2>&1; then
    printf '%s\n' 'Abre Xcode > Settings > Locations y selecciona Xcode en Command Line Tools.' >&2
    exit 1
fi

cd "$native_root"
xcodegen generate
printf '\nAbriendo proyecto nativo: %s\n' "$native_root/EpicenterDSP.xcodeproj"
printf '%s\n' 'Selecciona tu Team y tu iPhone; ejecuta con Command + R.' \
    'Comprueba la version 12.0.0 (21) en Musica > Ajustes > Acerca de.'
open "$native_root/EpicenterDSP.xcodeproj"
