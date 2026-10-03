"""
=============================================================================
EXTENSION POINT: Ticket Availability Stub
=============================================================================
This module is reserved for future integration with real ticket availability
endpoints per match (e.g., category-level seat counts or available gates),
if and when Tazkarti exposes an official or documented availability endpoint.

DO NOT INVENT ENDPOINTS. Leave this as a clean extension stub.
"""
from typing import Optional, Dict, Any


def check_availability(match_id: int) -> Optional[Dict[str, Any]]:
    """
    Check ticket availability for a specific match_id.
    Currently returns None until an official availability endpoint is integrated.
    """
    # Stub: Return None or future schema:
    # {
    #     "match_id": match_id,
    #     "is_available": True,
    #     "categories": [{"name": "CAT 1", "price": 150, "available_seats": 25}],
    #     "checked_at": datetime.utcnow().isoformat()
    # }
    return None
