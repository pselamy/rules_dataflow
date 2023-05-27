import unittest

from common import profile_generator


class GenerateProfilesTestCase(unittest.TestCase):
    def test_generate_profiles_count(self):
        # Test generating 5 profiles
        profiles = list(profile_generator.generate_profiles(5))
        self.assertEqual(len(profiles), 5)

    def test_generate_profiles_types(self):
        # Test profile attribute types
        profiles = list(profile_generator.generate_profiles(5))
        for profile in profiles:
            self.assertIsInstance(profile.name, str)
            self.assertIsInstance(profile.age, int)
            self.assertIsInstance(profile.email, str)

    def test_generate_profiles_age_range(self):
        # Test age range of generated profiles
        profiles = list(profile_generator.generate_profiles(5))
        for profile in profiles:
            self.assertTrue(18 <= profile.age <= 99)

    def test_generate_profiles_zero_count(self):
        # Test generating 0 profiles
        profiles = list(profile_generator.generate_profiles(0))
        self.assertEqual(len(profiles), 0)


if __name__ == "__main__":
    unittest.main()
