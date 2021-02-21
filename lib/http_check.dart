import 'dart:io';
import 'dart:async';
import 'dart:isolate';

Isolate _animationIsolate;

Future<Isolate> animationStart() async {
  return _animationIsolate ?? (_animationIsolate = await Isolate.spawn(_animate, null));
}

void animationStop() {
  _animationIsolate.kill(priority: Isolate.immediate);
  _animationIsolate = null;
}

Future<void> _animate(SendPort sp) async {
  var frames = const <String>[
      '⠁',
      '⠂',
      '⠄',
      '⡀',
      '⢀',
      '⠠',
      '⠐',
      '⠈'
    ];
  var baseFrame = 0;
  var period = 100; // milliseconds
  var terminalColumns = 0;

  void nextFrame(int frame) {
    stdout.write('\x1B[1m${frames[frame]}\x1B[m');
  }

  void clearFrame() {
    stdout.write('\x1B[2A\x1B[2K\x1B[1G'); // Go up, clear, go to column 1
  }

  while (true) {
    terminalColumns = stdout.terminalColumns;
    for (var frame = baseFrame; frame < terminalColumns + baseFrame; frame++) {
      nextFrame(frame % frames.length);
    }
    baseFrame = (baseFrame + 1) % frames.length;
    stdout.write('\n\n');
    // if (terminal_width != stdout.terminalColumns) {
    //   stdout.write('\x1B[2A\x1B[2K');
    // }
    sleep(Duration(milliseconds: period));
    await Future.delayed(Duration());
    clearFrame();
  }
}