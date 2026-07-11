import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/vexcore/web_vexcore.dart';
import 'package:nightlife_web/features/venue_management/data/venue_media_storage_service.dart';
import 'package:vex_core/vex_core.dart';

void main() {
  tearDown(() {
    WebVexCore.storageOverride = null;
  });

  test('venue media storage delegates to VexCore storage contract', () async {
    final fake = _FakeVexStorage();
    WebVexCore.storageOverride = fake;

    final service = VenueMediaStorageService();
    final result = await service.uploadBytes(
      storagePath: 'venues/v-1/media/logo/logo-1.png',
      bytes: Uint8List.fromList([9, 9, 9]),
      contentType: 'image/png',
    );

    expect(fake.putCalls, 1);
    expect(fake.lastPath, 'venues/v-1/media/logo/logo-1.png');
    expect(result.storagePath, 'venues/v-1/media/logo/logo-1.png');
    expect(result.downloadUrl, contains('logo-1.png'));
  });

  test('venue media delete delegates to VexCore storage contract', () async {
    final fake = _FakeVexStorage();
    WebVexCore.storageOverride = fake;

    final service = VenueMediaStorageService();
    await service.deleteAtPath('venues/v-1/media/logo/logo-1.png');

    expect(fake.deleteCalls, 1);
    expect(fake.deletedPath, 'venues/v-1/media/logo/logo-1.png');
  });
}

final class _FakeVexStorage implements VexStorageService {
  int putCalls = 0;
  int deleteCalls = 0;
  String? lastPath;
  String? deletedPath;

  @override
  Future<Uri> downloadUrl(String path) async {
    return Uri.parse('https://storage.example.com/$path');
  }

  @override
  Future<void> delete(String path) async {
    deleteCalls++;
    deletedPath = path;
  }

  @override
  Future<StorageResult> putBytes({
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    putCalls++;
    lastPath = path;
    return StorageResult(
      path: path,
      downloadUrl: Uri.parse('https://storage.example.com/$path'),
    );
  }
}
