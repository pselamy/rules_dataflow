load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_dataflow//python3:image.bzl", "dataflow_flex_py3_image")
load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--allow-unsafe"],
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
)

# Minimal Example
dataflow_flex_py3_image(
    name = "profile_pipeline",
    app_version = "0.0.1",
    base = "@dataflow_python310_template_launcher_base//image",
    packages = [
        "common",
    ],
    requires = [
        "Faker==18.9.0",
        "apache-beam[gcp]==2.47.0",
    ],
    layers = [
      requirement("Faker"),
      requirement("apache-beam"),        
      "//common:profile_generator",  
      "//common:profile_processor",  
    ],
)

py_test(
    name = "profile_pipeline_test",
    srcs = ["profile_pipeline_test.py"],
    deps = [
      ":profile_pipeline.base.binary",  
    ],
)
