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
  var base_frame = 0;
  var period = 100; // milliseconds
  var terminal_width = 0;

  void next_frame(int frame) {
    stdout.write('\x1B[1m${frames[frame]}\x1B[m');
  }

  void clear_frame() {
    stdout.write('\x1B[2A\x1B[2K\x1B[1G'); // Go up, clear, go to column 1
  }

  while (true) {
    terminal_width = stdout.terminalColumns;
    for (var frame = base_frame; frame < terminal_width + base_frame; frame++) {
      next_frame(frame % frames.length);
    }
    base_frame = (base_frame + 1) % frames.length;
    stdout.write('\n\n');
    // if (terminal_width != stdout.terminalColumns) {
    //   stdout.write('\x1B[2A\x1B[2K');
    // }
    sleep(Duration(milliseconds: period));
    await Future.delayed(Duration());
    clear_frame();
  }
}