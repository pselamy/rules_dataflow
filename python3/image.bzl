load("@io_bazel_rules_docker//container:container.bzl", "container_image")
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
  packages = [],
  requires = [],
  entrypoint = "/opt/google/dataflow/python_template_launcher",
  python_tag = "py3",
  **kwargs,
):
  main = main or "{}.py".format(name)
  srcs = srcs if main in srcs else srcs + [main]
  py3_image_name = "{}.base".format(name)
  py_binary_name = "{}.binary".format(py3_image_name)
  py_package_name = "{}.pkg".format(name)
  py_wheel_name = "{}.wheel".format(name)
  py_wheel_path = "{name}-{version}-{python_tag}-none-any.whl"
  required_deps = [
    requirement(r.split("==")[0].split("[")[0]) 
    for r in requires
  ]
  layers = layers + [
    r 
    for r in required_deps 
    if r not in layers and r not in deps
  ]
  
  container_image(
    name = name,
    base = ":{}".format(py3_image_name),
    entrypoint = entrypoint,
    env = {
      "FLEX_TEMPLATE_PYTHON_PY_FILE": py_binary_name,
      "FLEX_TEMPLATE_PYTHON_EXTRA_PACKAGES": "/{}".format(py_wheel_path)
    },
    files = [
      ":{}".format(py_wheel_name)
    ]
  )
  
  py3_image(
    name = py3_image_name,
    srcs = srcs,
    # See https://cloud.google.com/dataflow/docs/reference/flex-templates-base-images for list of images.
    base = base,
    main = main,
    deps = deps,
    layers = layers,
    **kwargs,
  )

  py_package(
    name = py_package_name,
    packages = packages,
    deps = [
      ":{}".format(py_binary_name),
    ],
  )
  
  py_wheel(
    name = py_wheel_name,
    # {name}-{version}-{python_tag}-none-any.whl
    distribution = name,
    version = wheel_version,
    requires = requires,
    deps = [
      ":{}".format(py_package_name),
    ],
  )
