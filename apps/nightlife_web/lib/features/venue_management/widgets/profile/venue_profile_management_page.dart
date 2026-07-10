import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../auth/services/user_role_service.dart';
import '../../../venue/data/venue_details_mapper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../venues/models/image_position_metadata.dart';
import '../../../venues/models/venue_model.dart';
import '../../../venues/data/venue_image_field_parser.dart';
import '../../data/venue_image_picker.dart';
import '../../data/venue_images_repository.dart';
import '../../data/venue_media_repository.dart';
import '../../data/venue_media_upload_service.dart';
import '../../data/venue_media_upload_errors.dart';
import '../../data/venue_media_upload_logger.dart';
import '../../models/venue_media_type.dart';
import '../../models/venue_dashboard_tab.dart';
import '../../models/venue_page_quick_action.dart';
import '../../services/venue_media_access_service.dart';
import '../drinks/venue_drinks_management_page.dart';
import '../image_reposition/image_reposition_dialog.dart';
import '../page/venue_dashboard_page_scaffold.dart';
import '../../data/venue_profile_repository.dart';
import '../page/venue_dashboard_page_widgets.dart';
import '../profile/edits/venue_profile_edit_dialog.dart';
import '../venue_dashboard_controller.dart';
import 'venue_profile_activity_counts.dart';
import 'venue_profile_dashboard_sections.dart';

/// Customer View Control Centre — venue profile management workspace.
class VenueProfileManagementPage extends StatefulWidget {
  const VenueProfileManagementPage({
    super.key,
    this.repository,
    this.uploadService,
    this.testUploadedByUid,
    this.testUserProfile,
  });

  final VenueImagesRepository? repository;
  final VenueMediaUploadService? uploadService;
  final String? testUploadedByUid;
  final UserRoleProfile? testUserProfile;

  @override
  State<VenueProfileManagementPage> createState() =>
      _VenueProfileManagementPageState();
}

