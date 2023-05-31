load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_dataflow//python3:options.bzl", "dataflow_flex_py3_pipeline_options")
load("@rules_python//python/pip_install:requirements.bzl", "compile_pip_requirements")

compile_pip_requirements(
    name = "requirements",
    extra_args = ["--allow-unsafe"],
    requirements_in = "requirements.txt",
    requirements_txt = "requirements_lock.txt",
)

dataflow_flex_py3_pipeline_options(
  name = "profile_pipeline_options",
  options_class = "ProfilePipelineOptions",
  metadata_name = "Profile Pipeline Options",
  metadata_description = "Dataflow Flex Template for Profile Pipeline Options",
  srcs = ["profile_pipeline_options.py"],
  deps = [
    requirement("apache-beam"),
  ],
)
