# CC toolchain tests

Build/test with either:

```py
bazel build --config=clang //:hello_world
bazel build --config=gcc //:hello_world
bazel test //...
```

## `clang` toolchain test

Instead of using
[`toolchains_llvm`](https://github.com/bazel-contrib/toolchains_llvm) and only
[testing the sysroot](../llvm_toolchain/README.md), this test sets up a
`clang-10` compiler toolchain from Ubuntu packages.

Recreate the lockfile with: `bazel run @clang_toolchain//:lock`

## `gcc` toolchain test

This test sets up a `gcc` compiler toolchain from Debian packages.

Recreate the lockfile with: `bazel run @gcc_toolchain//:lock`
