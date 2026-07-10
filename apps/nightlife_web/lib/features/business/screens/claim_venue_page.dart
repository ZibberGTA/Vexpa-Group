import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/breakpoints.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/drinkspot_button.dart';
import '../../../shared/components/public_page_hero.dart';
import '../../../shared/layouts/content_container.dart';
import '../../../shared/layouts/public_page_shell.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/premium_effects.dart';
import '../../venue_claims/data/venue_claim_repository.dart';
import '../../venue_claims/models/venue_claim.dart';

enum _ClaimFlowStep { options, createVenue, search, claim, draft }

class ClaimVenuePage extends StatefulWidget {
  const ClaimVenuePage({super.key});

  @override
  State<ClaimVenuePage> createState() => _ClaimVenuePageState();
}

class _ClaimVenuePageState extends State<ClaimVenuePage> {
  final _repository = VenueClaimRepository();
  final _searchController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyRegistrationController = TextEditingController();
  final _notesController = TextEditingController();
  final _createNameController = TextEditingController();
  final _createAddressController = TextEditingController();
  final _createCityController = TextEditingController();
  final _createPostcodeController = TextEditingController();
  final _createCategoryController = TextEditingController();
  final _draftDescriptionController = TextEditingController();
  final _draftTagsController = TextEditingController();
  final _draftWebsiteController = TextEditingController();
  final _draftSocialLinksController = TextEditingController();
  final _draftOpeningHoursController = TextEditingController();
  Timer? _searchDebounce;

