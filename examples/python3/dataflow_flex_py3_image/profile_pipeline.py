import apache_beam as beam

from common import profile_generator
from common import profile_processor


def run() -> None:
    """Runs the Apache Beam pipeline to print profiles."""
    with beam.Pipeline() as pipeline:
        profiles = (
            pipeline
            | beam.Create(profile_generator.generate_profiles(10))
            | beam.Map(print)
        )


if __name__ == "__main__":
    run()
