import dataclasses
from typing import Callable

import json
import hashlib

from common import models

@dataclasses.dataclass(frozen=True)
class ProfileProcessor:
    @staticmethod
    def _process_profile(profile: models.Profile) -> str:
        """
        Returns the MD5 hash of the JSON representation of a profile.

        Args:
            profile: The profile object.

        Returns:
            A string representing the MD5 hash of the profile JSON.
        """
        profile_json = json.dumps(dataclasses.asdict(profile))
        hash_object = hashlib.md5(profile_json.encode())
        return hash_object.hexdigest()

    process_profile: Callable[[models.Profile], str] = _process_profile
