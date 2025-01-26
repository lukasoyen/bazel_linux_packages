# End to End Smoke Tests

These e2e tests exercise the repo from an end-users perspective. They catch
mistakes in our install instructions, or usages that fail when called from an
"external" repository to debian_packages. They are also used by the presubmit
check for the Bazel Central Registry.

- [`busybox` smoke test](smoke/README.md)
- [`llvm_toolchain` syroot test](llvm_toolchain/README.md)
- [`clang` toolchain test](clang/README.md)
