load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")
load("@rules_python//python:packaging.bzl", "py_package")
load("@rules_python//python:packaging.bzl", "py_wheel")

def dataflow_flex_py3_image(
  name,
  wheel_version,
  base,
  main = "",
  deps = [],
  layers = [],
):
  main = main or "{}.py".format(name)
  py3_image_name = "{}.base".format(name)
  py_binary_name = "{}.binary".format(py3_image_name)
  py_wheel_name = "{}.wheel".format(name)
  
  container_image(
    name = name,
    base = ":{}".format(py3_image_name),
    env = {},
  )
  
  py3_image(
    name = py3_image_name,
    main = main,
    deps = deps,
    layers = layers,
    base = base,
  )
  
  py_wheel(
    name = py_wheel_name,
    version = wheel_version,
  )
