load("@pip_deps//:requirements.bzl", "requirement")

py_library(
    name = "models",
    srcs = ["models.py"],
)

py_library(
    name = "profile_generator",
    srcs = ["profile_generator.py"],
    deps = [
        requirement("faker"),
        ":models",
    ],
    visibility = ["//:__pkg__"],
)

py_test(
    name = "profile_generator_test",
    srcs = ["profile_generator_test.py"],
    deps = [
        ":models",
        ":profile_generator",
    ],
)

py_library(
    name = "profile_processor",
    srcs = ["profile_processor.py"],
    deps = [
        ":models",
        ":profile_processor",
    ],
    visibility = ["//:__pkg__"],
)

py_test(
    name = "profile_processor_test",
    srcs = ["profile_processor_test.py"],
    deps = [
        ":models",
        ":profile_processor",
    ],
)
