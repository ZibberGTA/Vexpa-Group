import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/components/drinkspot_button.dart';
import '../../../../../shared/widgets/glass_container.dart';
import '../../../../auth/services/user_role_service.dart';
import '../../../../venues/models/venue_model.dart';
import '../../../services/venue_media_access_service.dart';
import '../../../data/venue_profile_constants.dart';
import '../../../data/venue_profile_field_codec.dart';
import '../../../data/venue_profile_repository.dart';
import '../../venue_dashboard_controller.dart';

enum VenueProfileEditableField {
  venueName('Venue Name'),
  category('Category'),
  address('Address'),
  description('Description'),
  website('Website'),
  openingHours('Opening Hours'),
  featureTags('Feature Tags'),
  crowdLevel('Crowd Level'),
  ageRestriction('18+ Venue');

  const VenueProfileEditableField(this.label);

  final String label;

  static VenueProfileEditableField? fromLabel(String label) {
    for (final field in values) {
      if (field.label == label) return field;
    }
    return null;
  }
}

Future<bool?> showVenueProfileFieldEditDialog(
  BuildContext context, {
  required VenueProfileEditableField field,
  required VenueModel venue,
  required Map<String, dynamic>? rawVenueDocument,
  VenueProfileRepository? repository,
  String? testUserId,
  UserRoleProfile? testUserProfile,
}) {
  final controller = VenueDashboardController.maybeOf(context);
  final contextData = controller?.contextData;
  if (contextData == null) return Future.value(null);

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => VenueProfileFieldEditDialog(
      field: field,
      venue: venue,
      rawVenueDocument: rawVenueDocument,
      repository: repository ?? VenueProfileRepository(),
      testUserId: testUserId,
      testUserProfile: testUserProfile,
    ),
  );
}

class VenueProfileFieldEditDialog extends StatefulWidget {
  const VenueProfileFieldEditDialog({
    super.key,
    required this.field,
    required this.venue,
    required this.rawVenueDocument,
    required this.repository,
    this.testUserId,
    this.testUserProfile,
  });

  final VenueProfileEditableField field;
  final VenueModel venue;
  final Map<String, dynamic>? rawVenueDocument;
  final VenueProfileRepository repository;
  final String? testUserId;
  final UserRoleProfile? testUserProfile;

  @override
  State<VenueProfileFieldEditDialog> createState() =>
      _VenueProfileFieldEditDialogState();
}

