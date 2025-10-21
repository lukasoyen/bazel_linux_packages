# `llvm_toolchain` syroot test

https://github.com/bazel-contrib/toolchains_llvm is a `bazel` toolchain using
the LLVM suite. Unfortunately lacking a sysroot, making it non-hermetic in its
default configuration.

This e2e test downloads `gcc-10` as a sysroot and configures `toolchains_llvm`
to use it. Note that the `gcc-10` binary downloaded with this is not used at all.

Recreate the lockfile with: `bazel run @gcc_sysroot//:lock`
