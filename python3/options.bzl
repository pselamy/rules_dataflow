load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")


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
    # Assumes that there's only a single source file which is a python file
    module_name = srcs[0].split("/")[-1].rstrip(".py")

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
import logging

import argparse

logging.basicConfig(level=logging.DEBUG)

def generate_metadata_json():
    script_file = sys.argv[1]

    logging.debug('Importing module...')
    module_name = "{module_name}"
    module = importlib.import_module(module_name)
    options_class = getattr(module, "{options_class_name}")
    logging.debug(f'Successfully imported module {module_name}.')

    logging.debug('Generating metadata...')
    metadata = {{
        "name": '{name}',
        "description": 'Dataflow Flex Template for {metadata_name}',
        "parameters": [],
    }}

    # Instantiate the parser and add the argparse args
    parser = argparse.ArgumentParser()
    options_class._add_argparse_args(parser)

    # Iterate over the actions added to the parser
    for action in parser._actions:
        if action.dest == "help":
            continue

        parameter = {{
            "name": action.dest,
            "label": action.dest.capitalize().replace("_", " "),
            "helpText": action.help,
            "isOptional": action.default is not None,
        }}
        metadata["parameters"].append(parameter)


    logging.debug(metadata)

    # Write metadata to a json file
    output_file = sys.argv[2]
    with open(output_file, 'w') as f:
        json.dump(metadata, f, indent=4)

if __name__ == "__main__":
    generate_metadata_json()
EOF
""".format(name=name, metadata_name=metadata_name, module_name=module_name, options_class_name=main_class),
        tools=[":{}".format(library_name)],
    )

    # Define a py_binary target for the metadata generator script
    py_binary(
        name=metadata_script_name,
        srcs=["{}.py".format(metadata_script_name)],
        deps=[
            ":{}".format(library_name),
            beam_requirement,
        ],
    )

    # Define a genrule target that runs the metadata generator script and writes the output to a json file
    native.genrule(
        name="generate_{}".format(metadata_name),
        outs=["{}.json".format(metadata_name)],
        cmd=r"$(location :{metadata_script_name}) --output $@ $(location :{metadata_script_name}) {main_class}".format(
            metadata_script_name=metadata_script_name,
            main_class=main_class,
        ),
        tools=[":{}".format(metadata_script_name)],
    )
