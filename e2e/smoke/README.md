# `busybox` smoke test

The most basic use-case of installing a debian package that provides a binary
without dependencies.

Checks the general API and functionality.

The Focal and Resolute cases check package extraction for amd64 and arm64 and run
BusyBox on the host architecture. Resolute uses `busybox-static` so the tests can
run on older Linux distributions, including the existing Ubuntu 22.04 CI job.

Recreate the lockfiles with:

```sh
bazel run @busybox_amd64//:lock
bazel run @busybox_resolute_amd64//:lock
```
