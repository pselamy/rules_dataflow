load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")

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
  py_wheel_name = "{}.wheel".format(name)
  
  py3_image(
    name = py3_image_name,
    main = main,
    deps = deps,
    layers = layers,
  )
