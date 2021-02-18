import 'dart:io';
import 'dart:async';
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
const delim_count = 5;
const request_file_template = '''${delim}
generated request_file_template
${delim}
http://google.com
GET / HTTP/1.1
Host: google.com
${delim}
date: .* GMT
${delim}
Body data (Only for POST requests). This will be ignored with GET requests.
Remove/Update this segment if you whish to make a POST request instead.
${delim}
Response HEADERS
+
Response BODY''';

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
      flags.rest.isEmpty ? generateTemplate() : generateTemplate(file_paths: flags.rest);
    } else if (flags['help']) {

    }
  } catch(err) {
    print(err.toString());
    return;
  }
}

/// Throws an error if given string does not match the delimiter.
void checkDelim(String str) {
  if (str != delim) {
    throw FormatException('String did not match delimiter.');
  }
}

/// Forwards the list (by removing the part segmented by the delimiter), 
/// and returns the current segment.
List<String> getNextSegment(List<String> lines) {
  checkDelim(lines[0]);
  var start = 1;
  var stop = start + 1;
  if (lines[start] == delim) {
    stop = start;
  } else {
    for (; stop < lines.length && lines[stop] != delim; stop++) {};
  }
  checkDelim(lines[stop]);
  var ret = lines.sublist(start, stop);
  lines.removeRange(0, stop);
  return ret;
}

/// Makes a request and returns 
Future<String> getResponse(List<String> request, {String body}) async {
  var url = request[0];
  var method = request[1].split(' ')[0];
  var headers = <String, String>{};
  for (var line in request.sublist(2)) {
    var name = line.split(':')[0];
    var value = line.split(':').sublist(1).join(':');
    headers[name] = value;
  }

  // TODO: Depending on GET or post...
  String ret;
  http.Response response;
  switch (method) {
    case 'GET':
      response = await http.get(url, headers: headers);
      break;
    case 'POST':
      response = await http.post(url, headers: headers, body: body);
      break;
    default:
  }
  response.headers.forEach((key, value) { 
    ret = '${ret}${key}: ${value}\n';
  });
  ret = '${ret}\n${response.body}';
  return ret;
}

/// Generates request template files for each provided file (path).
/// 
/// If file names (paths) are not provided -> generate a single request template
///  file called 'generated'.
/// 
/// If a file already contains some valid data, make a request to the server as 
/// requested by the file, ignore patterns as defined by the file, and generate 
/// (overwrite) the previous expected request data of the file.
void generateTemplate({List<String> file_paths = const ['generated']}) {
  File file;
  List<String> lines, request, ignore;
  for (var file_path in file_paths) {
    file = File(file_path);

    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }

    if (file.lengthSync() == 0) {
      file.writeAsStringSync(request_file_template);
    }

    // Generate expected response
    lines = file.readAsLinesSync();
    getNextSegment(lines); // Skip name segment
    request = getNextSegment(lines);
    ignore = getNextSegment(lines);
    generateAndWriteExpectedResponse(file, request, ignore);
  }
}

void generateAndWriteExpectedResponse(File file, List<String> request, List<String> ignore) async {
  var response = await getResponse(request);

  // Ignore shenanigans
  for (var i = 0; i < ignore.length; i++) {
    // response = response.split(ignore[i]).join('#IGNORED#');
    response = response.replaceAll(RegExp('${ignore[i]}'), '#IGNORED#');
  }

  // Write back to file
  var file_data = file.readAsLinesSync();
  var delim_counter = 0;
  var response_start = 0;
  for (; delim_counter < delim_count; response_start++) {
    if (file_data[response_start] == delim) {
      delim_counter++;
    }
  }
  file_data.removeRange(response_start, file_data.length);
  file_data.add(response);
  file.writeAsStringSync(file_data.join('\n'), mode: FileMode.writeOnly);
}