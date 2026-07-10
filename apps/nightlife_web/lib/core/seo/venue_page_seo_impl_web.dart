import 'dart:convert';
import 'dart:html' as html; // ignore: deprecated_member_use, avoid_web_libraries_in_flutter

void applyVenuePageSeo({
  required String venueName,
  required String description,
  required String canonicalPath,
  String? imageUrl,
  String? address,
  String? phone,
  String? website,
  double? rating,
  double? latitude,
  double? longitude,
}) {
  final title = venueName.trim().isEmpty ? 'Venue | Vexda' : '$venueName | Vexda';
  html.document.title = title;

  _setMetaName('description', description);
  _setMetaProperty('og:title', title);
  _setMetaProperty('og:description', description);
  _setMetaProperty('og:type', 'website');
  _setMetaProperty('og:url', _absoluteUrl(canonicalPath));

  if (imageUrl != null && imageUrl.trim().isNotEmpty) {
    _setMetaProperty('og:image', imageUrl);
  }

  _setLinkRel('canonical', _absoluteUrl(canonicalPath));
  _setStructuredData(
    venueName: venueName,
    description: description,
    canonicalPath: canonicalPath,
    imageUrl: imageUrl,
    address: address,
    phone: phone,
    website: website,
    rating: rating,
    latitude: latitude,
    longitude: longitude,
  );
}

void resetVenuePageSeo() {
  html.document.title = 'Vexda';
  html.document.getElementById('vexda-venue-jsonld')?.remove();
}

void _setStructuredData({
  required String venueName,
  required String description,
  required String canonicalPath,
  String? imageUrl,
  String? address,
  String? phone,
  String? website,
  double? rating,
  double? latitude,
  double? longitude,
}) {
  final payload = <String, dynamic>{
    '@context': 'https://schema.org',
    '@type': 'BarOrPub',
    'name': venueName,
    'description': description,
    'url': _absoluteUrl(canonicalPath),
    if (imageUrl != null && imageUrl.isNotEmpty) 'image': imageUrl,
    if (address != null && address.isNotEmpty)
      'address': {
        '@type': 'PostalAddress',
        'streetAddress': address,
      },
    if (phone != null && phone.isNotEmpty) 'telephone': phone,
    if (website != null && website.isNotEmpty) 'sameAs': [website],
    if (rating != null && rating > 0)
      'aggregateRating': {
        '@type': 'AggregateRating',
        'ratingValue': rating.toStringAsFixed(1),
        'bestRating': '5',
      },
    if (latitude != null && longitude != null)
      'geo': {
        '@type': 'GeoCoordinates',
        'latitude': latitude,
        'longitude': longitude,
      },
  };

  html.document.getElementById('vexda-venue-jsonld')?.remove();
  html.document.head?.append(
    html.ScriptElement()
      ..id = 'vexda-venue-jsonld'
      ..type = 'application/ld+json'
      ..text = jsonEncode(payload),
  );
}

void _setMetaName(String name, String content) {
  final element = html.document.querySelector('meta[name="$name"]')
      as html.MetaElement?;
  if (element != null) {
    element.content = content;
    return;
  }

  html.document.head?.append(
    html.MetaElement()
      ..name = name
      ..content = content,
  );
}

void _setMetaProperty(String property, String content) {
  final selector = 'meta[property="$property"]';
  final element = html.document.querySelector(selector) as html.MetaElement?;
  if (element != null) {
    element.content = content;
    return;
  }

  html.document.head?.append(
    html.MetaElement()
      ..setAttribute('property', property)
      ..content = content,
  );
}

void _setLinkRel(String rel, String href) {
  final element = html.document.querySelector('link[rel="$rel"]')
      as html.LinkElement?;
  if (element != null) {
    element.href = href;
    return;
  }

  html.document.head?.append(
    html.LinkElement()
      ..rel = rel
      ..href = href,
  );
}

String _absoluteUrl(String path) {
  final origin = html.window.location.origin;
  if (path.startsWith('http')) return path;
  if (path.startsWith('/')) return '$origin$path';
  return '$origin/$path';
}
