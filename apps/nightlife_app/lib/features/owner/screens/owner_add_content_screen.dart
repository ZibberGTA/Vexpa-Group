import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/home_icon_button.dart';
import '../../../core/widgets/premium_scaffold.dart';
import '../../auth/services/auth_service.dart';
import '../../home/models/venue_model.dart';
import '../../home/services/venue_service.dart';
import '../../venues/screens/add_event_screen.dart';
import 'add_deal_screen.dart';
import 'add_drink_screen.dart';

class OwnerAddContentScreen extends StatefulWidget {
  const OwnerAddContentScreen({super.key});

  @override
  State<OwnerAddContentScreen> createState() => _OwnerAddContentScreenState();
}

enum _ContentType {
  drink,
  deal,
  event,
}

class _OwnerAddContentScreenState extends State<OwnerAddContentScreen> {
  _ContentType? _selectedType;

  String get _title {
    switch (_selectedType) {
      case _ContentType.drink:
        return 'Choose venue for drink';
      case _ContentType.deal:
        return 'Choose venue for deal';
      case _ContentType.event:
        return 'Choose venue for event';
      case null:
        return 'Add content';
    }
  }

  String get _subtitle {
    switch (_selectedType) {
      case _ContentType.drink:
        return 'Select the venue this drink belongs to.';
      case _ContentType.deal:
        return 'Select the venue this deal belongs to.';
      case _ContentType.event:
        return 'Select the venue this event belongs to.';
      case null:
        return 'Create drinks, deals and events for your venues.';
    }
  }

  void _openContentScreen(VenueModel venue) {
    final selectedType = _selectedType;
    if (selectedType == null) return;

    Widget screen;
    switch (selectedType) {
      case _ContentType.drink:
        screen = AddDrinkScreen(venue: venue);
        break;
      case _ContentType.deal:
        screen = AddDealScreen(venue: venue);
        break;
      case _ContentType.event:
        screen = AddEventScreen(
          venueId: venue.id,
          venueName: venue.name,
        );
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const PremiumScaffold(
        body: Center(child: Text('Not logged in')),
      );
    }

    return PremiumScaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: const [HomeIconButton()],
      ),
      body: StreamBuilder<List<VenueModel>>(
        stream: VenueService.getVenuesForOwner(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Could not load venues: ${snapshot.error}'));
          }

          final venues = snapshot.data ?? [];

          return ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + 28,
            ),
            children: [
              _HeaderCard(
                title: _title,
                subtitle: _subtitle,
                selectedType: _selectedType,
                onReset: _selectedType == null
                    ? null
                    : () => setState(() => _selectedType = null),
              ),
              const SizedBox(height: 16),
              if (_selectedType == null) ...[
                _ContentTypeCard(
                  icon: Icons.local_bar_rounded,
                  title: 'New Drink',
                  subtitle: 'Add cocktails, bottles, mixers or menu drinks.',
                  accentColor: AppColors.primaryPink,
                  onTap: () => setState(() => _selectedType = _ContentType.drink),
                ),
                const SizedBox(height: 12),
                _ContentTypeCard(
                  icon: Icons.local_offer_rounded,
                  title: 'New Deal',
                  subtitle: 'Create happy hours, offers and promotions.',
                  accentColor: AppColors.primaryPurple,
                  onTap: () => setState(() => _selectedType = _ContentType.deal),
                ),
                const SizedBox(height: 12),
                _ContentTypeCard(
                  icon: Icons.event_rounded,
                  title: 'New Event',
                  subtitle: 'Promote DJ nights, live music and themed events.',
                  accentColor: const Color(0xFF25D6FF),
                  onTap: () => setState(() => _selectedType = _ContentType.event),
                ),
              ] else ...[
                if (venues.isEmpty)
                  const _EmptyVenueCard()
                else ...[
                  const _SectionLabel('Select venue'),
                  const SizedBox(height: 10),
                  ...venues.map(
                    (venue) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _VenueSelectCard(
                        venue: venue,
                        onTap: () => _openContentScreen(venue),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.subtitle,
    required this.selectedType,
    required this.onReset,
  });

  final String title;
  final String subtitle;
  final _ContentType? selectedType;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purpleDark.withOpacity(0.92),
            AppColors.purple.withOpacity(0.70),
            const Color(0xFF1E2030).withOpacity(0.66),
          ],
        ),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.16),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add_business_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.74),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onReset != null) ...[
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: 'Change type',
              onPressed: onReset,
              icon: const Icon(Icons.swap_horiz_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContentTypeCard extends StatelessWidget {
  const _ContentTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2030).withOpacity(0.60),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accentColor.withOpacity(0.38)),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: accentColor.withOpacity(0.40)),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.66),
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _VenueSelectCard extends StatelessWidget {
  const _VenueSelectCard({
    required this.venue,
    required this.onTap,
  });

  final VenueModel venue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 142,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFF181925),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primaryPurple.withOpacity(0.34)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (venue.bannerImageUrl.isNotEmpty)
              Image.network(
                venue.bannerImageUrl,
                fit: BoxFit.cover,
                cacheWidth: 900,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.18),
                    Colors.black.withOpacity(0.82),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _VenueLogo(venue: venue),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.54),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.white.withOpacity(0.16)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Select',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    venue.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    venue.category.isEmpty ? 'Venue listing' : venue.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.76),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueLogo extends StatelessWidget {
  const _VenueLogo({required this.venue});

  final VenueModel venue;

  @override
  Widget build(BuildContext context) {
    if (venue.logoUrl.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.48),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            venue.logoUrl,
            fit: BoxFit.cover,
            cacheWidth: 160,
            errorBuilder: (_, __, ___) => _InitialBubble(name: venue.name),
          ),
        ),
      );
    }

    return _InitialBubble(name: venue.name);
  }
}

class _InitialBubble extends StatelessWidget {
  const _InitialBubble({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.48),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _EmptyVenueCard extends StatelessWidget {
  const _EmptyVenueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030).withOpacity(0.60),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryPurple.withOpacity(0.26)),
      ),
      child: const Column(
        children: [
          Icon(Icons.storefront_rounded, size: 42),
          SizedBox(height: 12),
          Text(
            'No venues yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'Add a venue first before creating drinks, deals or events.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
