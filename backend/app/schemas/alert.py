from datetime import datetime

from pydantic import BaseModel, ConfigDict


class AlertResponse(BaseModel):
    id: int
    alert_type: str
    message: str
    severity: str
    is_read: bool
    created_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)
