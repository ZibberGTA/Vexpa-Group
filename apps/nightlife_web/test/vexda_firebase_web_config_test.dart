import 'package:flutter_test/flutter_test.dart';
import 'package:nightlife_web/core/firebase/vexda_firebase_web_config.dart';

void main() {
  test('registered plugin inventory maps to required module globals', () {
    expect(kVexdaFirebaseWebModules, hasLength(5));
    expect(
      kVexdaFirebaseWebModules.map((module) => module.serviceName).toList(),
      ['core', 'auth', 'firestore', 'storage', 'functions'],
    );
    expect(
      kVexdaFirebaseWebModules.map((module) => module.windowGlobal).toList(),
      [
        'firebase_core',
        'firebase_auth',
        'firebase_firestore',
        'firebase_storage',
        'firebase_functions',
      ],
    );
  });

  test('ignore scripts cover every registered service', () {
    expect(
      kVexdaFlutterFireIgnoreScripts,
      ['core', 'auth', 'firestore', 'storage', 'functions'],
    );
  });

  test('module graph URLs use one SDK version', () {
    for (final module in kVexdaFirebaseWebModules) {
      final url = vexdaFirebaseModuleGraphUrl(
        kVexdaFirebaseJsSdkVersion,
        module.scriptFileName,
      );
      expect(url, contains('/$kVexdaFirebaseJsSdkVersion/'));
      expect(url, isNot(contains('AIza')));
    }
  });

  test('diagnostics config contains no secrets', () {
    for (final module in kVexdaFirebaseWebModules) {
      expect(module.windowGlobal, isNot(contains('@')));
      expect(module.scriptFileName, isNot(contains('AIza')));
    }
    expect(kVexdaFirebaseJsSdkVersion, '11.9.1');
  });
}
