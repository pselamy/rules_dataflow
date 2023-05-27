import apache_beam as beam

from helpers import profile_generator


def run() -> None:
    """Runs the Apache Beam pipeline to print profiles."""
    with beam.Pipeline() as pipeline:
        profiles = (
            pipeline
            | beam.Create(profile_generator.generate_profiles())
            | beam.Map(print)
        )


if __name__ == "__main__":
    run()
