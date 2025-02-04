#!/usr/bin/bash

# This wraps gcc and post-processes the generated dotd file to make all
# included system headers relative paths.
#
# Even though we pass -no-canoncical-prefixes/-fno-canonical-system-headers to gcc,
#  it prints absolute include paths.
#
# The `gcc` from Ubuntu/Debian is patched in a way, that `-no-canonical-prefixes`
# has no effect. Bug: https://gcc.gnu.org/bugzilla/show_bug.cgi?id=102803
# patch: https://sources.debian.org/src/gcc-13/13.3.0-12/debian/patches/canonical-cpppath.diff

# This wrapper requires the actual compiler to be passed as the first argument
readonly gcc="$1"; shift

readonly dotd="$(echo "$@" | grep -o "\-MF [^ ]*.d" | cut -d' ' -f2 || echo "")"
"${gcc}" "$@"
readonly ret=$?
if [[ -n "${dotd}" ]]; then
  sed -i "s:$(realpath $(pwd))/::" "${dotd}"
fi
exit $ret
