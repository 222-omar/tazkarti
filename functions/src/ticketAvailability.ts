/**
 * ============================================================================
 * EXTENSION POINT: Ticket Availability Stub
 * ============================================================================
 * This module is reserved for future integration with real ticket availability
 * endpoints per match (e.g. category-level seat counts or available gates),
 * if and when Tazkarti exposes an official or documented availability endpoint.
 *
 * DO NOT INVENT ENDPOINTS. Leave this as a clean extension stub.
 */

export interface TicketAvailability {
  matchId: number;
  isAvailable: boolean;
  categories: Array<{
    name: string;
    price?: number;
    availableSeats?: number;
  }>;
  checkedAt: string;
}

/**
 * Check ticket availability for a specific matchId.
 * Currently returns null until an official availability endpoint is integrated.
 */
export async function checkAvailability(
  matchId: number
): Promise<TicketAvailability | null> {
  // Stub implementation
  // In the future:
  // const res = await axios.get(`https://tazkarti.com/data/availability-${matchId}.json`);
  // return parseAvailability(res.data);
  return null;
}
