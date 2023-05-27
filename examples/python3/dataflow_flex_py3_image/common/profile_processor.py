import dataclasses
from typing import Callable

from common import models

@dataclasses.dataclass(frozen=True)
class ProfileProcessor:
  process_profile: Callable[[models.Profile], str]
