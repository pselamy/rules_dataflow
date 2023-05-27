import unittest
import dataclasses

from common import models
from common import profile_processor


class ProfileProcessorTestCase(unittest.TestCase):
    def test_process_profile(self):
        # Arrange
        profile = models.Profile(name="John Doe", age=25, email="johndoe@example.com")
        expected_hash = "3fc93ea9182f3d65dcb868fbf378f395"
        processor = profile_processor.ProfileProcessor()

        # Act
        actual_hash = processor.process_profile(profile)

        # Assert
        self.assertEqual(actual_hash, expected_hash)

if __name__ == "__main__":
    unittest.main()
