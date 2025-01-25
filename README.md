# Bazel extension for downloading and extracting debian packages

This `bazel` extension enables downloading and extracting `*.deb` into a `bazel`
repository. This can be used to run binaries packaged as `*.deb` packages or
create compiler toolchains and sysroots.

> [!IMPORTANT]
> This is not a ruleset to create `*.deb` packages.

## Usage

Put the following in your `MODULE.bazel`. During the first setup a `*.lock.json`
file will not exist. Run `bazel run @busybox//:lock` to create the lockfile.
After that, `bazel run @busybox//:bin/busybox` should run the downloaded binary.
See [e2e/smoke/MODULE.bazel](e2e/smoke/MODULE.bazel) for an end to end test.

```
apt = use_extension("@debian_packages//apt:extensions.bzl", "apt", dev_dependency = True)
apt.source(
    architectures = ["amd64"],
    components = [
        "main",
        "universe",
    ],
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
