import 'package:args/command_runner.dart';
import 'package:http_check/http_check.dart' as http_check;
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

    } else if (flags['help']) {

    }
  } catch(err) {
    print(err.toString());
    return;
  }
}

// void generateTemplate({@required String path = './generated'}) {

// }
