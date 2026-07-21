import 'package:flutter/widgets.dart';

import '../widgets/venue_management_page_activity_controller.dart';

/// Reloads canonical page-scoped activity after a successful mutation.
Future<void> reloadVenueManagementPageActivity(BuildContext context) async {
  await VenueManagementPageActivityController.reloadIfPresent(context);
}
