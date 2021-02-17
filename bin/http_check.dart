import 'dart:io';
// import 'dart:collection';

import 'package:http_check/http_check.dart' as http_check;

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:args/args.dart' as arg;
import 'package:http/http.dart' as http;
import 'package:ansicolor/ansicolor.dart' as color;

// Flow:
// Take input (paths to files either relative or absolute)
// For each file:
  // Make request with data from file content
  // Ignore parts according to file content
  // Compare to response with expected response (also stored in file)

// TODO:
// 1. Create a generator function
// 2. Create a request function
// 3. Create a ignore function
// 4. Create a compare function

// TODO: Extras
// 1. Make some parts (such as reading files) asynchronous.

/// Delimiter between request file segments
const delim = '#####';

void main(List<String> arguments) {
  final parser = arg.ArgParser();
  parser
    ..addFlag('continuous', abbr: 'c')
    ..addFlag('generate', abbr: 'g')
    ..addFlag('help', abbr: 'h');
  
  try {
    final flags = parser.parse(arguments);

    if (flags['continuous']) {

    } else if (flags['generate']) {
      flags.rest.isEmpty ? generateTemplate() : generateTemplate(files: flags.rest);
    } else if (flags['help']) {

    }
  } catch(err) {
    print(err.toString());
    return;
  }
}

/// Generates template files for each provided file (path).
/// 
/// If file names (paths) are not provided -> generate a single template file 
/// called 'generated'.
/// 
/// If a file already contains some valid data, make a request to the server as 
/// requested by the file, ignore patterns as defined by the file, and generate 
/// (overwrite) the previous expected request data of the file.
void generateTemplate({List<String> files = const ['generated']}) {
  List<String> name, request, ignore, response;
  for (var file in files) {
    for (var lines in File(file).readAsLinesSync()) {
      
      // if (_.length == 1 && _.toString() == delim) {
        print(lines);
      // }
      // Read each line until a delimiter is encountered
      // 
    }
  }
}