  _ClaimFlowStep _step = _ClaimFlowStep.options;
  List<VenueClaimSearchResult> _searchResults = const [];
  VenueClaimSearchResult? _selectedVenue;
  VenueClaimSubmissionResult? _submission;
  String? _activeDraftClaimId;
  bool _searching = false;
  bool _searchCompleted = false;
  String? _searchError;
  int _searchRequestId = 0;
  bool _submitting = false;
  bool _showWizard = true;
  String? _message;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _businessEmailController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _companyRegistrationController.dispose();
    _notesController.dispose();
    _createNameController.dispose();
    _createAddressController.dispose();
    _createCityController.dispose();
    _createPostcodeController.dispose();
    _createCategoryController.dispose();
    _draftDescriptionController.dispose();
    _draftTagsController.dispose();
    _draftWebsiteController.dispose();
    _draftSocialLinksController.dispose();
    _draftOpeningHoursController.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String value) async {
    _searchDebounce?.cancel();
    final trimmed = value.trim();

    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _searching = false;
        _searchCompleted = false;
        _searchError = null;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 260), () async {
      final requestId = ++_searchRequestId;
      if (!mounted) return;
      setState(() {
        _searching = true;
        _searchCompleted = false;
        _searchError = null;
      });

      final response = await _repository.searchVenues(trimmed);
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _searching = false;
        _searchCompleted = true;
        if (response.success) {
          _searchResults = response.results;
          _searchError = null;
        } else {
          _searchResults = const [];
          _searchError =
              response.errorMessage ?? 'Venue search failed. Please try again.';
        }
      });
    });
  }

  Future<void> _submitClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    final venue = _selectedVenue;
    if (user == null) {
      Navigator.pushNamed(context, AppRouter.login);
      return;
    }
    if (venue == null) return;

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      final result = await _repository.submitClaim(
        user: user,
        venue: venue,
        evidence: VenueClaimEvidence(
          businessEmail: _businessEmailController.text,
          website: _websiteController.text,
          phone: _phoneController.text,
          companyRegistration: _companyRegistrationController.text,
          notes: _notesController.text,
        ),
      );
      if (!mounted) return;
      _primeDraftFromVenue(venue);
      if (result.autoApproved) {
        Navigator.pushNamed(context, AppRouter.venueDashboard);
        return;
      }
      setState(() {
        _submission = result;
        _activeDraftClaimId = result.claimId;
        _step = _ClaimFlowStep.draft;
        _message = 'Claim submitted. You can start setting up your draft now.';
      });
    } on VenueClaimBackendException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = 'Claim could not be submitted. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _createVenue() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, AppRouter.login);
      return;
    }
    if (_createNameController.text.trim().isEmpty) {
      setState(() => _message = 'Enter a venue name to continue.');
      return;
    }

    setState(() {
      _submitting = true;
      _message = null;
    });

    try {
      final venueId = await _repository.createVenueInstant(
        user: user,
        name: _createNameController.text,
        address: _createAddressController.text,
        city: _createCityController.text,
        postcode: _createPostcodeController.text,
        category: _createCategoryController.text,
        website: _websiteController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      setState(() {
        _submission = VenueClaimSubmissionResult(
          claimId: '',
          venueId: venueId,
          status: VenueClaimStatus.completed,
          autoApproved: true,
        );
        _step = _ClaimFlowStep.draft;
        _message = 'Venue created. Welcome to your setup workspace.';
      });
    } on VenueClaimBackendException catch (error) {
      if (!mounted) return;
      setState(() => _message = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _message = 'Venue could not be created. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _saveDraft() async {
    final user = FirebaseAuth.instance.currentUser;
    final claimId = _activeDraftClaimId;
    if (user == null || claimId == null || claimId.isEmpty) return;
    await _repository.saveDraft(
      claimId: claimId,
      claimantUid: user.uid,
      draftVenueData: _draftData(),
    );
    if (!mounted) return;
    setState(
      () => _message =
          'Draft saved. It will publish automatically when approved.',
    );
  }

  void _primeDraftFromVenue(VenueClaimSearchResult venue) {
    _draftWebsiteController.text = _websiteController.text.trim().isEmpty
        ? venue.website
        : _websiteController.text.trim();
    _draftDescriptionController.text = (venue.rawData['description'] ?? '')
        .toString();
  }

  Map<String, dynamic> _draftData() {
    return {
      'description': _draftDescriptionController.text.trim(),
      'website': _draftWebsiteController.text.trim(),
      'websiteUrl': _draftWebsiteController.text.trim(),
      'featureTags': _draftTagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(),
      'socialLinks': {'notes': _draftSocialLinksController.text.trim()},
      'openingHoursDraft': _draftOpeningHoursController.text.trim(),
      'draftChecklist': {
        'logo': false,
        'banner': false,
        'openingHours': _draftOpeningHoursController.text.trim().isNotEmpty,
        'description': _draftDescriptionController.text.trim().isNotEmpty,
        'drinks': false,
        'deals': false,
        'events': false,
        'website': _draftWebsiteController.text.trim().isNotEmpty,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return PublicPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PublicPageHero(
            eyebrow: 'Venue onboarding',
            title: 'Claim or create your venue',
            subtitle:
                'Start setting up immediately. If approval is needed, your work is saved as a private draft and published automatically later.',
            trailing: DrinkSpotButton(
              label: 'Venue Dashboard',
              icon: Icons.dashboard_rounded,
              variant: DrinkSpotButtonVariant.secondary,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.venueDashboard),
            ),
          ),
          ContentContainer(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_message != null) ...[
                    _StatusBanner(message: _message!),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  AnimatedSwitcher(
                    duration: PremiumEffects.medium,
                    child: switch (_step) {
                      _ClaimFlowStep.options => _buildOptions(),
                      _ClaimFlowStep.createVenue => _buildCreateVenue(),
                      _ClaimFlowStep.search => _buildSearch(),
                      _ClaimFlowStep.claim => _buildClaimForm(),
                      _ClaimFlowStep.draft => _buildDraftWorkspace(),
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoColumns = constraints.maxWidth >= 760;
        final cards = [
          _OnboardingOptionCard(
            icon: Icons.add_business_rounded,
            title: 'Create New Venue',
            subtitle:
                'Create a new Starter venue instantly, then jump straight into setup.',
            steps: const [
              'Create Venue',
              'Starter minimum',
              'Welcome Wizard',
              'Dashboard',
            ],
            buttonLabel: 'Create Venue',
            onPressed: () => setState(() => _step = _ClaimFlowStep.createVenue),
          ),
          _OnboardingOptionCard(
            icon: Icons.verified_user_rounded,
            title: 'Claim Existing Venue',
            subtitle:
                'Find your listing, verify ownership and start editing a private draft immediately.',
            steps: const [
              'Search venue',
              'Submit claim',
              'Draft workspace',
              'Auto publish',
            ],
            buttonLabel: 'Claim Venue',
            onPressed: () => setState(() => _step = _ClaimFlowStep.search),
          ),
        ];
        if (!twoColumns) {
          return Column(
            children: [
              for (final card in cards) ...[
                card,
                const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: AppSpacing.xl),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }

  Widget _buildCreateVenue() {
    return _FlowPanel(
      title: 'Create New Venue',
      subtitle:
          'Starter is the minimum plan for new venue setup. Stripe is not part of this phase.',
      onBack: () => setState(() => _step = _ClaimFlowStep.options),
      child: Column(
        children: [
          _ResponsiveFieldGrid(
            children: [
              _ClaimTextField(
                controller: _createNameController,
                label: 'Venue name',
              ),
              _ClaimTextField(
                controller: _createCategoryController,
                label: 'Category',
              ),
              _ClaimTextField(
                controller: _createAddressController,
                label: 'Address',
              ),
              _ClaimTextField(
                controller: _createCityController,
                label: 'Town / city',
              ),
              _ClaimTextField(
                controller: _createPostcodeController,
                label: 'Postcode',
              ),
              _ClaimTextField(controller: _websiteController, label: 'Website'),
              _ClaimTextField(
                controller: _phoneController,
                label: 'Phone number',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: DrinkSpotButton(
              label: _submitting ? 'Creating...' : 'Create Venue',
              icon: Icons.add_business_rounded,
              onPressed: _submitting ? null : _createVenue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return _FlowPanel(
      title: 'Find your venue',
      subtitle: 'Search by venue name, postcode, town or address.',
      onBack: () => setState(() => _step = _ClaimFlowStep.options),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ClaimTextField(
            controller: _searchController,
            label: 'Search venues',
            icon: Icons.search_rounded,
            onChanged: _runSearch,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_searchController.text.trim().length < 2)
            const _SearchHintCard()
          else if (_searching)
            const _SkeletonList()
          else if (_searchError != null)
            _SearchErrorCard(message: _searchError!)
          else if (_searchCompleted && _searchResults.isEmpty)
            const _EmptyStateCard()
          else if (_searchResults.isNotEmpty)
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: _searchResults
                  .map(
                    (venue) => _VenueSearchCard(
                      venue: venue,
                      onClaim: () {
                        _selectedVenue = venue;
                        _websiteController.text = venue.website;
                        _phoneController.text = venue.phone;
                        setState(() => _step = _ClaimFlowStep.claim);
                      },
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildClaimForm() {
    final venue = _selectedVenue;
    if (venue == null) return _buildSearch();

    return _FlowPanel(
      title: 'Claim ${venue.name}',
      subtitle:
          'Vexda attempts instant verification whenever possible. If manual review is needed, your setup work is saved privately as a draft.',
      onBack: () => setState(() => _step = _ClaimFlowStep.search),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _VenueSummaryCard(venue: venue),
          const SizedBox(height: AppSpacing.lg),
          _ResponsiveFieldGrid(
            children: [
              _ClaimTextField(
                controller: _businessEmailController,
                label: 'Business email',
                icon: Icons.alternate_email_rounded,
              ),
              _ClaimTextField(
                controller: _websiteController,
                label: 'Website',
                icon: Icons.public_rounded,
              ),
              _ClaimTextField(
                controller: _phoneController,
                label: 'Phone number',
                icon: Icons.phone_rounded,
              ),
              _ClaimTextField(
                controller: _companyRegistrationController,
                label: 'Company registration (optional)',
                icon: Icons.apartment_rounded,
              ),
              _ClaimTextField(
                controller: _notesController,
                label: 'Additional notes / location verification',
                icon: Icons.notes_rounded,
                maxLines: 4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _EvidenceExplainer(),
          const SizedBox(height: AppSpacing.xl),
          Align(
            alignment: Alignment.centerLeft,
            child: DrinkSpotButton(
              label: _submitting ? 'Submitting...' : 'Submit Claim',
              icon: Icons.verified_rounded,
              onPressed: _submitting ? null : _submitClaim,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftWorkspace() {
    final autoApproved = _submission?.autoApproved == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showWizard) ...[
          _WelcomeWizard(onStart: () => setState(() => _showWizard = false)),
          const SizedBox(height: AppSpacing.xl),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = Breakpoints.isDesktop(context);
            final editor = _DraftEditor(
              descriptionController: _draftDescriptionController,
              tagsController: _draftTagsController,
              websiteController: _draftWebsiteController,
              socialLinksController: _draftSocialLinksController,
              openingHoursController: _draftOpeningHoursController,
              canSaveDraft: !autoApproved && _activeDraftClaimId != null,
              onSaveDraft: _saveDraft,
              onOpenDashboard: autoApproved
                  ? () => Navigator.pushNamed(context, AppRouter.venueDashboard)
                  : null,
            );
            final checklist = _SetupChecklist(data: _draftData());
            if (!sideBySide) {
              return Column(
                children: [
                  checklist,
                  const SizedBox(height: AppSpacing.lg),
                  editor,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: editor),
                const SizedBox(width: AppSpacing.xl),
                Expanded(flex: 2, child: checklist),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _FlowPanel extends StatelessWidget {
  const _FlowPanel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onBack != null) ...[
                IconButton(
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _OnboardingOptionCard extends StatefulWidget {
  const _OnboardingOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.steps,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> steps;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  State<_OnboardingOptionCard> createState() => _OnboardingOptionCardState();
}

class _OnboardingOptionCardState extends State<_OnboardingOptionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: PremiumEffects.fast,
        scale: _hovered ? 1.015 : 1,
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderRadius: AppSpacing.radiusLg,
          elevation: _hovered ? GlassElevation.medium : GlassElevation.soft,
          innerHighlight: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GradientIcon(icon: widget.icon),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final step in widget.steps)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primaryPink,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              DrinkSpotButton(
                label: widget.buttonLabel,
                icon: Icons.arrow_forward_rounded,
                onPressed: widget.onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveFieldGrid extends StatelessWidget {
  const _ResponsiveFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 720
            ? (constraints.maxWidth - AppSpacing.lg) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _ClaimTextField extends StatelessWidget {
  const _ClaimTextField({
    required this.controller,
    required this.label,
    this.icon,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: AppColors.primaryPink, size: 18),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surfaceElevated.withValues(alpha: 0.74),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(
            color: AppColors.primaryPurple.withValues(alpha: 0.22),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primaryPink),
        ),
      ),
    );
  }
}

class _VenueSearchCard extends StatelessWidget {
  const _VenueSearchCard({required this.venue, required this.onClaim});

  final VenueClaimSearchResult venue;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: AppSpacing.radiusLg,
        elevation: GlassElevation.soft,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 118,
                decoration: BoxDecoration(
                  gradient: AppColors.surfaceGradient,
                  image: venue.bannerUrl.isEmpty
                      ? null
                      : DecorationImage(
                          image: NetworkImage(venue.bannerUrl),
                          fit: BoxFit.cover,
                        ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.surfaceElevated,
                      backgroundImage: venue.logoUrl.isEmpty
                          ? null
                          : NetworkImage(venue.logoUrl),
                      child: venue.logoUrl.isEmpty
                          ? const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.white,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      venue.displayAddress,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _Pill(label: venue.category),
                        _Pill(label: venue.claimStatusLabel),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DrinkSpotButton(
                      label: 'Claim Venue',
                      icon: Icons.verified_user_outlined,
                      compact: true,
                      onPressed: onClaim,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueSummaryCard extends StatelessWidget {
  const _VenueSummaryCard({required this.venue});

  final VenueClaimSearchResult venue;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderRadius: AppSpacing.radiusMd,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.surfaceElevated,
            backgroundImage: venue.logoUrl.isEmpty
                ? null
                : NetworkImage(venue.logoUrl),
            child: venue.logoUrl.isEmpty
                ? const Icon(Icons.storefront_rounded, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venue.name,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  venue.displayAddress,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvidenceExplainer extends StatelessWidget {
  const _EvidenceExplainer();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('High', 'Business email matches domain'),
      ('High', 'Website or registration matches'),
      ('Medium', 'Phone matches existing listing'),
      ('Low', 'Location verification notes'),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items
          .map((item) => _Pill(label: '${item.$1}: ${item.$2}'))
          .toList(),
    );
  }
}

class _WelcomeWizard extends StatefulWidget {
  const _WelcomeWizard({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_WelcomeWizard> createState() => _WelcomeWizardState();
}

class _WelcomeWizardState extends State<_WelcomeWizard> {
  int _index = 0;

  static const _slides = [
    (
      'Welcome to Vexda',
      'Grow your venue, not just manage it.',
      Icons.rocket_launch_rounded,
    ),
    (
      'Drinks',
      'Customers search for drinks. Keep your menu updated.',
      Icons.local_bar_rounded,
    ),
    (
      'Deals & Events',
      'Promote what makes tonight worth visiting.',
      Icons.local_offer_rounded,
    ),
    ('Analytics', 'See what attracts customers.', Icons.insights_rounded),
    (
      'Let’s Set Up Your Venue',
      'Start setup and publish-ready work now.',
      Icons.task_alt_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    final isLast = _index == _slides.length - 1;
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.medium,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GradientIcon(icon: slide.$3),
          const SizedBox(height: AppSpacing.lg),
          Text(
            slide.$1,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.$2,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              for (var i = 0; i < _slides.length; i++)
                Container(
                  width: i == _index ? 22 : 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    color: i == _index
                        ? AppColors.primaryPink
                        : AppColors.white.withValues(alpha: 0.16),
                  ),
                ),
              const Spacer(),
              DrinkSpotButton(
                label: isLast ? 'Start Setup' : 'Next',
                compact: true,
                onPressed: () {
                  if (isLast) {
                    widget.onStart();
                    return;
                  }
                  setState(() => _index += 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DraftEditor extends StatelessWidget {
  const _DraftEditor({
    required this.descriptionController,
    required this.tagsController,
    required this.websiteController,
    required this.socialLinksController,
    required this.openingHoursController,
    required this.canSaveDraft,
    required this.onSaveDraft,
    this.onOpenDashboard,
  });

  final TextEditingController descriptionController;
  final TextEditingController tagsController;
  final TextEditingController websiteController;
  final TextEditingController socialLinksController;
  final TextEditingController openingHoursController;
  final bool canSaveDraft;
  final VoidCallback onSaveDraft;
  final VoidCallback? onOpenDashboard;

  @override
  Widget build(BuildContext context) {
    return _FlowPanel(
      title: 'Draft Workspace',
      subtitle:
          'Edit your setup now. Pending claims keep this private until approval publishes it.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveFieldGrid(
            children: [
              _ClaimTextField(
                controller: descriptionController,
                label: 'Description',
                maxLines: 4,
              ),
              _ClaimTextField(
                controller: openingHoursController,
                label: 'Opening hours notes',
                maxLines: 4,
              ),
              _ClaimTextField(
                controller: tagsController,
                label: 'Tags (comma separated)',
              ),
              _ClaimTextField(controller: websiteController, label: 'Website'),
              _ClaimTextField(
                controller: socialLinksController,
                label: 'Social links',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: const [
              _Pill(label: 'Logo placeholder'),
              _Pill(label: 'Banner placeholder'),
              _Pill(label: 'Drinks draft'),
              _Pill(label: 'Deals draft'),
              _Pill(label: 'Events draft'),
              _Pill(label: 'Gallery placeholders'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              DrinkSpotButton(
                label: 'Save Draft',
                icon: Icons.save_outlined,
                onPressed: canSaveDraft ? onSaveDraft : null,
              ),
              if (onOpenDashboard != null)
                DrinkSpotButton(
                  label: 'Open Dashboard',
                  icon: Icons.dashboard_rounded,
                  variant: DrinkSpotButtonVariant.secondary,
                  onPressed: onOpenDashboard,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupChecklist extends StatelessWidget {
  const _SetupChecklist({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final checklist = data['draftChecklist'] is Map
        ? Map<String, dynamic>.from(data['draftChecklist'] as Map)
        : const <String, dynamic>{};
    final items = [
      ('Logo', checklist['logo'] == true),
      ('Banner', checklist['banner'] == true),
      ('Opening Hours', checklist['openingHours'] == true),
      ('Description', checklist['description'] == true),
      ('Drinks', checklist['drinks'] == true),
      ('Deals', checklist['deals'] == true),
      ('Events', checklist['events'] == true),
      ('Website', checklist['website'] == true),
    ];
    final completed = items.where((item) => item.$2).length;
    final percent = (completed / items.length * 100).round();

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      borderRadius: AppSpacing.radiusLg,
      elevation: GlassElevation.soft,
      innerHighlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Setup',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$percent% Complete',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.08),
              color: AppColors.primaryPink,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final item in items)
            _ChecklistRow(
              label: item.$1,
              state: item.$2
                  ? 'Completed'
                  : (item.$1 == 'Description' || item.$1 == 'Website'
                        ? 'In Progress'
                        : 'Not Started'),
              completed: item.$2,
            ),
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.label,
    required this.state,
    required this.completed,
  });

  final String label;
  final String state;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: completed ? AppColors.primaryPink : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.white)),
          ),
          Text(
            state,
            style: TextStyle(
              color: completed
                  ? AppColors.primaryPink
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppSpacing.radiusMd,
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        boxShadow: PremiumEffects.hoverGlow(intensity: 0.5),
      ),
      child: Icon(icon, color: AppColors.white),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.26),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SearchHintCard extends StatelessWidget {
  const _SearchHintCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Text(
        'Type at least 2 characters to search by venue name, postcode, town or address.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.45),
      ),
    );
  }
}

class _SearchErrorCard extends StatelessWidget {
  const _SearchErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.primaryPink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.white, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: List.generate(
        3,
        (_) => Container(
          width: 340,
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return const GlassContainer(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Text(
        'No venues matched that search. Try a postcode, town or address.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
