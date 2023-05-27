py_library(
    name = "generate_profiles",
    srcs = ["generate_profiles.py"],
    deps = [
        requirement("faker"),
    ],
)

py_test(
    name = "generate_profiles_test",
    srcs = ["generate_profiles_test.py"],
    deps = [
        ":generate_profiles",
    ],
)
