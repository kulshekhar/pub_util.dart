@TestOn('vm')
import 'dart:io';

import 'package:test/test.dart';

const Map<String, String> packages = const {
  'retrace': '1.0.3',
  'flare': '0.5.0',
};

void main() {
  group('pub_util', () {
    setUpAll(() {
      packages.forEach((name, version) {
        final result =
            Process.runSync('pub', ['global', 'activate', name, version]);
        print(result.exitCode);
        print('Error: ${result.stderr}');
        print('Output: ${result.stdout}');
      });
    });

    test('should display the flags when run without arguments', () async {
      final result = await Process.run('dart', ['bin/pub_util.dart']);
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
      final result = await Process.run('dart', ['bin/pub_util.dart', '-l']);
      expect(result.exitCode, 0);
      expect(result.stderr, '');
      packages.forEach((name, version) {
        expect(result.stdout, contains(name));
        expect(result.stdout, contains(version));
      });
    });

    test('should list outdated packages with the -o flag', () async {
      final result = await Process
          .run('dart', ['bin${Platform.pathSeparator}pub_util.dart', '-o']);
      expect(result.exitCode, 0);
      expect(result.stdout, contains('update available'));
      expect(result.stdout,
          contains('You have ${packages.length} outdated packages'));
    });

    test('should update outdated packages with the -u flag', () async {
      final result = await Process
          .run('dart', ['bin${Platform.pathSeparator}pub_util.dart', '-u']);
      expect(result.exitCode, 0);
      expect(result.stdout,
          contains('You have ${packages.length} outdated packages'));

      packages.forEach((name, version) {
        expect(result.stdout, contains('Updating $name from $version to'));
        expect(result.stdout, contains('Updated $name to'));
      });

      final updatedResult = await Process
          .run('dart', ['bin${Platform.pathSeparator}pub_util.dart', '-u']);
      expect(updatedResult.exitCode, 0);
      expect(updatedResult.stderr, '');
      expect(updatedResult.stdout, contains('You have 0 outdated packages'));
    });

    tearDownAll(() {
      packages.keys.forEach((p) {
        Process.run('pub', ['global', 'deactivate', p]);
      });
    });
  });
}
