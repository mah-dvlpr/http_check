import 'dart:io';
import 'dart:async';
import 'dart:isolate';

import 'package:http_check/http_check.dart';

import 'package:meta/meta.dart';
import 'package:args/args.dart' as arg;
import 'package:http/http.dart' as http;
import 'package:pedantic/pedantic.dart';

import 'package:ansi_styles/ansi_styles.dart' as ansi_styles;
import 'package:path/path.dart';

const delim = '#####';
const delim_count = 5;
const request_file_template = '''${delim}
generated request_file_template (Write your own test name here!)
${delim}
https://httpbin.org/get
GET / HTTP/1.1
Host: httpbin.org
${delim}
date: .* GMT
"X-Amzn-Trace-Id.*\\n 
${delim}
Body data (Only for POST requests). This will be ignored with GET requests.
Remove/Update this segment if you wish to make a POST request instead.
${delim}
Response HEADERS
+
Response BODY''';

Isolate animation_isolate;

void main(List<String> arguments) async {
  final parser = arg.ArgParser();
  parser
    ..addFlag('continuous', abbr: 'c')
    ..addFlag('generate', abbr: 'g')
    ..addFlag('help', abbr: 'h');

  try {
    final flags = parser.parse(arguments);

    if (flags['continuous']) {
      await run_loop(file_paths: flags.rest);
    } else if (flags['generate']) {
      flags.rest.isEmpty
          ? generateTemplate()
          : generateTemplate(file_paths: flags.rest);
    } else if (flags['help']) {
      // TODO: Add help section
    } else {
      await run_once(file_paths: flags.rest);
    }
  } catch (err) {
    print(err.toString());
    return;
  }
}

Future<void> run_loop({@required List<String> file_paths}) async {
  var run = true;
  while (run) {
    run = await run_once(file_paths: file_paths);
    sleep(Duration(seconds: 4));  // Keep results on screen for a while.
    print('\x1B[2J\x1B[0;0H');    // Clear the screen.
  }
}

/// TODO: Add doc...
Future<bool> run_once({@required List<String> file_paths}) async {
  print('========== New run at - ${DateTime.now().toString().substring(11,19)} ==========');

  await animationStart();
  sleep(Duration(seconds: 5));

  File file;
  List<String> lines, request, ignore, body, expected;
  var names = <String>[];
  var futures = <Future<bool>>[];
  var results = <bool>[];

  // Get response for each file
  for (var file_path in file_paths) {
    file = File(file_path); 

    if (!file.existsSync()) {
      throw PathException('File \'${file.path}\' does not exist at path.');
    }

    if (file.lengthSync() == 0) {
      throw FormatException('File \'${file.path}\' is empty.');
    }

    lines = file.readAsLinesSync();
    names.add(getNextSegment(lines)[0]);
    request = getNextSegment(lines);
    ignore = getNextSegment(lines);
    body = getNextSegment(lines);
    expected = getNextSegment(lines, last_segment: true);
    futures.add(getResponseAndCompare(request, ignore, body, expected));
  }

  // Print results
  results = await Future.wait(futures);
  animationStop();
  for (var i = 0; i < results.length; i++) {
    if (results[i]) {
      print('${ansi_styles.AnsiStyles.bold.greenBright('OK')}\t- ${names[i]}');
    } else {
      print('${ansi_styles.AnsiStyles.bold.redBright('FAILED')}\t- ${names[i]}');
    }
  }

  return true;
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
  List<String> lines, request, ignore, body;
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
    body = getNextSegment(lines);
    generateAndWriteExpectedResponse(file, request, ignore, body);
  }
}

/// Throws an error if given string does not match the delimiter.
void checkDelim(String str) {
  if (str != delim) {
    throw FormatException('String did not match delimiter.');
  }
}

/// Forwards the list (by removing the part segmented by the delimiter),
/// and returns the current (i.e. the skipped) segment.
List<String> getNextSegment(List<String> lines, {bool last_segment = false}) {
  checkDelim(lines[0]);
  var start = 1;
  var stop = start + 1;
  if (lines[start] == delim) {
    stop = start;
  } else {
    for (; stop < lines.length && lines[stop] != delim; stop++) {}
  }
  if (!last_segment) {
    checkDelim(lines[stop]);
  }
  var ret = lines.sublist(start, stop);
  lines.removeRange(0, stop);
  return ret;
}

/// Makes a request and returns
Future<String> getResponse(List<String> request, List<String> ignore,
    {List<String> body}) async {
  var url = request[0];
  var method = request[1].split(' ')[0];
  var headers = <String, String>{};
  for (var line in request.sublist(2)) {
    var name = line.split(':')[0];
    var value = line.split(':').sublist(1).join(':');
    headers[name] = value;
  }

  String ret;
  http.Response response;
  switch (method) {
    case 'GET':
      response = await http.get(url, headers: headers);
      break;
    case 'POST':
      response = await http.post(url, headers: headers, body: body.join('\n'));
      break;
    case 'PATCH':
      response = await http.patch(url, headers: headers, body: body.join('\n'));
      break;
    case 'PUT':
      response = await http.put(url, headers: headers, body: body.join('\n'));
      break;
    case 'DELETE':
      response = await http.delete(url, headers: headers);
      break;
    default:
      throw HttpException('Method currently not supported!');
  }
  response.headers.forEach((key, value) {
    ret = '${ret}${key}: ${value}\n';
  });
  ret = '${ret}\n${response.body}';

  // Ignore shenanigans
  ignore.forEach((element) {
    ret = ret.replaceAll(RegExp('${element}'), '#IGNORED -> \"${element}\"#');
  });

  return ret;
}

Future<bool> getResponseAndCompare(List<String> request, List<String> ignore,
    List<String> body, List<String> expected) async {
  var response = await getResponse(request, ignore, body: body);

  // CRLF is nasty! Remove it!
  expected.forEach((element) {element.replaceAll('\r\n', '\n');});
  response.replaceAll('\r\n', '\n');

  if (response.trim() != expected.join('\n').trim()) {
    return false;
  }
  return true;
}

void generateAndWriteExpectedResponse(File file, List<String> request,
    List<String> ignore, List<String> body) async {
  var response = await getResponse(request, ignore, body: body);

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