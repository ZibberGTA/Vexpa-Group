import 'package:vex_core/vex_core.dart';

import '../../features/venue/data/models/deal_model.dart';

VenueDeal vexVenueDealFromDealModel(DealModel model) {
  return VenueDeal(
    id: model.id,
    venueId: model.venueId,
    title: model.title,
    description: model.description,
    dealType: model.dealType,
    value: model.value,
    startTime: model.startTime,
    endTime: model.endTime,
    startDateTime: model.startDateTime,
    endDateTime: model.endDateTime,
    isActive: model.isActive,
    featured: model.featured,
    isDeleted: model.isDeleted,
  );
}

DealModel dealModelFromVexVenueDeal(VenueDeal deal) {
  return DealModel(
    id: deal.id,
    venueId: deal.venueId,
    title: deal.title,
    description: deal.description,
    dealType: deal.dealType,
    value: deal.value,
    startTime: deal.startTime,
    endTime: deal.endTime,
    startDateTime: deal.startDateTime,
    endDateTime: deal.endDateTime,
    isActive: deal.isActive,
    featured: deal.featured,
    isDeleted: deal.isDeleted,
  );
}
