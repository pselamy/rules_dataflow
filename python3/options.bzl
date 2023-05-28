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

    metadata_script_genrule_name = "generate_{}".format(metadata_script_name)
    metadata_genrule_name = "generate_{}".format(metadata_name)

    native.genrule(
        name=metadata_script_genrule_name,
        srcs=srcs,
        outs=["{}.py".format(metadata_script_name)],
        cmd="""
            echo 'import sys' >> $@
            echo 'import json' >> $@
            echo '' >> $@
            echo "src_file = '$(location {src_file})'" >> $@
            echo "main_class = '{main_class}'" >> $@
            echo '' >> $@
            echo 'with open(src_file) as f:' >> $@
            echo '    script_code = f.read()' >> $@
            echo '' >> $@
            echo 'script_globals = globals().copy()' >> $@
            echo 'script_locals = locals().copy()' >> $@
            echo '' >> $@
            echo 'exec(script_code, script_globals, script_locals)' >> $@
            echo '' >> $@
            echo 'options = script_locals.get(main_class)()' >> $@
            echo 'metadata = []' >> $@
            echo '' >> $@
            echo "for name, value in options.__class__.__dict__.items():" >> $@
            echo '    if isinstance(value, property) and issubclass(value.fget.__class__, apache_beam.options.value_provider.ValueProvider):' >> $@
            echo '        option = {' >> $@
            echo "            'name': name," >> $@
            echo "            'label': name," >> $@
            echo "            'helpText': value.__doc__," >> $@
            echo "            'is_optional': True" >> $@
            echo '        }' >> $@
            echo '        metadata.append(option)' >> $@
            echo '' >> $@
            echo "metadata_json = {" >> $@
            echo "    'name': '{template_name}',".format(template_name=name) >> $@
            echo "    'description': 'Dataflow Flex Template for {template_name}',".format(template_name=name) >> $@
            echo "    'parameters': metadata" >> $@
            echo "}" >> $@
            echo '' >> $@
            echo "with open('$(@)', 'w') as f:" >> $@
            echo "    json.dump(metadata_json, f, indent=4)" >> $@
        """.format(src_file=srcs[0], main_class=main_class),
    )

    py_binary(
        name=metadata_script_name,
        srcs=["{}.py".format(metadata_script_name)],
    )

    native.genrule(
        name=metadata_genrule_name,
        outs=["{}.json".format(metadata_name)],
        cmd="""
            ${{location(":{}")}} --output $@
        """.format(metadata_script_name),
        tools=[":{}".format(metadata_script_name)],
    )
