load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_binary", "py_library")

def dataflow_flex_py3_pipeline_options(
    name,
    srcs,
    main_class,
    deps=[],
    **kwargs,
):
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
        outs=["{}.py".format(metadata_script_name)],
        cmd=r"""
cat > $@ << 'EOF'
import sys
import json

import apache_beam
from rules_python.python.runfiles import runfiles

r = runfiles.Create()
src_file = r.Rlocation("$(location :{})")

main_class = '{}'

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
    'name': '{}',
    'description': 'Dataflow Flex Template for {}',
    'parameters': metadata
}}

with open('$@', 'w') as f:
    json.dump(metadata_json, f, indent=4)
EOF
""".format(library_name, main_class, metadata_name, metadata_name),
        tools=[":{}".format(library_name)],
    )

    py_binary(
        name=metadata_script_name,
        srcs=["{}.py".format(metadata_script_name)],
        deps=[
            ":{}".format(library_name),
            beam_requirement,
            "@rules_python//python/runfiles"
        ],
    )

    native.genrule(
        name="generate_{}".format(metadata_name),
        outs=["{}.json".format(metadata_name)],
        cmd="$(location :{}) --output $@ $(location :{})".format(metadata_script_name, metadata_script_name),
        tools=[":{}".format(metadata_script_name)],
    )
