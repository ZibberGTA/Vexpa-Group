/// Firebase-independent metadata for stored documents and media.
final class VexDocumentMetadata {
  const VexDocumentMetadata({
    required this.path,
    required this.ownerId,
    this.contentType,
    this.byteLength,
    this.checksum,
    this.labels = const {},
  });

  final String path;
  final String ownerId;
  final String? contentType;
  final int? byteLength;
  final String? checksum;
  final Map<String, String> labels;
}

/// Reference to a stored document without Firebase types.
final class VexDocumentReference {
  const VexDocumentReference({
    required this.path,
    required this.downloadUrl,
    required this.metadata,
  });

  final String path;
  final Uri downloadUrl;
  final VexDocumentMetadata metadata;
}
