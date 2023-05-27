load("@pip_deps//:requirements.bzl", "requirement")

py_library(
    name = "profile_generator",
    srcs = ["profile_generator.py"],
    deps = [
        requirement("faker"),
    ],
    visibility = ["//:__pkg__"],
)

py_test(
    name = "profile_generator_test",
    srcs = ["profile_generator_test.py"],
    deps = [
        ":profile_generator",
    ],
)
