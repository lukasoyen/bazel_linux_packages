load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")
load("@busybox_shared_amd64//:defs.bzl", SHARED_INTERPRETER = "INTERPRETER")

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

# Use static BusyBox so Resolute packages can be tested on older Linux hosts.
native_binary(
    name = "busybox_resolute",
    src = select({
        "@platforms//cpu:x86_64": "@busybox_resolute_amd64//:usr/bin/busybox",
        "@platforms//cpu:arm64": "@busybox_resolute_arm64//:usr/bin/busybox",
    }),
)

genrule(
    name = "echo_resolute",
    outs = ["out_resolute.txt"],
    cmd = './$(location busybox_resolute) echo "Hello Bazel"> "$@"',
    tools = ["busybox_resolute"],
)

diff_test(
    name = "echo_resolute_output",
    file1 = ":out_resolute.txt",
    file2 = "expected_output.txt",
)

diff_test(
    name = "manifest_resolute_amd64",
    file1 = "@busybox_resolute_amd64//:manifest",
    file2 = "expected_manifest_resolute_amd64.json",
)

diff_test(
    name = "manifest_resolute_arm64",
    file1 = "@busybox_resolute_arm64//:manifest",
    file2 = "expected_manifest_resolute_arm64.json",
)

native_binary(
    name = "busybox_shared",
    src = "@busybox_shared_amd64//:bin/busybox",
)

# BusyBox must use the shared interpreter outside the output base.
genrule(
    name = "echo_shared",
    outs = ["out_shared.txt"],
    cmd = " && ".join(
        [
            # buildifier: disable=external-path
            'case "{0}" in */external/*|"") exit 1;; esac'.format(SHARED_INTERPRETER),
            './$(location busybox_shared) strings $(location busybox_shared) | ./$(location busybox_shared) grep -qxF "{0}"'.format(SHARED_INTERPRETER),
            './$(location busybox_shared) echo "Hello Bazel" > "$@"',
        ],
    ),
    # Only amd64 packages have their interpreter in `lib64/`.
    target_compatible_with = ["@platforms//cpu:x86_64"],
    tools = ["busybox_shared"],
)

diff_test(
    name = "echo_shared_output",
    file1 = ":out_shared.txt",
    file2 = "expected_output.txt",
)