class _VenueProfileFieldEditDialogState extends State<VenueProfileFieldEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  late final TextEditingController _multilineController;
  late String? _selectedCategory;
  late String? _selectedCrowdLevel;
  late Set<String> _selectedFeatureKeys;
  late bool _ageRestricted;
  late Map<String, Map<String, dynamic>> _openingHoursDraft;
  late final Map<String, TextEditingController> _openControllers;
  late final Map<String, TextEditingController> _closeControllers;
  late final Map<String, bool> _closedDays;

  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final venue = widget.venue;
    final raw = widget.rawVenueDocument;

    _textController = TextEditingController();
    _multilineController = TextEditingController();
    _selectedCategory = venue.category.trim().isNotEmpty
        ? venue.category.trim()
        : VenueProfileConstants.categories.first;
    _selectedCrowdLevel = venue.crowdLevel.trim().isNotEmpty
        ? venue.crowdLevel.trim().toLowerCase()
        : VenueProfileConstants.crowdLevels.first.value;
    _selectedFeatureKeys = VenueProfileFieldCodec.selectedFeatureTagKeys(
      venue,
      raw,
    );
    if (_selectedFeatureKeys.length > VenueProfileConstants.maxFeatureTags) {
      _selectedFeatureKeys = _selectedFeatureKeys
          .take(VenueProfileConstants.maxFeatureTags)
          .toSet();
    }
    _ageRestricted = VenueProfileFieldCodec.isAgeRestrictedVenue(venue, raw);
    _openingHoursDraft = VenueProfileFieldCodec.parseOpeningHours(
      venue.openingHours,
    );

    _openControllers = {};
    _closeControllers = {};
    _closedDays = {};
    for (final day in VenueProfileConstants.openingDayKeys) {
      final dayData = _openingHoursDraft[day] ?? const {};
      _openControllers[day] = TextEditingController(
        text: (dayData['open'] ?? '12:00').toString(),
      );
      _closeControllers[day] = TextEditingController(
        text: (dayData['close'] ?? '23:00').toString(),
      );
      _closedDays[day] = dayData['closed'] == true;
    }

    switch (widget.field) {
      case VenueProfileEditableField.venueName:
        _textController.text = venue.name;
      case VenueProfileEditableField.address:
        _textController.text = venue.address;
      case VenueProfileEditableField.website:
        _textController.text = venue.website;
      case VenueProfileEditableField.description:
        _multilineController.text = venue.description;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _multilineController.dispose();
    for (final controller in _openControllers.values) {
      controller.dispose();
    }
    for (final controller in _closeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  VenueModelSnapshot _buildSnapshot({
    required String userId,
    required UserRoleProfile profile,
  }) {
    final dashboard = VenueDashboardController.maybeOf(context);
    return VenueModelSnapshot(
      userId: userId,
      profile: profile,
      venueOwnerId: widget.venue.ownerId,
      accessibleVenueIds: dashboard?.contextData.availableVenueIds ?? const [],
      name: widget.venue.name,
      description: widget.venue.description,
      address: widget.venue.address,
      category: widget.venue.category,
      crowdLevel: widget.venue.crowdLevel,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;

    final userId = widget.testUserId ?? FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      setState(() => _errorMessage = 'You must be signed in to save changes.');
      return;
    }

    UserRoleProfile profile;
    try {
      profile =
          widget.testUserProfile ?? await UserRoleService.getCurrentUserProfile();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Could not verify your account. Please try again.',
      );
      return;
    }

    final snapshot = _buildSnapshot(userId: userId, profile: profile);
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      switch (widget.field) {
        case VenueProfileEditableField.venueName:
          await widget.repository.updateVenueName(
            venueId: widget.venue.id,
            name: _textController.text.trim(),
            context: snapshot,
          );
        case VenueProfileEditableField.category:
          await widget.repository.updateVenueCategory(
            venueId: widget.venue.id,
            category: _selectedCategory!,
            context: snapshot,
          );
        case VenueProfileEditableField.address:
          await widget.repository.updateVenueAddress(
            venueId: widget.venue.id,
            address: _textController.text.trim(),
            context: snapshot,
          );
        case VenueProfileEditableField.description:
          await widget.repository.updateVenueDescription(
            venueId: widget.venue.id,
            description: _multilineController.text.trim(),
            context: snapshot,
          );
        case VenueProfileEditableField.website:
          await widget.repository.updateVenueWebsite(
            venueId: widget.venue.id,
            website: _textController.text.trim(),
            context: snapshot,
          );
        case VenueProfileEditableField.openingHours:
          final draft = _currentOpeningHoursDraft();
          final validationError = VenueProfileFieldCodec.validateOpeningHours(
            draft,
          );
          if (validationError != null) {
            setState(() {
              _saving = false;
              _errorMessage = validationError;
            });
            return;
          }
          await widget.repository.updateOpeningHours(
            venueId: widget.venue.id,
            openingHours: draft,
            context: snapshot,
          );
        case VenueProfileEditableField.featureTags:
          await widget.repository.updateFeatureTags(
            venueId: widget.venue.id,
            selectedKeys: _selectedFeatureKeys,
            ageRestricted: _ageRestricted,
            context: snapshot,
          );
        case VenueProfileEditableField.crowdLevel:
          await widget.repository.updateCrowdLevel(
            venueId: widget.venue.id,
            crowdLevel: _selectedCrowdLevel!,
            context: snapshot,
          );
        case VenueProfileEditableField.ageRestriction:
          await widget.repository.updateAgeRestriction(
            venueId: widget.venue.id,
            ageRestricted: _ageRestricted,
            selectedFeatureKeys: _selectedFeatureKeys,
            context: snapshot,
          );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on VenueMediaAccessDeniedException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = 'Could not save changes. Please try again.';
      });
    }
  }

  Map<String, Map<String, dynamic>> _currentOpeningHoursDraft() {
    final draft = <String, Map<String, dynamic>>{};
    for (final day in VenueProfileConstants.openingDayKeys) {
      draft[day] = {
        'closed': _closedDays[day] == true,
        'open': VenueProfileFieldCodec.normaliseTimeInput(
          _openControllers[day]?.text ?? '',
        ),
        'close': VenueProfileFieldCodec.normaliseTimeInput(
          _closeControllers[day]?.text ?? '',
        ),
      };
    }
    return draft;
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = widget.field == VenueProfileEditableField.openingHours
        ? 640.0
        : 560.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit ${widget.field.label}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _fieldSubtitle(widget.field),
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.92),
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildFieldContent(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.primaryPink,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                  if (_saving) ...[
                    const SizedBox(height: AppSpacing.md),
                    const LinearProgressIndicator(
                      color: AppColors.primaryPink,
                      backgroundColor: AppColors.surface,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: DrinkSpotButton(
                          label: 'Cancel',
                          variant: DrinkSpotButtonVariant.ghost,
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DrinkSpotButton(
                          label: _saving ? 'Saving…' : 'Save',
                          icon: _saving ? null : Icons.check_rounded,
                          onPressed: _saving ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fieldSubtitle(VenueProfileEditableField field) {
    return switch (field) {
      VenueProfileEditableField.venueName =>
        'This name appears on your public venue profile and search cards.',
      VenueProfileEditableField.category =>
        'Choose the category that best describes your venue.',
      VenueProfileEditableField.address =>
        'Your venue address shown to customers on the map and profile.',
      VenueProfileEditableField.description =>
        'Tell customers what makes your venue special.',
      VenueProfileEditableField.website =>
        'Optional link to your venue website or booking page.',
      VenueProfileEditableField.openingHours =>
        'These times control the Open / Closed status on map and search cards. Use 24-hour time.',
      VenueProfileEditableField.featureTags =>
        'Select up to ${VenueProfileConstants.maxFeatureTags} tags shown on venue cards.',
      VenueProfileEditableField.crowdLevel =>
        'Set the current crowd level for your venue.',
      VenueProfileEditableField.ageRestriction =>
        'Mark whether your venue is restricted to adults aged 18 and over.',
    };
  }

  Widget _buildFieldContent() {
    return switch (widget.field) {
      VenueProfileEditableField.venueName => _buildTextField(
          controller: _textController,
          label: 'Venue name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Venue name is required';
            }
            return null;
          },
        ),
      VenueProfileEditableField.address => _buildTextField(
          controller: _textController,
          label: 'Address',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Address is required';
            }
            return null;
          },
        ),
      VenueProfileEditableField.website => _buildTextField(
          controller: _textController,
          label: 'Website URL',
          keyboardType: TextInputType.url,
          validator: (value) => VenueProfileFieldCodec.validateWebsite(
            value ?? '',
          ),
        ),
      VenueProfileEditableField.description => _buildTextField(
          controller: _multilineController,
          label: 'Description',
          maxLines: 6,
        ),
      VenueProfileEditableField.category => _buildDropdown<String>(
          label: 'Category',
          value: _selectedCategory,
          items: VenueProfileConstants.categories,
          itemLabel: (value) => value,
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
      VenueProfileEditableField.crowdLevel => _buildDropdown<String>(
          label: 'Crowd level',
          value: _selectedCrowdLevel,
          items: VenueProfileConstants.crowdLevels
              .map((option) => option.value)
              .toList(),
          itemLabel: (value) {
            return VenueProfileConstants.crowdLevels
                .firstWhere((option) => option.value == value)
                .label;
          },
          onChanged: (value) => setState(() => _selectedCrowdLevel = value),
        ),
      VenueProfileEditableField.featureTags => _buildFeatureTagsField(),
      VenueProfileEditableField.openingHours => _buildOpeningHoursField(),
      VenueProfileEditableField.ageRestriction => _buildAgeRestrictionField(),
    };
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white),
      decoration: _inputDecoration(label),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T value) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            ),
          )
          .toList(),
      onChanged: _saving ? null : onChanged,
      dropdownColor: AppColors.surface,
      decoration: _inputDecoration(label),
      validator: (value) => value == null ? '$label is required' : null,
    );
  }

  Widget _buildFeatureTagsField() {
    final existingCount = widget.venue.featureTags.length;
    final trimmedExisting = existingCount > VenueProfileConstants.maxFeatureTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trimmedExisting)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              'Only ${VenueProfileConstants.maxFeatureTags} tags can be shown on venue cards.',
              style: TextStyle(
                color: AppColors.trailGold.withValues(alpha: 0.95),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: VenueProfileConstants.featureTagOptions.entries.map((entry) {
            final selected = _selectedFeatureKeys.contains(entry.key);
            final atLimit =
                !selected &&
                _selectedFeatureKeys.length >= VenueProfileConstants.maxFeatureTags;

            return FilterChip(
              label: Text(entry.value),
              selected: selected,
              onSelected: _saving
                  ? null
                  : (value) {
                      setState(() {
                        if (value) {
                          if (_selectedFeatureKeys.length >=
                              VenueProfileConstants.maxFeatureTags) {
                            return;
                          }
                          _selectedFeatureKeys.add(entry.key);
                        } else {
                          _selectedFeatureKeys.remove(entry.key);
                        }
                      });
                    },
              selectedColor: AppColors.primaryPurple.withValues(alpha: 0.35),
              checkmarkColor: AppColors.white,
              disabledColor: AppColors.surface.withValues(alpha: 0.4),
              labelStyle: TextStyle(
                color: atLimit && !selected
                    ? AppColors.textSecondary.withValues(alpha: 0.55)
                    : AppColors.white,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.primaryPink.withValues(alpha: 0.55)
                    : AppColors.glassBorder,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '${_selectedFeatureKeys.length}/${VenueProfileConstants.maxFeatureTags} selected',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.85),
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAgeRestrictionField() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text(
        '18+ venue',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Show an age restriction badge on your public venue profile.',
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.9),
          fontSize: 13,
        ),
      ),
      value: _ageRestricted,
      activeThumbColor: AppColors.primaryPink,
      onChanged: _saving
          ? null
          : (value) => setState(() => _ageRestricted = value),
    );
  }

  Widget _buildOpeningHoursField() {
    return Column(
      children: [
        for (final day in VenueProfileConstants.openingDayKeys) ...[
          _OpeningHoursRow(
            dayLabel: VenueProfileConstants.openingDayLabels[day] ?? day,
            isClosed: _closedDays[day] ?? false,
            openController: _openControllers[day]!,
            closeController: _closeControllers[day]!,
            enabled: !_saving,
            onClosedChanged: (value) => setState(() => _closedDays[day] = value),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
      filled: true,
      fillColor: AppColors.surfaceElevated.withValues(alpha: 0.78),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: AppColors.primaryPurple.withValues(alpha: 0.18),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: AppColors.primaryPink.withValues(alpha: 0.65),
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        borderSide: BorderSide(
          color: AppColors.primaryPink.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

class _OpeningHoursRow extends StatelessWidget {
  const _OpeningHoursRow({
    required this.dayLabel,
    required this.isClosed,
    required this.openController,
    required this.closeController,
    required this.enabled,
    required this.onClosedChanged,
  });

  final String dayLabel;
  final bool isClosed;
  final TextEditingController openController;
  final TextEditingController closeController;
  final bool enabled;
  final ValueChanged<bool> onClosedChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            dayLabel,
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: TextFormField(
            controller: openController,
            enabled: enabled && !isClosed,
            inputFormatters: const [_TimeTextInputFormatter()],
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              labelText: 'Open',
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextFormField(
            controller: closeController,
            enabled: enabled && !isClosed,
            inputFormatters: const [_TimeTextInputFormatter()],
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(
              labelText: 'Close',
              isDense: true,
            ),
          ),
        ),
        Switch(
          value: isClosed,
          onChanged: enabled ? onClosedChanged : null,
          activeThumbColor: AppColors.primaryPink,
        ),
        const SizedBox(width: AppSpacing.xs),
        const Text(
          'Closed',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _TimeTextInputFormatter extends TextInputFormatter {
  const _TimeTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;

    var formatted = limited;
    if (limited.length > 2) {
      formatted = '${limited.substring(0, 2)}:${limited.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
