import 'dart:async';
import 'dart:math';

import 'package:fft/fft.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:my_complex/my_complex.dart';
import 'package:supercharged/supercharged.dart';
import 'package:tinytuna/src/button_event.dart';

class HomepageBloc {
  StreamSubscription<List<int>> _listener;
  bool _listening = false;
  bool _frequencyMode = false;

  final _buttonEventController = StreamController<ButtonEvent>();
  final _audioStateController = StreamController<bool>();
  final _frequencyModeStateController = StreamController<bool>();
  final Stream<List<int>> _microphone = microphone();
  final _audioDataController = StreamController<List<num>>();

  StreamSink<ButtonEvent> get buttonEventSink => _buttonEventController.sink;

  Stream<ButtonEvent> get _buttonEventStream => _buttonEventController.stream;

  Stream<bool> get audioStateStream => _audioStateController.stream;

  StreamSink<bool> get _audioStateSink => _audioStateController.sink;

  Stream<bool> get frequencyModeStateStream =>
      _frequencyModeStateController.stream;

  StreamSink<bool> get _frequencyModeStateSink =>
      _frequencyModeStateController.sink;

  Stream<List<num>> get audioDataStream => _audioDataController.stream;

  StreamSink<List<num>> get _audioDataSink => _audioDataController.sink;

  HomepageBloc() {
    _buttonEventStream.listen(_mapEventToState);
  }

  void _mapEventToState(ButtonEvent event) {
    switch (event) {
      case ButtonEvent.AudioButtonPressed:
        {
          if (_listener == null) {
            _listener = _microphone.listen((event) => _processMicrophoneEvent(event));
          } else if (_listening) {
            _listener.pause();
          } else {
            _listener.resume();
          }
          _listening = !_listening;
          _audioStateSink.add(_listening);
        }
        break;

      case ButtonEvent.FrequencyModeButtonPressed:
        {
          _frequencyMode = !_frequencyMode;
          _frequencyModeStateSink.add(_frequencyMode);
          break;
        }
    }
  }

  _processMicrophoneEvent(List<int> event) {
    List<num> data;
    Window window;
    List<Complex> transformed;

    data = event;
    num m = data.averageBy((n) => n);
    data = data.map((e) => e - m).toList();
    int closestPowerOf2 = pow(2, log(data.length) ~/ log(2));
    data = data.sublist(0, closestPowerOf2);

    window = Window(WindowType.HAMMING);
    data = window.apply(data);
    if (_frequencyMode) {
      transformed = FFT().Transform(data);
      data = transformed.map((e) => e.modulus).toList();
    }
    data = data.chunked(32).map((e) => e.averageBy((n) => n)).toList();

    _audioDataSink.add(data);
  }

  void close() {
    _buttonEventController.close();
    _audioStateController.close();
    _audioDataController.close();
    _frequencyModeStateController.close();
    _listener.cancel();
  }
}
