# Business Dashboard Upgrade

Added `lib/features/owner/screens/business_dashboard_screen.dart` and connected it to the owner/manage tab.

## Included

- 4-tab owner dashboard: Overview, Manage, Analytics, Growth
- Business overview cards for venues, drinks, deals, events, venues with deals, and busy venues
- Daily checklist for content readiness
- Venue status list
- Quick actions for:
  - Add venue
  - Add drink
  - Add deal
  - Add event
  - Update crowd level
  - Boost venue
  - Owner Pro upgrade
- Analytics tab using the existing `OwnerAnalyticsSummaryCard`
- Growth tab for boosts and owner subscription upsell

## Connected files

- `lib/features/navigation/main_navigation_screen.dart`
  - Owner users now open `BusinessDashboardScreen` instead of the older `OwnerDashboardScreen`.

## Notes

The dashboard reads existing Firebase collections:

- `drinks`
- `deals`
- `events`
- owner venues through `VenueService.getVenuesForOwner`

Run after replacing the project files:

```bash
flutter clean
flutter pub get
flutter run
```
