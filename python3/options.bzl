load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "genrule", "py_binary", "py_library")

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
        name=library_name,
        srcs=srcs,
        deps=deps,
        **kwargs,
    )

    native.genrule(
        name=name + "_generate_metadata_script",
        srcs=srcs,
        outs=[name + "/metadata_script.py"],
        cmd="""
            cat $(location {src_file}) > $@
        """.format(src_file=srcs[0]),
    )

    py_binary(
        name=name + "_metadata_script",
        srcs=[name + "/metadata_script.py"],
        main="metadata_script.py",
        deps=deps,
    )

    native.genrule(
        name=name + "_metadata",
        srcs=srcs,
        outs=[name + "/metadata.json"],
        cmd="""
            python -c "
            import sys
            import json

            src_file = '{src_file}'
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
                'name': '{template_name}',
                'description': 'Dataflow Flex Template for {template_name}',
                'parameters': metadata
            }}

            with open('$@', 'w') as f:
                json.dump(metadata_json, f, indent=4)
            "
        """.format(src_file=name + "/metadata_script.py", main_class=main_class, template_name=name),
        tools=[":" + name + "_metadata_script"],
    )
