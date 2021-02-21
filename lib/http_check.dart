import 'dart:io';
import 'dart:async';
import 'dart:isolate';

Isolate _animation_isolate;

Future<Isolate> animation_start() async {
  return _animation_isolate ?? (_animation_isolate = await Isolate.spawn(_animate, null));
}

void animation_stop() {
  _animation_isolate.kill(priority: Isolate.immediate);
  _animation_isolate = null;
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
  var frame = 0;
  var period = 100; // milliseconds
  var snake_length = (8 * 1) + 1; // (8 frames x length of snake) + 1 to make it animated.

  void next_frame() {
    stdout.write('\x1B[1m${frames[frame++]}\x1B[m');
    frame %= frames.length;
  }

  void clear_frame() {
    stdout.write('\x1B[2A\x1B[2K\x1B[1G'); // Go up, clear, go to column 1
  }

  var run = true;
  while (run) {
    for (var i = 0; i < snake_length; i++) {
      next_frame();
    } 
    stdout.write('\n\n');
    sleep(Duration(milliseconds: period));
    await Future.delayed(Duration());
    clear_frame();
    
  }
}