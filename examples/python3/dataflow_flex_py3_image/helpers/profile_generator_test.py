import unittest
from mymodule import generate_profiles


class GenerateProfilesTestCase(unittest.TestCase):
    def test_generate_profiles(self):
        # Test case 1: Generate 5 profiles
        profiles = list(generate_profiles(5))
        self.assertEqual(len(profiles), 5)
        for profile in profiles:
            self.assertIsInstance(profile.name, str)
            self.assertTrue(18 <= profile.age <= 99)
            self.assertIsInstance(profile.email, str)

        # Test case 2: Generate 0 profiles
        profiles = list(generate_profiles(0))
        self.assertEqual(len(profiles), 0)


if __name__ == "__main__":
    unittest.main()
