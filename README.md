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
apt.ubuntu(
    name = "busybox",
    lockfile = "//:focal.lock.json",
    packages = ["busybox"],
    suites = ["focal"],
)
use_repo(apt, "busybox")
```

See [e2e/](e2e/README.md) for end to end tests and
[the extension docs](docs/extensions.md) for more details:

- [`apt.download()`](docs/extensions.md#download)
- [`apt.ubuntu()`](docs/extensions.md#ubuntu)
- [`apt.debian()`](docs/extensions.md#debian)

## Handle Library Paths

- As packages are installed in a non-standard location, binaries might not
  find their required libraries. Additionally, as the packages are pulled for
  a Debian/Ubuntu distribution that is based on a specific `glibc` version,
  incompatibilities can result in errors. The created repository will contain
  the correct `glibc` version. There are two strategies to handle these:

  1. Set [`fix_rpath_with_patchelf = True`](docs/extensions.md#apt.install-fix_rpath_with_patchelf) for
     [`apt.download()`](docs/extensions.md#download). This will use
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

## Key Differences to `rules_distroless`

This project was forked from
[`rules_distroless`](https://github.com/GoogleContainerTools/rules_distroless)
but serves a distinct purpose.

`bazel_linux_packages` is focused on downloading and extracting individual
`.deb` packages (and their dependencies) for use as tooling or libraries in
Bazel builds for the execution platform. It is ideal when you need to run
packaged binaries, create toolchains, build sysroots, or access specific
libraries from Linux distributions within your build process. The result is a
Bazel repository containing the extracted package contents, ready for use in
your build rules.

On the other hand, `rules_distroless` is designed to create complete
Linux/Debian installations from scratch, mainly for building minimal container
images or full system environments for the target platform. Use it when you need
to assemble a full Linux filesystem layout, create distroless containers, or
perform system administration tasks as part of your build. The output is a
complete filesystem tree suitable for use as a container image or runtime
environment.

Use `bazel_linux_packages` for integrating specific Linux packages or tools into
your Bazel build, and use `rules_distroless` when you need to build a full
minimal Linux environment or container image. Both can be combined—extract
development tools with `bazel_linux_packages`, then assemble your final runtime
with `rules_distroless`.

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
