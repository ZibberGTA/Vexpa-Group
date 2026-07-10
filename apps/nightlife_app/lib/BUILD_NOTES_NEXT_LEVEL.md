# Next-Level Build Notes

Implemented in this LIB update:

## Live map glow system
- Busy and packed venues now render a soft circle glow around the map marker.
- Marker hue still reflects crowd level.
- Added a "Recommended now" map strip based on live crowd, active deals and upcoming events.

## Owner revenue dashboard
- Owner analytics now includes estimated visits, estimated revenue and ROI signal.
- Estimates are intentionally conservative and based on app engagement signals until real POS/deal redemption tracking is connected.

## AI-style venue recommendations
- Added `VenueRecommendationService`.
- Recommendations score venues using crowd level, active deals and upcoming events.
- Map displays a recommendation strip for quick user discovery.

## Push/notification engine change
- Removed crowd-update user notifications.
- Notifications are now limited to users who have saved/favourited the venue.
- Saved-venue notifications are only created for new deals and new upcoming events.
- Crowd updates are still logged for analytics only.
