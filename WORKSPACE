workspace(name = "rules_dataflow")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

##########################
##### SKYLIB SUPPORT #####
##########################
git_repository(
    name = "bazel_skylib",
    remote = "https://github.com/bazelbuild/bazel-skylib",
    tag = "1.4.1",
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

###########################
####### PKG SUPPORT #######
###########################
git_repository(
    name = "rules_python",
    remote = "https://github.com/bazelbuild/rules_pkg",
    tag = "0.9.1",
)

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")
rules_pkg_dependencies()

##########################
##### PYTHON SUPPORT #####
##########################
git_repository(
    name = "rules_python",
    remote = "https://github.com/bazelbuild/rules_python",
    tag = "0.20.0",
)

load("@rules_python//python:repositories.bzl", "python_register_toolchains")

python_register_toolchains(
    name = "python3_10",
    # Available versions are listed in @rules_python//python:versions.bzl.
    # We recommend using the same version your team is already standardized on.
    python_version = "3.10",
)

load("@python3_10//:defs.bzl", "interpreter")
load("@rules_python//python:pip.bzl", "pip_parse")

# Create a central repo that knows about the dependencies needed from
# requirements_lock.txt.
pip_parse(
    name = "pip_deps",
    python_interpreter_target = interpreter,
    requirements_lock = "//:requirements_lock.txt",
)

# Load the starlark macro which will define your dependencies.
load("@pip_deps//:requirements.bzl", "install_deps")

# Call it to define repos for your requirements.
install_deps()

##########################
##### DOCKER SUPPORT #####
##########################
git_repository(
    name = "io_bazel_rules_docker",
    remote = "https://github.com/bazelbuild/rules_docker",
    tag = "v0.22.0",
)

load(
    "@io_bazel_rules_docker//repositories:repositories.bzl",
    container_repositories = "repositories",
)

container_repositories()

load("@io_bazel_rules_docker//python3:image.bzl", _py_image_repos = "repositories")

_py_image_repos()

load("@io_bazel_rules_docker//repositories:deps.bzl", container_deps = "deps")

container_deps()
