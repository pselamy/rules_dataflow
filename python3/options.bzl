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
    metadata_script_name = "{}_metadata_script".format(name)
    metadata_name = "{}_metadata".format(name)
    beam_requirement = requirement("apache-beam")
    deps = deps if beam_requirement in deps else deps + [beam_requirement]

    py_library(
        name=library_name,
        srcs=srcs,
        deps=deps,
        **kwargs,
    )

    native.genrule(
        name="generate_{}".format(metadata_script_name),
        srcs=srcs,
        outs=["{}.py".format(metadata_script_name)],
        cmd="""\
cat > $@ << EOF
import sys
import json

src_file = '$(location {src_file})'
main_class = '{main_class}'

with open(src_file) as f:
    script_code = f.read()

script_globals = globals().copy()
script_locals = locals().copy()

exec(script_code, script_globals, script_locals)

options = script_locals.get(main_class)()
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
    'name': '{metadata_name}',
    'description': 'Dataflow Flex Template for {metadata_name}',
    'parameters': metadata
}}

with open('$@', 'w') as f:
    json.dump(metadata_json, f, indent=4)
EOF
""".format(src_file=srcs[0], main_class=main_class, metadata_name=name),
    )

    py_binary(
        name=metadata_script_name,
        srcs=["{}.py".format(metadata_script_name)],
    )

    native.genrule(
        name="generate_{}".format(metadata_name),
        outs=["{}.json".format(metadata_name)],
        cmd="$< --output $@",
        tools=[":{}".format(metadata_script_name)],
    )
