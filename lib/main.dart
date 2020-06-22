import 'dart:math';

import 'package:charts_flutter/flutter.dart';
import 'package:fft/fft.dart';
import 'package:flutter/material.dart';
import 'package:my_complex/my_complex.dart';
import 'package:supercharged/supercharged.dart';
import 'package:tinytuna/src/homepage_bloc.dart';
import 'package:tinytuna/src/button_event.dart';

void main() => runApp(App());

class App extends StatelessWidget {
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

class HomePage extends StatelessWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final HomepageBloc bloc = HomepageBloc();
  final String title;

    Widget _buildBarChart(
      BuildContext context, AsyncSnapshot<List<int>> snapshot) {
    List<num> data;
    Window window;
    List<Complex> transformed;
    Series<num, String> series;

    if (!snapshot.hasData) {
      return Text('No data yet.');
    }
    data = snapshot.data.toList();
    num m = data.averageBy((n) => n);
    data = data.map((e) => e - m).toList();
    int closestPowerOf2 = pow(2, log(data.length) ~/ log(2));
    data = data.sublist(0, closestPowerOf2);

    window = Window(WindowType.HAMMING);
    data = window.apply(data);
//    if (_frequencyMode) {
//      transformed = FFT().Transform(data);
//      data = transformed.map((e) => e.modulus).toList();
//    }
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
        title: Text(title),
      ),
      body: Column(
        children: <Widget>[
          ButtonBar(
            children: <Widget>[
              StreamBuilder<Object>(
                stream: bloc.frequencyModeStateStream,
                initialData: false,
                builder: (context, snapshot) {
                  return Switch(
                    value: snapshot.data,
                    onChanged: (bool newValue)=> bloc.buttonEventSink.add(ButtonEvent.FrequencyModeButtonPressed),
                  );
                }
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              child: StreamBuilder<List<int>>(
                stream: bloc.audioDataStream,
                builder: _buildBarChart,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bloc.audioStateStream,
        initialData: false,
        builder: (context, snapshot) {
          return FloatingActionButton(
            onPressed: () => bloc.buttonEventSink.add(ButtonEvent.AudioButtonPressed),
            tooltip: 'Listen',
            backgroundColor: snapshot.data ? Colors.red : Colors.blue,
            child: snapshot.data ? Icon(Icons.stop) : Text('Listen'),
          );
        }
      ),
    );
  }
}
