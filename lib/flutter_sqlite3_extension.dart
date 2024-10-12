// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

bool verbose = false;

Future<void> create(
  String source,
  String name, {
  bool debug = false,
}) async {
  verbose = debug;
  final desc = name.substring(0, name.length - 2);
  await run('flutter', [
    'create',
    '-t',
    'plugin_ffi',
    '--platforms=ios,android,macos,windows,linux',
    '--project-name=$desc',
    desc,
  ]);
  final dir = Directory(desc);
  final data = await File(source).readAsString();
  await writeFile(
    p.join(dir.path, 'Makefile'),
    makeFile,
  );
  await writeFile(
    p.join(dir.path, 'src', 'CMakeLists.txt'),
    cmakeList.replaceAll('{{name}}', desc),
  );
  await writeFile(
    p.join(dir.path, 'src', '$desc.c'),
    data,
  );
  await deleteFile(
    p.join(dir.path, 'src', '$desc.h'),
  );
  await deleteFile(
    p.join(dir.path, 'ffigen.yaml'),
  );
  await deleteFile(
    p.join(dir.path, 'lib', '${desc}_bindings_generated.dart'),
  );
  await writeFile(
    p.join(dir.path, 'lib', '$desc.dart'),
    packageFile.replaceAll('{{name}}', desc),
  );
  await writeFile(
    p.join(dir.path, 'example', 'pubspec.yaml'),
    examplePubspec.replaceAll('{{name}}', desc),
  );
  await writeFile(
    p.join(dir.path, 'example', 'lib', 'main.dart'),
    exampleCode.replaceAll('{{name}}', desc),
  );
  await run(
    'make',
    ['init'],
    workingDirectory: desc,
  );
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  await file.delete();
}

Future<void> writeFile(String path, String contents) async {
  final file = File(path);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  await file.writeAsString(contents);
}

Future<bool> run(
  String command,
  List<String> args, {
  String? workingDirectory,
}) async {
  if (verbose) {
    print('running: $command ${args.join(' ')}');
  }
  final result = await Process.run(
    command,
    args,
    workingDirectory: workingDirectory,
  );
  if (verbose) {
    result.stdout.transform(utf8.decoder).forEach(print);
  }
  if (result.exitCode != 0) {
    print(result.stderr);
  }
  return result.exitCode == 0;
}

const cmakeList = r'''
# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project({{name}}_library VERSION 0.0.1 LANGUAGES C)

add_library({{name}} SHARED
  "{{name}}.c"
)

set_target_properties({{name}} PROPERTIES
  OUTPUT_NAME "{{name}}"
)

target_compile_definitions({{name}} PUBLIC DART_SHARED_LIB)
''';

const makeFile = r'''
vendor:
	mkdir -p vendor
	curl -o sqlite-amalgamation.zip https://www.sqlite.org/2024/sqlite-amalgamation-3450300.zip
	unzip sqlite-amalgamation.zip
	mv sqlite-amalgamation-3450300/* vendor/
	rmdir sqlite-amalgamation-3450300
	rm sqlite-amalgamation.zip

deps: sqlite3ext.h sqlite3.h

init: vendor deps

sqlite3ext.h: ./vendor/sqlite3ext.h
		cp $< $@
		mv sqlite3ext.h src/

sqlite3.h: ./vendor/sqlite3.h
		cp $< $@
		mv sqlite3.h src/

.PHONY: deps
''';

const exampleCode = r'''
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:{{name}}/{{name}}.dart' as {{name}};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sqlite3.ensureExtensionLoaded(
    SqliteExtension.inLibrary({{name}}.lib, 'sqlite3_{{name}}_init'),
  );
  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'app.db');
  final db = sqlite3.open(dbPath);
  runApp(MyApp(db: db));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.db});

  final Database db;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    widget.db.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final version = widget.db //
        .select('SELECT {{name}}_version() as version;')
        .first['version'];
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('{{name}}'),
        ),
        body: Center(
          child: Text(
            'version: $version',
          ),
        ),
      ),
    );
  }
}
''';

const packageFile = r'''
import 'dart:ffi';
import 'dart:io';

const String _libName = '{{name}}';

/// The dynamic library in which the symbols for [SqliteVecBindings] can be found.
final DynamicLibrary lib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('$_libName.framework/$_libName');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$_libName.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$_libName.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();
''';

const examplePubspec = r'''
name: {{name}}_example
description: "Demonstrates how to use the {{name}} plugin."
publish_to: 'none' # Remove this line if you wish to publish to pub.dev

version: 1.0.0+1

environment:
  sdk: '>=3.4.3 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  {{name}}:
    path: ../
  
  cupertino_icons: ^1.0.6
  sqlite3: ^2.4.6
  sqlite3_flutter_libs: ^0.5.24
  path: ^1.9.0
  path_provider: ^2.1.4

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
''';
