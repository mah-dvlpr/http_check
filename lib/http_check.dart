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
  stdout.write('\n');
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

  void nextFrame(int frame) {
    stdout.write('\x1B[1m${frames[frame]}\x1B[m');
  }

  void clearFrame() {
    stdout.write('\x1B[2K\x1B[1G');
  }

  while (true) {
    for (var frame = baseFrame; frame < stdout.terminalColumns ~/ 2 + baseFrame; frame++) {
      nextFrame(frame % frames.length);
    }
    baseFrame = (baseFrame + 1) % frames.length;
    sleep(Duration(milliseconds: period));
    clearFrame();
  }
}