@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';

const Map<String, String> packages = const {
  'retrace': '1.0.3',
  'flare': '0.5.0',
};

void main() {
  final pub = Platform.environment['PUB_EXECUTABLE'] == null ||
          Platform.environment['PUB_EXECUTABLE'] == ''
      ? 'pub'
      : Platform.environment['PUB_EXECUTABLE'];
  final dartDir = Platform.environment['DART_DIR'] ?? '';
  final env = {'PUB_EXECUTABLE': pub};
  if (FileSystemEntity.isDirectorySync(dartDir)) {
    env['DART_DIR'] = dartDir;
  }

  group('pub_util', () {
    setUpAll(() {
      packages.forEach((name, version) {
        if (FileSystemEntity.isDirectorySync(dartDir)) {
          Process.runSync(pub, ['global', 'activate', name, version],
              workingDirectory: dartDir);
        } else {
          Process.runSync(pub, ['global', 'activate', name, version]);
        }
      });
    });

    test('should display the flags when run without arguments', () async {
      final result =
          await Process.run('dart', ['bin/pub_util.dart'], environment: env);
      expect(result.exitCode, 0);
      expect(result.stderr, '');
      expect(result.stdout,
          contains('-o, --outdated    List all outdated packages'));
      expect(result.stdout,
          contains('-l, --list        List all installed packages'));
      expect(result.stdout,
          contains('-u, --update      Update all outdated packages'));
    });

    test('should list global packages with the -l flag', () async {
      final result = await Process.run('dart', ['bin/pub_util.dart', '-l'],
          environment: env);

      expect(result.exitCode, 0);
      expect(result.stderr, '');
      packages.forEach((name, version) {
        expect(result.stdout, contains(name));
        expect(result.stdout, contains(version));
      });
    });

    test('should list outdated packages with the -o flag', () async {
      final result = await Process.run(
          'dart', ['bin${Platform.pathSeparator}pub_util.dart', '-o'],
          environment: env);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('update available'));
      expect(result.stdout,
          contains('You have ${packages.length} outdated packages'));
    });

    test('should update outdated packages with the -u flag', () async {
      final result = await Process.run(
          'dart', ['bin${Platform.pathSeparator}pub_util.dart', '-u'],
          environment: env);
      expect(result.exitCode, 0);
      expect(result.stdout,
          contains('You have ${packages.length} outdated packages'));

      packages.forEach((name, version) {
        expect(result.stdout, contains('Updating $name from $version to'));
        expect(result.stdout, contains('Updated $name to'));
      });

      final updatedResult = await Process.run(
          'dart', ['bin${Platform.pathSeparator}pub_util.dart', '-u'],
          environment: env);
      expect(updatedResult.exitCode, 0);
      expect(updatedResult.stderr, '');
      expect(updatedResult.stdout, contains('You have 0 outdated packages'));
    });

    tearDownAll(() {
      packages.keys.forEach((p) {
        if (FileSystemEntity.isDirectorySync(dartDir)) {
          Process.runSync(pub, ['global', 'deactivate', p],
              workingDirectory: dartDir);
        } else {
          Process.runSync(pub, ['global', 'deactivate', p]);
        }
      });
    });
  });
}
