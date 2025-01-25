load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "busybox",
    src = "@busybox//:bin/busybox",
)

genrule(
    name = "echo",
    outs = ["out.txt"],
    cmd = './$(location busybox) echo "Hello Bazel"> "$@"',
    tools = ["busybox"],
)

diff_test(
    name = "echo_output",
    file1 = ":out.txt",
    file2 = "expected.txt",
)

build_test(
    name = "smoke_test",
    targets = [
        ":busybox",
        ":echo",
    ],
)
