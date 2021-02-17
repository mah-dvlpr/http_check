import 'package:http_check/http_check.dart' as http_check;
import 'package:ansicolor/ansicolor.dart' as color;

void main(List<String> arguments) {
  // print('Hello world: ${http_checker.calculate()}!');
  color.AnsiPen pen = color.AnsiPen()..red();
  print(pen('Hejsan mamma! :D') + "This is normal");
}
