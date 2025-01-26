# `clang` toolchain test

Instead of using
[`toolchains_llvm`](https://github.com/bazel-contrib/toolchains_llvm) and only
[testing the sysroot](../llvm_toolchain/README.md), this test sets up a
`clang-10` compiler toolchain from Ubuntu packages.

Recreate the lockfile with: `bazel run @clang_toolchain//:lock`
