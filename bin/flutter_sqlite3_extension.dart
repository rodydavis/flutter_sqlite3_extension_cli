// ignore_for_file: avoid_print
import 'dart:io';

import 'package:args/args.dart';
import 'package:flutter_sqlite3_extension/flutter_sqlite3_extension.dart';
import 'package:path/path.dart' as p;

var parser = ArgParser() //
  ..addOption('source', abbr: 's', mandatory: true)
  ..addOption('name')
  ..addFlag('verbose', abbr: 'v');

bool verbose = false;

void main(List<String> args) async {
  final result = parser.parse(args);
  verbose = result.flag('verbose');
  var source = result.option('source')!;
  if (!source.endsWith('.c')) {
    print('source file must end in .c');
    exit(-1);
  }
  var name = result.option('name') ?? p.basename(source);
  if (!name.endsWith('.c')) {
    print('name must end in .c');
    exit(-1);
  }
  await create(source, name, debug: verbose);
}
