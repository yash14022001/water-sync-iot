import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class GaugeChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;
  final pi = 3.14;

  static final orange = charts.MaterialPalette.yellow.makeShades(1);
  static final red = charts.MaterialPalette.red.makeShades(1);
  static final green = charts.MaterialPalette.green.makeShades(1);
  static final gray = charts.MaterialPalette.gray.makeShades(1);

  GaugeChart(this.seriesList, {this.animate});

  /// Creates a [PieChart] with sample data and no transition.
  factory GaugeChart.withSampleData() {
    return new GaugeChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.PieChart(seriesList,
        animate: animate,
        // Configure the width of the pie slices to 30px. The remaining space in
        // the chart will be left as a hole in the center. Adjust the start
        // angle and the arc length of the pie so it resembles a gauge.
        defaultRenderer: new charts.ArcRendererConfig(
            arcWidth: 30, startAngle: 4 / 5 * pi, arcLength: 7 / 5 * pi));
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<GaugeSegment, String>> _createSampleData() {
    final data = [
      new GaugeSegment('Water', 20),
      new GaugeSegment('Empty', 80),
    ];

    return [
      new charts.Series<GaugeSegment, String>(
        id: 'Segments',
        colorFn: (GaugeSegment segment, _) => getColor(segment, _),
        domainFn: (GaugeSegment segment, _) => segment.segment,
        measureFn: (GaugeSegment segment, _) => segment.size,
        data: data,
      )
    ];
  }

  static charts.Color getColor(GaugeSegment gs,_){
    if(gs.segment == "Empty"){
      return gray[0];
    }
    else if(gs.size >= 75){
      return green[0];
    }
    else if(gs.size >= 50){
      return orange[0];
    }
    else{
      return red[0];
    }
  }
}

/// Sample data type.
class GaugeSegment {
  final String segment;
  final int size;

  GaugeSegment(this.segment, this.size);
}
