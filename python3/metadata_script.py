import sys
import json
import inspect

from apache_beam.options import pipeline_options
from absl import app
from absl import flags

FLAGS = flags.FLAGS
flags.DEFINE_string("src_file", None, "Path to the source file", required=True)
flags.DEFINE_string("output_file", None, "Path to the output file", required=True)


def generate_metadata(src_file, output_file):
    sys.path.insert(0, "")
    module_name = src_file.split(".")[0]
    module = __import__(module_name)
    classes = inspect.getmembers(module, inspect.isclass)
    options = [option[1] for option in classes if issubclass(option[1], pipeline_options.PipelineOptions)]

    metadata = []
    for option in options:
        option_name = option.__name__
        option_label = option_name
        option_help_text = option.__doc__
        option_dict = {
            "name": option_name,
            "label": option_label,
            "helpText": option_help_text,
            "isOptional": True
        }
        metadata.append(option_dict)

    metadata_json = {
        "name": module_name,
        "description": f"Dataflow Flex Template for {module_name}",
        "parameters": metadata
    }

    with open(output_file, "w") as f:
        json.dump(metadata_json, f, indent=4)

def main(argv):
    generate_metadata(FLAGS.src_file, FLAGS.output_file)

if __name__ == "__main__":
    app.run(main)
