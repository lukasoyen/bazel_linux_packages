load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

cc_binary(
    name = "hello_world",
    srcs = ["hello_world.cc"],
)

build_test(
    name = "smoke_test",
    targets = [":hello_world"],
)
