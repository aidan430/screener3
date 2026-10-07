"""Training tables. Imported at the end of factory/models.py so create_all sees them."""
from __future__ import annotations

import json
from datetime import datetime
from typing import Optional

from sqlmodel import Field, SQLModel

from factory.models import utcnow


class Squad(SQLModel, table=True):
    """The five agents Training prepares for one winning niche."""
    id: Optional[int] = Field(default=None, primary_key=True)
    card_id: int = Field(foreign_key="card.id", index=True)
    slug: str = ""
    status: str = "training"                   # training | certified | failed | launched
    attempts: int = 0
    score: float = 0.0                         # lowest agent score, 0-1
    folder: str = ""                           # ventures/{slug}
    sops_json: str = "{}"                      # policies the Playbook writer wrote
    catalogue_json: str = "{}"                 # what the niche sells (Catalogue builder)
    notes: str = ""
    created_at: datetime = Field(default_factory=utcnow)
    certified_at: Optional[datetime] = None
    launched_at: Optional[datetime] = None

    def j(self, field: str):
        return json.loads(getattr(self, field + "_json"))


class SquadAgent(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    squad_id: int = Field(foreign_key="squad.id", index=True)
    role: str                                  # store | content | ads | support | books
    name: str
    model: str
    prompt: str = ""                           # the agent's full instructions
    version: int = 1
    status: str = "drafted"                    # drafted | passed | failed
    score: float = 0.0                         # last exam, 0-1
    breaches: int = 0                          # rules broken in the last exam
    scenarios_json: str = "[]"
    exam_json: str = "[]"                      # [{n, situation, reply, score, breached, feedback}]
    revisions_json: str = "[]"                 # what the Prompt engineer changed and why
    updated_at: datetime = Field(default_factory=utcnow)

    def j(self, field: str):
        return json.loads(getattr(self, field + "_json"))
