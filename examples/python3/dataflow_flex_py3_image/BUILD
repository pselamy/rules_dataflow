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
    layers = [
      "//helpers:profile_generator",  
    ],
)

py_test(
    name = "profile_pipeline_test",
    srcs = ["profile_pipeline_test.py"],
    deps = [
      ":profile_pipeline.base.binary",  
    ],
)
