import dataclasses
import random
from typing import Iterable

import faker


@dataclasses.dataclass(frozen=True)
class Profile:
    """Represents a user profile with name, age, and email."""

    name: str
    age: int
    email: str


def generate_profiles(count: int) -> Iterable[Profile]:
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
        yield Profile(name, age, email)
