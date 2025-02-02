# `gcc` toolchain test

This test sets up a `gcc` compiler toolchain from Debian packages. See
[clang_toolchain](../clang_toolchain/README.md) for `clang` from Ubuntu.

Recreate the lockfile with: `bazel run @gcc_toolchain//:lock`
