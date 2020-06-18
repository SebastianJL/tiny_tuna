import 'dart:async';
import 'dart:math';

import 'package:charts_flutter/flutter.dart';
import 'package:fft/fft.dart';
import 'package:flutter/material.dart';
import 'package:mic_stream/mic_stream.dart';
import 'package:my_complex/my_complex.dart';
import 'package:supercharged/supercharged.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tiny Tuna',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(title: 'Tiny Tuna'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;
  final Stream<List<int>> _microphone = microphone(sampleRate: 44100);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _listening = false;
  bool _frequencyMode = false;

  Widget _buildBarChart(
      BuildContext context, AsyncSnapshot<List<int>> snapshot) {
    List<num> data;
    Window window;
    List<Complex> transformed;
    Series<num, String> series;

    if (!snapshot.hasData) {
      return Text('bla');
    }
    data = snapshot.data.toList();
    num m = data.averageBy((n) => n);
    data = data.map((e) => e - m).toList();
    int closestPowerOf2 = pow(2, log(data.length) ~/ log(2));
    data = data.sublist(0, closestPowerOf2);

    window = Window(WindowType.HAMMING);
    data = window.apply(data);
    if (_listening) {
      if (_frequencyMode) {
        transformed = FFT().Transform(data);
        data = transformed.map((e) => e.modulus).toList();
      }
    } else {
      return Center(child: Text("No data yet."));
    }
    data = data.chunked(32).map((e) => e.averageBy((n) => n)).toList();
    series = Series(
      id: 'bla',
      data: data,
      measureFn: (datum, index) => datum,
      domainFn: (datum, index) => index.toString(),
    );

    return BarChart(
      [series],
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          ButtonBar(
            children: <Widget>[
              Switch(
                value: _frequencyMode,
                onChanged: (bool newValue) {
                  setState(() {
                    _frequencyMode = newValue;
                  });
                },
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              child: StreamBuilder<List<int>>(
                stream: widget._microphone,
                builder: _buildBarChart,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _listening = !_listening;
          });
        },
        tooltip: 'Listen',
        backgroundColor: _listening ? Colors.red : Colors.blue,
        child: _listening ? Icon(Icons.stop) : Text('listen'),
      ),
    );
  }
}

List<T> slice<T>(List<T> list, [int start = 0, int stop = -1, int step = 1]) {
  stop = stop % list.length;
  var sliced = <T>[];
  for (var i = start; i <= stop; i += step) sliced.add(list[i]);
  return sliced;
}
