import dataclasses
import random
from typing import Iterable

import faker

from common import models

def generate_profiles(count: int) -> Iterable[models.Profile]:
    """Generate a specified number of random user profiles.

    Args:
        count (int): The number of profiles to generate.

    Yields:
        Iterable[Profile]: An iterator of randomly generated user profiles.

    """
    fake = faker.Faker()
    for _ in range(count):
        name = fake.name()
        age = random.randint(18, 99)
        email = fake.email()
        yield models.Profile(name, age, email)
