#!/usr/bin/bash

# This wraps gcc and post-processes the generated dotd file to make all included
# system headers relative paths. The `gcc` from Ubuntu/Debian is patched in a
# way that `-no-canonical-prefixes` has no effect.
# https://sources.debian.org/src/gcc-13/13.3.0-12/debian/patches/canonical-cpppath.diff

set -euo pipefail

function relativize_dotd() {
    dotd="$(echo "$@" | grep -o "\-MF [^ ]*.d" | cut -d' ' -f2 || echo "")"

    if [[ -n ${dotd} ]]; then
        sed -i "s:$(realpath "$(pwd)")/::" "${dotd}"
    fi
}

trap 'relativize_dotd "$@"' EXIT

GCC_EXEC_PREFIX="$(dirname "$(which "$(basename "$0")")")/../../usr/lib/gcc/" \
    "$(basename "$0")" "$@"
exit $?
