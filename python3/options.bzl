load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_library")

def dataflow_flex_py3_pipeline_options(
    name,
    srcs,
    main_class,
    deps=[],
    **kwargs,
):
    """
    Builds a Dataflow Flex Template and generates metadata.json.

    Args:
        name (str): Name of the target.
        srcs (List[str]): List of source files.
        main_class (str): Name of the main class that extends Apache Beam PipelineOptions.
        deps (List[str]): List of dependencies for the py_library target.
        **kwargs: Additional keyword arguments to pass to py_library.

    Returns:
        None
    """
    library_name = "{}_library".format(name)
    beam_requirement = requirement("apache-beam")
    deps = deps if beam_requirement in deps else deps + [beam_requirement]

    py_library(
        name = library_name,
        srcs = srcs,
        deps = deps,
        **kwargs,
    )

    native.genrule(
        name = name + "_metadata",
        srcs = srcs,
        outs = [name + "/metadata.json"],
        cmd = '''
            python -c "
import sys
import json
from {location} import {main_class}

options = {main_class}()
metadata = []

for name, value in options.__class__.__dict__.items():
    if isinstance(value, property) and issubclass(value.fget.__class__, apache_beam.options.value_provider.ValueProvider):
        option = {{
            'name': name,
            'label': name,
            'helpText': value.__doc__,
            'is_optional': True
        }}
        metadata.append(option)

metadata_json = {{
    'name': '{template_name}',
    'description': 'Dataflow Flex Template for {template_name}',
    'parameters': metadata
}}

with open('$(location {out})', 'w') as f:
    json.dump(metadata_json, f, indent=4)
"
            '''.format(location = ":{}".format(srcs[0]), main_class = main_class, template_name = name, out = name + "/metadata.json"),
    )
