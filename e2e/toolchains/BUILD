load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_platform//platform_data:defs.bzl", "platform_data")

cc_binary(
    name = "hello_world",
    srcs = ["hello_world.cc"],
    tags = ["manual"],
)

platform_data(
    name = "hello_clang",
    platform = "//platforms:clang",
    target = ":hello_world",
)

platform_data(
    name = "hello_gcc",
    platform = "//platforms:gcc",
    target = ":hello_world",
)

build_test(
    name = "smoke_test",
    targets = [
        ":hello_clang",
        ":hello_gcc",
    ],
)
