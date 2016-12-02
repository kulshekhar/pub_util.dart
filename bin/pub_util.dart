import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;

const PUB_API_BASE_URL = 'https://pub.dartlang.org/api';
final pub = Platform.environment['PUB_EXECUTABLE'] == null ||
        Platform.environment['PUB_EXECUTABLE'] == ''
    ? 'pub'
    : Platform.environment['PUB_EXECUTABLE'];
final dartDir = Platform.environment['DART_DIR'] ?? '';

main(List<String> args) {
  final parser = new ArgParser();

  parser.addFlag('outdated',
      abbr: 'o', negatable: false, help: 'List all outdated packages');
  parser.addFlag('list',
      abbr: 'l', negatable: false, help: 'List all installed packages');
  parser.addFlag('update',
      abbr: 'u', negatable: false, help: 'Update all outdated packages');

  final results = parser.parse(args);
  if (results.arguments.isEmpty) {
    print(parser.usage);
  } else {
    _processGlobal(results);
  }
}

_processGlobal(ArgResults flags) async {
  Iterable<Package> packageList = await _getGlobalPackageList();
  var outdatedCount = 0;

  if (flags['outdated'] || flags['update']) {
    packageList = await _updateWithLatestVersions(packageList);
    outdatedCount = packageList
        .where((p) => p.latest != p.version && p.latest != null)
        .length;

    packageList.forEach((p) {
      final message = '${_logBold(p.name)} ${p.version}' +
          (p.latest != null && p.latest != p.version
              ? ' (${_logRed("update available")})'
              : ' (${_logGreen("latest")})');
      print(message);
    });
    print('You have $outdatedCount outdated packages.');
  } else {
    packageList.forEach((p) {
      print('${_logBold(p.name)} ${p.version}');
    });
  }

  if (flags['update']) {
    _updateOutdatedPackages(packageList);
  } else if (outdatedCount > 0) {
    print('Run "pub_util -u" to update outdated packages');
  }
}

_getGlobalPackageList() async {
  try {
    final results =
        await Process.run(pub, ['global', 'list'], workingDirectory: dartDir);
    if (results.exitCode == 0) {
      return (results.stdout as String).trim().split('\n').map((s) {
        final parts = s.split(' ');

        return new Package(parts[0], parts[1]);
      });
    } else {
      print(
          'An error occurred while running "pub global list"\nError: ${results.stderr}');
    }
  } on ProcessException {
    print('Could not run "pub global list"');
    exit(1);
  }
}

_updateWithLatestVersions(Iterable<Package> packages) async =>
    Future.wait(packages.map((p) async {
      p.latest = await _getLatestPackageVersion(p.name);
      return p;
    }));

_updateOutdatedPackages(Iterable<Package> packages) async {
  packages.forEach((p) async {
    if (p.version != p.latest && p.latest != null) {
      print('Updating ${p.name} from ${p.version} to ${p.latest}');
      try {
        final results = await Process.run(pub, ['global', 'activate', p.name],
            workingDirectory: dartDir);
        if (results.exitCode == 0) {
          print('Updated ${p.name} to ${p.latest}');
        } else {
          print(
              'An error occurred while running "pub global activate ${p.name} "\nError: ${results.stderr}');
        }
      } on ProcessException {
        print('Could not update ${p.name}.');
      }
    }
  });
}

_getLatestPackageVersion(String name) async {
  try {
    final url = '$PUB_API_BASE_URL/packages/$name';

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final parsed = JSON.decode(response.body);
      return parsed['latest']['version'];
    }
  } catch (e) {
    print(e);
  }
}

class Package {
  final String name;
  final String version;
  String latest;

  Package(this.name, this.version);

  @override
  toString() => '$name, current: $version, latest: $latest';
}

String _logBold(String s) => '$_bold$s$_none';
String _logRed(String s) => '$_red$s$_none';
String _logGreen(String s) => '$_green$s$_none';

final _cyan = _format('\u001b[36m');
final _green = _format('\u001b[32m');
final _magenta = _format('\u001b[35m');
final _red = _format('\u001b[31m');
final _yellow = _format('\u001b[33m');
final _blue = _format('\u001b[34m');
final _gray = _format('\u001b[1;30m');
final _none = _format('\u001b[0m');
final _noColor = _format('\u001b[39m');
final _bold = _format('\u001b[1m');

String _format(String formatter) => Platform.isWindows ? '' : formatter;
