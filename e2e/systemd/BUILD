load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@bazel_skylib//rules:diff_test.bzl", "diff_test")

diff_test(
    name = "manifest",
    file1 = "@systemd//:manifest",
    file2 = "expected_manifest.json",
)

build_test(
    name = "build_file_substitutions",
    targets = ["@systemd//:test_alias"],
)
