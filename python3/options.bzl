load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")


def dataflow_flex_py3_pipeline_options(
    name,
    src,
    options_class,
    metadata_name,
    metadata_description,
    deps=[],
    tags=[],
    **kwargs,
):
    """
    Define a bazel rule for generating metadata json for a Google Cloud Dataflow pipeline.
    This rule imports a python script as a module and uses the pipeline options defined
    in the script to generate a metadata json file.

    Args:
        name (str): Name of the rule, also used as a base name for generated targets.
        src (str): The python source file for the pipeline options.
        options_class (str): The name of the main pipeline options class in the source.
        metadata_name (str): Name of the pipeline, to be used in the metadata.
        metadata_description (str): Description of the pipeline, to be used in the metadata.
        deps (List[str], optional): Additional dependencies needed by the pipeline options script. Defaults to an empty list.
        tags (List[str], optional): Bazel tags. Defaults to an empty list.
        **kwargs: Additional keyword arguments that will be passed to the py_library rule.

    This function defines several bazel targets internally:
    - A python library target for the pipeline script.
    - A genrule target for generating a python script that generates the metadata json.
    - A python binary target for the generated script.
    - A genrule target that runs the script and writes the metadata json to a file.

    """

    # Format target and script names using the base name
    metadata_script_name = "{}.metadata_script".format(name)
    metadata_target_name = "{}.metadata".format(name)
    
    # Extract module name from python file name
    module_name = src.split("/")[-1].rstrip(".py")

    # Add apache-beam requirement to deps if it's not already there
    beam_requirement = requirement("apache-beam")
    deps = deps if beam_requirement in deps else deps + [beam_requirement]

    # Define a py_library target for the pipeline script
    py_library(
        name=name,
        srcs=[src],
        deps=deps,
        tags=tags,
        **kwargs,
    )

    # Define a genrule target that generates a python script for creating the metadata json
    native.genrule(
        name="generate_{}".format(metadata_script_name),
        outs=["{}.py".format(metadata_script_name)],
        srcs=[src],
        cmd=r"""
cat > $@ << 'EOF'
import importlib.util
import json
import sys
import logging

import argparse

logging.basicConfig(level=logging.DEBUG)

def generate_metadata_json(script_file, output_file):
    script_file = sys.argv[1]

    logging.debug('Importing module...')
    module_name = "{module_name}"

    spec = importlib.util.spec_from_file_location(module_name, script_file)
    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    spec.loader.exec_module(module)
    
    options_class = getattr(module, "{options_class}")
    logging.debug('Successfully imported module %s.', module_name)

    logging.debug('Generating metadata...')
    metadata = {{
        "name": "{metadata_name}",
        "description": "{metadata_description}",
        "parameters": [],
    }}

    # Instantiate the parser and add the argparse args
    parser = argparse.ArgumentParser()
    options_class._add_argparse_args(parser)

    # Iterate over the actions added to the parser
    for action in parser._actions:
        if action.dest == "help":
            continue

        if not action.help:
            raise ValueError("%s is missing help text." % action.dest)

        parameter = {{
            "name": action.dest,
            "label": action.dest.replace("_", " ").title(),
            "helpText": action.help,
            "isOptional": action.default is not None,
        }}
        metadata["parameters"].append(parameter)

    # Write metadata to a json file
    output_file = sys.argv[2]
    with open(output_file, 'w') as f:
        print(json.dumps(metadata, indent=4),file=f)

    logging.debug("Successfully generated metadata file: %s" % output_file)

if __name__ == "__main__":
    script_file = sys.argv[1]
    output_file = sys.argv[2]
    generate_metadata_json(script_file, output_file)
EOF
""".format(
            metadata_name=metadata_name,
            metadata_description=metadata_description,
            module_name=module_name,
            options_class=options_class
        ),
        tools=[":{}".format(name)],
    )

    # Define a py_binary target for the metadata generator script
    py_binary(
        name=metadata_script_name,
        srcs=["{}.py".format(metadata_script_name)],
        deps=[
            ":{}".format(name),
            beam_requirement,
        ],
    )

    # Define a genrule target that runs the metadata generator script and writes the output to a json file
    native.genrule(
        name="generate_{}".format(metadata_target_name),
        outs=["{}.json".format(metadata_target_name)],
        cmd=r"$(location :{metadata_script_name}) $(location :{name}) $@".format(
            metadata_script_name=metadata_script_name,
            name=name,
        ),
        tools=[":{}".format(metadata_script_name), ":{}".format(name)],
        tags=tags,
    )

