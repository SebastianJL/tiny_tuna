import 'dart:async';

import 'package:mic_stream/mic_stream.dart';
import 'package:tinytuna/src/button_event.dart';

class HomepageBloc {
  StreamSubscription<List<int>> _listener;
  bool _listening = false;
  bool _frequencyMode = false;

  final _buttonEventController = StreamController<ButtonEvent>();
  final _audioStateController = StreamController<bool>();
  final _frequencyModeStateController = StreamController<bool>();
  final Stream<List<int>> _microphone = microphone();
  final _audioDataController = StreamController<List<int>>();

  StreamSink<ButtonEvent> get buttonEventSink => _buttonEventController.sink;

  Stream<ButtonEvent> get _buttonEventStream => _buttonEventController.stream;

  Stream<bool> get audioStateStream => _audioStateController.stream;

  StreamSink<bool> get _audioStateSink => _audioStateController.sink;

  Stream<bool> get frequencyModeStateStream => _frequencyModeStateController.stream;

  StreamSink<bool> get _frequencyModeStateSink => _frequencyModeStateController.sink;

  Stream<List<int>> get audioDataStream => _audioDataController.stream;

  StreamSink<List<int>> get _audioDataSink => _audioDataController.sink;

  HomepageBloc() {
    _buttonEventStream.listen(_mapEventToState);
  }

  void _mapEventToState(ButtonEvent event) {
    switch (event) {
      case ButtonEvent.AudioButtonPressed:
        {
          if (_listener == null) {
            _listener =
                _microphone.listen((event) => _audioDataSink.add(event));
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

  void close() {
    _buttonEventController.close();
    _audioStateController.close();
    _audioDataController.close();
    _frequencyModeStateController.close();
    _listener.cancel();
  }
}
