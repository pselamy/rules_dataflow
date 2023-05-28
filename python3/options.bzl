load("@pip_deps//:requirements.bzl", "requirement")
load("@rules_python//python:defs.bzl", "py_library")

def dataflow_flex_py3_pipeline_options(
    name,
    srcs,
    main_class,
    **kwargs,
):
    """
    Builds a Dataflow Flex Template and generates metadata.json.

    Args:
        name (str): Name of the target.
        srcs (List[str]): List of source files.
        main_class (str): Name of the main class that extends Apache Beam PipelineOptions.
        **kwargs: Additional keyword arguments to pass to py_library.

    Returns:
        None
    """
    library_name = "{}.library".format(name)

    py_library(
        name=library_name,
        srcs=srcs,
        deps=[
            requirement("apache-beam"),
        ],
        **kwargs,
    )

    native.genrule(
        name="{}.flex_template".format(name),
        srcs=[":{}".format(library_name)],
        outs=["metadata.json"],
        cmd="""
            echo '{
                "metadata": {
                    "sdkInfo": {
                        "language": "PYTHON"
                    }
                },
                "parameters": [
                    $$(cat $$(location :{library}) | python3 -c "
                        import sys, inspect
                        options = inspect.getmembers(sys.modules['__main__'], inspect.isclass)
                        options = [
                            option[1] for option in options if issubclass(option[1], \
                            sys.modules['apache_beam'].PipelineOptions)
                        ]
                        print(','.join([
                            '{{"name": \'{option.__name__}\', "label": \'{option.__name__}\', \
                            "helpText": \'{option.__doc__}\', "isOptional": true}}' \
                            for option in options
                        ]))
                    ")
                ]
            }' > $@
        """.format(library=library_name),
    )
