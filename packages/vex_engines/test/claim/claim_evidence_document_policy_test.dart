import 'package:test/test.dart';
import 'package:vex_engines/claim/application/claim_evidence_document_policy.dart';
import 'package:vex_engines/claim/domain/claim_result.dart';

void main() {
  const policy = ClaimEvidenceDocumentPolicy();

  test('accepts supported pdf evidence files', () {
    final result = policy.validateFile(
      bytes: [1, 2, 3],
      fileName: 'registration.pdf',
    );

    expect(result, isA<ClaimSuccess<({String extension, String contentType})>>());
  });

  test('rejects unsupported file types', () {
    final result = policy.validateFile(
      bytes: [1, 2, 3],
      fileName: 'notes.txt',
    );

    expect(result, isA<ClaimFailure<({String extension, String contentType})>>());
  });

  test('rejects oversized files', () {
    final result = policy.validateFile(
      bytes: List.filled(11 * 1024 * 1024, 1),
      fileName: 'large.pdf',
    );

    expect(result, isA<ClaimFailure<({String extension, String contentType})>>());
  });
}
