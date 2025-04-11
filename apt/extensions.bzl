"""
# Extension for downloading and extracting Debian/Ubuntu packages.

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
"""

load("//apt/private:apt_extension.bzl", _apt = "apt")

apt = _apt
