# `busybox` smoke test

The most basic use-case of installing a debian package that provides a binary
without dependencies.

Checks the general API and functionality.

Recreate the lockfile with: `bazel run @busybox_amd64//:lock`
