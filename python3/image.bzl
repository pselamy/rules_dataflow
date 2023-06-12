load("@io_bazel_rules_docker//container:container.bzl", "container_image")
load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")
load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:packaging.bzl", "py_package")
load("@rules_python//python:packaging.bzl", "py_wheel")


def dataflow_flex_py3_image(
  name,
  app_version,
  base,
  requirements_file,
  visibility=["//visibility:private"],
  srcs=[],
  main="",
  distribution="",
  deps=[],
  layers=[],
  packages=[],
  entrypoint="/opt/google/dataflow/python_template_launcher",
  **kwargs,
):
  """
  Generates a Docker image for Dataflow Flex Templates in Python 3.

  Args:
    name (str): Name of the Docker image.
    app_version (str): Application version.
    base (str): Base image for the Docker image.
    visibility (str): The Bazel visibility. Defaults to ["//visibility:private"].
    srcs (List[str], optional): Source files. Defaults to a list containing main.
    main (str, optional): Main source file. Defaults to name + .py.
    distribution (str, optional): Distribution file. Defaults to the value of name.
    deps (List[str], optional): Dependency files. Defaults to an empty list.
    layers (List[str], optional): Additional layers for the Docker image. Defaults to an empty list.
    packages (List[str], optional): Python packages. Defaults to an empty list.
    entrypoint (str, optional): Docker container entrypoint. Defaults to "/opt/google/dataflow/python_template_launcher".
    **kwargs: Additional arguments.

  Returns:
    None
  """

  # Set main source file if not provided
  main = main or "{}.py".format(name)

  # Include main source file in srcs if it's not already present
  srcs = srcs if main in srcs else srcs + [main]

  # Generate names for intermediate targets
  base_container_image_name = "{}.image".format(name)
  py3_image_name = "{}.base".format(name)
  py_binary_name = "{}.binary".format(py3_image_name)
  distribution = distribution or name
  py_package_name = "{}.pkg".format(name)
  py_wheel_name = "{}.wheel".format(name)

  # Generate the filename for the Python wheel
  py_wheel_path = "{name}-{version}-py3-none-any.whl".format(
    name=name,
    version=app_version,
  )

  generated_requirements_name = "{}.requirements".format(name)
  generated_requirements_path = "generated_{}_requirements.txt".format(name)

  beam_requirement = requirement("apache-beam")
  # Check if 'beam_requirement' is already in 'deps' or 'layers'
  if beam_requirement not in deps + layers:
    # If not present, add 'beam_requirement' to 'layers'
    layers = layers + [beam_requirement]

  # Compute the package path
  package_name = native.package_name()
  package_path = package_name + "/" if package_name else ""

  container_image(
      name = base_container_image_name,
      # See https://cloud.google.com/dataflow/docs/reference/flex-templates-base-images for list of images.
      base = base,
      entrypoint="/bin/bash",
      # Beam base image places python3 under /usr/local/bin, but the host
      # toolchain used by py3_image might use /usr/bin instead.
      symlinks = {
          "/usr/bin/python": "/usr/local/bin/python",
          "/usr/bin/python3": "/usr/local/bin/python3",
      },
  )

  container_image(
    name=name,
    base=":{}".format(py3_image_name),
    entrypoint=entrypoint,
    env={
      "FLEX_TEMPLATE_PYTHON_PY_FILE": "{}{}".format(package_path, py_binary_name),
      "FLEX_TEMPLATE_PYTHON_REQUIREMENTS_FILE": "/{}".format(generated_requirements_path)      
    },
    files=[
      ":{}".format(generated_requirements_name),
      ":{}".format(py_wheel_name),
    ],
    visibility=visibility,
  )

  py3_image(
    name=py3_image_name,
    srcs=srcs,
    base=":{}".format(base_container_image_name),
    main=main,
    deps=deps,
    layers=layers,
    visibility=visibility,
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
    distribution = distribution,
    version = app_version,
    deps = [
      ":{}".format(py_package_name),
    ],
  )

  native.genrule(
    name = generated_requirements_name,
    srcs = [requirements_file],
    outs = [generated_requirements_path],
    cmd = """
        cat $(SRCS) > $(OUTS) &&
        echo $${py_wheel_path} >> $(OUTS)
    """,
    args = {
        "py_wheel_path": "/{}".format(py_wheel_path),
    },
  )

