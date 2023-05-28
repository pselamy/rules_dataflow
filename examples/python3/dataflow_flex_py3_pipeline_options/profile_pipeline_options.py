from apache_beam.options import pipeline_options


class ProfilePipelineOptions(pipeline_options.PipelineOptions):
    @classmethod
    def _add_argparse_args(cls, parser):
        parser.add_argument(
            "--input",
            dest="input",
            default="gs://my-bucket/input",
            help="Input file or directory for the profile pipeline.",
        )
        parser.add_argument(
            "--output",
            dest="output",
            default="gs://my-bucket/output",
            help="Output directory for the profile pipeline.",
        )
        parser.add_argument(
            "--profile_id",
            dest="profile_id",
            default="12345",
            help="ID of the profile for the profile pipeline.",
        )
