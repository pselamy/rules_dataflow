import dataclasses

@dataclasses.dataclass(frozen=True)
class Profile:
    """Represents a user profile with name, age, and email."""

    name: str
    age: int
    email: str
