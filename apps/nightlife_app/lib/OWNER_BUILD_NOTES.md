# Owner build update

Implemented the requested next build batch:

- Owner analytics dashboard
  - Added a dedicated Owner Analytics page.
  - Dashboard now links to analytics from the owner dashboard.
  - Tracks venue views, favourites, conversion, drink views, deal views, event views and crowd activity.

- Improved map experience
  - Venue pins now use crowd-based marker colours.
  - Venue preview logs venue views for analytics.
  - Venue preview shows live crowd signal, active deals and upcoming events.
  - Expired deals are filtered from the map preview.

- Split notifications
  - Personal and business notifications are separated.
  - Account tab badge now tracks personal notifications only.
  - Manage tab badge now tracks business notifications.
  - Notifications screen now has Personal and Business tabs.

- Smart crowd system
  - Added SmartCrowdService.
  - Crowd combines manual crowd, time decay, upcoming/live events, recent check-ins and recent venue interest.
  - Owner venue management and venue details now show smart crowd output.

- Deal expiry hardening
  - Expired deals are deactivated and hidden from customer-facing screens.
  - Reusable deals stream added for owner-side reactivation flows.