class _VenueProfileManagementPageState
    extends State<VenueProfileManagementPage> {
  late final VenueImagesRepository _repository =
      widget.repository ?? VenueImagesRepository();
  late final VenueProfileRepository _profileRepository = VenueProfileRepository();
  late final VenueMediaRepository _mediaRepository = VenueMediaRepository();
  late final VenueMediaUploadService _uploadService =
      widget.uploadService ??
      VenueMediaUploadService(repository: _mediaRepository);

  final _profileDetailsKey = GlobalKey();
  Future<VenueProfileActivityCounts>? _activityCountsFuture;
  String? _activityCountsVenueId;

  String? _usableImageUrl(String? url) {
    final trimmed = url?.trim() ?? '';
    if (!VenueImageFieldParser.isRenderableImageUrl(trimmed)) {
      return null;
    }
    return trimmed;
  }

  Future<VenueProfileActivityCounts> _activityCountsFor(String venueId) {
    if (_activityCountsFuture != null && _activityCountsVenueId == venueId) {
      return _activityCountsFuture!;
    }
    _activityCountsVenueId = venueId;
    _activityCountsFuture = loadVenueProfileActivityCounts(venueId);
    return _activityCountsFuture!;
  }

  void _scrollToProfileDetails() {
    final context = _profileDetailsKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  Future<void> _handleEditField(
    String fieldLabel,
    VenueModel venue,
    Map<String, dynamic>? rawVenueDocument,
  ) async {
    final field = VenueProfileEditableField.fromLabel(fieldLabel);
    if (field == null) return;

    final saved = await showVenueProfileFieldEditDialog(
      context,
      field: field,
      venue: venue,
      rawVenueDocument: rawVenueDocument,
      repository: _profileRepository,
      testUserId: widget.testUploadedByUid,
      testUserProfile: widget.testUserProfile,
    );

    if (!mounted || saved != true) return;
    _showMessage('${field.label} saved successfully.');
  }

  @override
  Widget build(BuildContext context) {
    final controller = VenueDashboardController.maybeOf(context);
    final venueId = controller?.contextData.venueId ?? '';

    return StreamBuilder<Map<String, dynamic>?>(
      stream: _repository.watchVenueDocument(venueId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final venue = data == null ? null : VenueModel.fromMap(venueId, data);

        return VenueDashboardPageScaffold(
          tab: VenueDashboardTab.venueProfile,
          onPrimaryAction: venue == null ? null : _scrollToProfileDetails,
          onQuickAction: (action) => _handleQuickAction(action, venue, venueId),
          mainContent: venue == null
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryPink,
                  ),
                )
              : FutureBuilder<VenueProfileActivityCounts>(
                  future: _activityCountsFor(venue.id),
                  builder: (context, countsSnapshot) {
                    final activityCounts =
                        countsSnapshot.data ?? VenueProfileActivityCounts.empty;
                    final details = VenueDetailsMapper.fromVenueModel(venue);
                    final bannerUrl = _usableImageUrl(venue.bannerImageUrl);
                    final logoUrl = _usableImageUrl(venue.logoUrl);

                    return VenueProfileDashboardLayout(
                      publicPreview: VenueProfilePublicPreviewCard(
                        venue: venue,
                        details: details,
                        usableBannerUrl: bannerUrl,
                        usableLogoUrl: logoUrl,
                        onEditProfileDetails: _scrollToProfileDetails,
                      ),
                      searchPreview: VenueProfileSearchPreviewCard(
                        venue: venue,
                      ),
                      profileDetails: KeyedSubtree(
                        key: _profileDetailsKey,
                        child: VenueProfileDetailsGrid(
                          venue: venue,
                          rawVenueDocument: data,
                          onEditField: (label) =>
                              _handleEditField(label, venue, data),
                        ),
                      ),
                      branding: VenueProfileBrandingCard(
                        venue: venue,
                        usableBannerUrl: bannerUrl,
                        usableLogoUrl: logoUrl,
                        onUploadLogo: () => _pickAndReposition(
                          frameKind: ImageFrameKind.logo,
                          venue: venue,
                          existingMetadata: venue.logoImagePosition,
                        ),
                        onUploadBanner: () => _pickAndReposition(
                          frameKind: ImageFrameKind.banner,
                          venue: venue,
                          existingMetadata: venue.bannerImagePosition,
                        ),
                        onAdjustLogo: () => _adjustExisting(
                          frameKind: ImageFrameKind.logo,
                          imageUrl: venue.logoUrl,
                          metadata: venue.logoImagePosition,
                          venue: venue,
                        ),
                        onAdjustBanner: () => _adjustExisting(
                          frameKind: ImageFrameKind.banner,
                          imageUrl: venue.bannerImageUrl,
                          metadata: venue.bannerImagePosition,
                          venue: venue,
                        ),
                      ),
                      visibilityChecklist: VenueProfileVisibilityChecklist(
                        venue: venue,
                        activityCounts: activityCounts,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _handleQuickAction(
    VenuePageQuickAction action,
    VenueModel? venue,
    String venueId,
  ) {
    if (venue == null) return;

    if (action.label == 'Edit Venue Details') {
      _scrollToProfileDetails();
      return;
    }
    if (action.actionKey == VenuePageActionKeys.changeBanner) {
      _pickAndReposition(
        frameKind: ImageFrameKind.banner,
        venue: venue,
        existingMetadata: venue.bannerImagePosition,
      );
      return;
    }
    if (action.actionKey == VenuePageActionKeys.uploadLogo) {
      _pickAndReposition(
        frameKind: ImageFrameKind.logo,
        venue: venue,
        existingMetadata: venue.logoImagePosition,
      );
      return;
    }
    if (action.actionKey == VenuePageActionKeys.adjustBannerPosition) {
      _adjustExisting(
        frameKind: ImageFrameKind.banner,
        imageUrl: venue.bannerImageUrl,
        metadata: venue.bannerImagePosition,
        venue: venue,
      );
      return;
    }
    if (action.actionKey == VenuePageActionKeys.adjustLogoPosition) {
      _adjustExisting(
        frameKind: ImageFrameKind.logo,
        imageUrl: venue.logoUrl,
        metadata: venue.logoImagePosition,
        venue: venue,
      );
      return;
    }
    showVenuePagePlaceholderAction(context, action.label);
  }

  Future<void> _adjustExisting({
    required ImageFrameKind frameKind,
    required String imageUrl,
    required ImagePositionMetadata? metadata,
    required VenueModel venue,
  }) async {
    if (imageUrl.trim().isEmpty) {
      _showMessage('Upload a ${frameKind.label.toLowerCase()} first.');
      return;
    }

    final saved = await showImageRepositionDialog(
      context,
      frameKind: frameKind,
      imageUrl: imageUrl,
      initialMetadata: metadata,
      previewSubtitle: frameKind == ImageFrameKind.banner
          ? 'Matches your public venue profile banner frame.'
          : 'Matches the circular logo on venue cards.',
    );
    if (!mounted || saved == null) return;
    await _persistPosition(venue: venue, frameKind: frameKind, metadata: saved);
  }

  Future<void> _pickAndReposition({
    required ImageFrameKind frameKind,
    required VenueModel venue,
    required ImagePositionMetadata? existingMetadata,
  }) async {
    final mediaType = frameKind.venueMediaType;
    if (mediaType == null) return;

    final bytes = await pickVenueImageBytes();
    if (!mounted || bytes == null) return;

    final provider = MemoryImage(bytes);
    final saved = await showImageRepositionDialog(
      context,
      frameKind: frameKind,
      imageProvider: provider,
      initialMetadata: existingMetadata,
      previewSubtitle: frameKind == ImageFrameKind.banner
          ? 'Matches your public venue profile banner frame.'
          : 'Matches the circular logo on venue cards.',
    );
    if (!mounted || saved == null) return;

    final userId =
        widget.testUploadedByUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      _showMessage('You must be signed in to upload images.');
      return;
    }

    try {
      final profile =
          widget.testUserProfile ??
          await UserRoleService.getCurrentUserProfile();
      if (!mounted) return;
      final controller = VenueDashboardController.maybeOf(context);

      await _uploadService.uploadBrandingImage(
        venueId: venue.id,
        uploadedByUid: userId,
        mediaType: mediaType,
        bytes: bytes,
        fileName: frameKind == ImageFrameKind.logo ? 'logo.jpg' : 'banner.jpg',
        profile: profile,
        position: saved,
        venueOwnerId: venue.ownerId,
        accessibleVenueIds:
            controller?.contextData.availableVenueIds ?? const [],
      );
    } on VenueMediaAccessDeniedException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
      return;
    } on VenueMediaUploadException catch (error) {
      if (!mounted) return;
      VenueMediaUploadLogger.logFailure(error);
      _showMessage(error.messageForUi(includeDevDetails: true));
      return;
    } catch (error, stackTrace) {
      if (!mounted) return;
      final mapped = VenueMediaUploadException.fromObject(
        error,
        stackTrace: stackTrace,
        context: 'branding upload venueId=${venue.id}',
      );
      VenueMediaUploadLogger.logFailure(mapped);
      _showMessage(mapped.messageForUi(includeDevDetails: true));
      return;
    }

    if (!mounted) return;
    _showMessage('${frameKind.label} uploaded and saved.');
  }

  Future<void> _persistPosition({
    required VenueModel venue,
    required ImageFrameKind frameKind,
    required ImagePositionMetadata metadata,
  }) async {
    try {
      await _repository.saveImagePosition(
        venueId: venue.id,
        frameKind: frameKind,
        metadata: metadata,
      );

      final mediaId = frameKind == ImageFrameKind.logo
          ? venue.currentLogoMediaId
          : venue.currentBannerMediaId;
      if (mediaId.trim().isNotEmpty) {
        await _mediaRepository.saveBrandingCrop(
          venueId: venue.id,
          mediaId: mediaId,
          metadata: metadata,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not save image position. Please try again.');
      return;
    }

    if (!mounted) return;
    _showMessage('${frameKind.label} position saved.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
