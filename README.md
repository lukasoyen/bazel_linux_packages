# Bazel Extension for downloading and extracting Debian/Ubuntu packages.

This `bazel` extension enables downloading and extracting `*.deb` into a `bazel`
repository. This can be used to run binaries packaged as `*.deb` packages or
create compiler toolchains and sysroots.

> [!IMPORTANT]
> This is not a ruleset to create `*.deb` ore other Linux distribution packages.

## Usage

Place the following in your `MODULE.bazel`. Then:

- run `bazel run @busybox//:lock` to create a lockfile and
- run `bazel run @busybox//:bin/busybox` to download/extract the package and run the binary.

```py
apt = use_extension("@bazel_linux_packages//apt:extensions.bzl", "apt")
apt.source(
    architectures = ["amd64"],
    components = ["main"],
    suites = ["focal"],
    uri = "https://snapshot.ubuntu.com/ubuntu/20250219T154000Z",
)
apt.download(
    lockfile = "//:focal.lock.json",
    packages = ["busybox"],
)
apt.install(name = "busybox")
use_repo(apt, "busybox")
```

See [e2e/](e2e/README.md) for end to end tests and
[the extension docs](docs/extensions.md) for more details:

- [`apt.source()`](docs/extensions.md#source)
- [`apt.download()`](docs/extensions.md#download)
- [`apt.install()`](docs/extensions.md#install)

## Handle Library Paths

- As packages are installed in a non-standard location, binaries might not
  find their required libraries. Additionally, as the packages are pulled for
  a Debian/Ubuntu distribution that is based on a specific `glibc` version,
  incompatibilities can result in errors. The created repository will contain
  the correct `glibc` version. There are two strategies to handle these:

  1. Set [`fix_rpath_with_patchelf = True`](docs/extensions.md#apt.install-fix_rpath_with_patchelf) for
     [`apt.install()`](docs/extensions.md#install). This will use
     [`patchelf`](https://github.com/NixOS/patchelf) to modify the executables
     and binaries to add library search directories to `RUNPATH`. See also
     `fix_absolute_interpreter_with_patchelf`,
     `fix_relative_interpreter_with_patchelf`, and `extra_patchelf_dirs`.
  2. The systems' loader will be used to load required libraries and will search
     system-wide. `LD_LIBRARY_PATH` can be used to set directories to search.
     `LD_DEBUG` can be used to debug missing library issues. The generated
     repository exposes `with_repository_prefix()` that returns the `exec`-root
     relative path to it. It can be used like:

     ```py
     load("@my_repository//:defs.bzl", "with_repository_prefix")

     my_rule(
         [...]
         env = {"LD_LIBRARY_PATH": with_repository_prefix("usr/lib/x86_64-linux-gnu")},
     )
     ```

- The `glibc` version from the extracted packages might be compiled against
  a newer Linux kernel than you are running and error out. Use
  `file path/to/your/binary` to check which kernel version is the minimum required.

## Related

- [debian_dependency_bazelizer](https://github.com/shabanzd/debian_dependency_bazelizer)
  does something in the same area, but differently
- [bazel-cc-sysroot-generator](https://github.com/keith/bazel-cc-sysroot-generator)
  creates a sysroot archive outside of `bazel`

## Credit

- https://github.com/keith/bazel-cc-sysroot-generator inspired the idea
- https://github.com/GoogleContainerTools/rules_distroless was forked and reworked
  - ideas from https://github.com/GoogleContainerTools/rules_distroless/issues/123 were used
  - https://github.com/GoogleContainerTools/rules_distroless/issues/124 is the same idea
