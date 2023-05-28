"""
Import necessary bazel build libraries and rules.
"""

load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")


def dataflow_flex_py3_pipeline_options(
    name,
    srcs,
    main_class,
    deps=[],
    **kwargs,
):
    """
    Define a bazel rule for generating metadata json for a Google Cloud Dataflow pipeline.
    This rule imports a python script as a module and uses the pipeline options defined
    in the script to generate a metadata json file.

    Args:
        name (str): Name of the rule, also used as a base name for generated targets.
        srcs (List[str]): Source files for the pipeline.
        main_class (str): The name of the main pipeline options class in the source.
        deps (List[str], optional): Additional dependencies needed by the pipeline script.
        **kwargs: Additional keyword arguments.

    Returns:
        None
    """

    # Format library and script names using the base name
    library_name = "{}_library".format(name)
    metadata_script_name = "{}_metadata_script".format(name)
    metadata_name = "{}_metadata".format(name)

    # Add apache-beam requirement to deps if it's not already there
    beam_requirement = requirement("apache-beam")
    deps = deps if beam_requirement in deps else deps + [beam_requirement]

    # Define a py_library target for the pipeline script
    py_library(
        name=library_name,
        srcs=srcs,
        deps=deps,
        **kwargs,
    )

    # Define a genrule target that generates a python script for creating the metadata json
    native.genrule(
        name="generate_{}".format(metadata_script_name),
        outs=["{}.py".format(metadata_script_name)],
        cmd=r"""
cat > $@ << 'EOF'
import importlib
import json
import sys

def generate_metadata_json():
    script_file = sys.argv[1]
    options_class_name = sys.argv[2]

    try:
        # Import the pipeline script as a module
        module_name = script_file.rstrip(".py").lstrip("./").lstrip("/")
        module = importlib.import_module(module_name)
        options_class = getattr(module, options_class_name)

        # Generate metadata JSON based on the options class
        metadata = {
            "name": '{}',
            "description": 'Dataflow Flex Template for {}',
            "parameters": [],
        }

        # Retrieve the pipeline options
        options = options_class()

        # Iterate over the options class attributes
        for attr_name, attr_value in options.__class__.__dict__.items():
            if isinstance(attr_value, property) and issubclass(attr_value.fget.__class__, apache_beam.options.value_provider.ValueProvider):
                parameter = {
                    "name": attr_name,
                    "label": attr_name.capitalize().replace("_", " "),
                    "helpText": attr_value.__doc__,
                    "isOptional": True,
                }
                metadata["parameters"].append(parameter)

        # Write metadata to a json file
        with open('$@', 'w') as f:
            json.dump(metadata, f, indent=4)

    except Exception as e:
        print(f"Error: {str(e)}")

if __name__ == "__main__":
    generate_metadata_json()
EOF
""".format(metadata_name, metadata_name),
        tools=[":{}".format(library_name)],
    )

    # Define a py_binary target for the metadata generator script
    py_binary(
        name=metadata_script_name,
        srcs=["{}.py".format(metadata_script_name)],
        deps=[
            ":{}".format(library_name),
            beam_requirement,
            "@rules_python//python/runfiles"
        ],
    )

    # Define a genrule target that runs the metadata generator script and writes the output to a json file
    native.genrule(
        name="generate_{}".format(metadata_name),
        outs=["{}.json".format(metadata_name)],
        cmd="$(location :{}) --output $@ $(location :{})".format(metadata_script_name, metadata_script_name),
        tools=[":{}".format(metadata_script_name)],
    )
