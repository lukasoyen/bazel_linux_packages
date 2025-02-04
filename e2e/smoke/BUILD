load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
    name = "busybox",
    src = select({
        "@platforms//cpu:x86_64": "@busybox_amd64//:bin/busybox",
        "@platforms//cpu:arm64": "@busybox_arm64//:bin/busybox",
    }),
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
    file2 = "expected_output.txt",
)

diff_test(
    name = "manifest_amd64",
    file1 = "@busybox_amd64//:manifest",
    file2 = "expected_manifest_amd64.json",
)

diff_test(
    name = "manifest_arm64",
    file1 = "@busybox_arm64//:manifest",
    file2 = "expected_manifest_arm64.json",
)

build_test(
    name = "smoke_test",
    targets = [":echo"],
)
