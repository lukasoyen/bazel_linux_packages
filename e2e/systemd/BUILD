load("@bazel_skylib//rules:diff_test.bzl", "diff_test")

diff_test(
    name = "manifest",
    file1 = "@systemd//:manifest",
    file2 = "expected_manifest.json",
)
