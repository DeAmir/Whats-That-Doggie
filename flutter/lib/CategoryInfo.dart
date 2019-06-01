import 'package:flutter/material.dart';
import 'dart:io';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/services.dart';

class CategoryBar {
  final String label;
  final double probability;
  var color;

  CategoryBar(this.label, this.probability, Color c)
      : this.color = charts.Color(r: c.red, g: c.green, b: c.blue, a: c.alpha);

  void setColor(Color c){
    this.color = charts.Color(r: c.red, g: c.green, b: c.blue, a: c.alpha);
  }
}

List<CategoryBar> data;

class CategoryInfo extends StatefulWidget {
  CategoryInfo(
      {Key key,
      @required String this.path,
      @required List<CategoryBar> this.categoryBars})
      : super(key: key);

  final String path;
  final List<CategoryBar> categoryBars;

  @override
  _CategoryInfoState createState() => _CategoryInfoState();
}

var client = HttpClient();

class _CategoryInfoState extends State<CategoryInfo> {
  String category, path;
  File imageFile;
  double height, width;

  var series;

  @override
  void initState() {
    super.initState();

    data = widget.categoryBars;
    series = [
      charts.Series(
          id: "Percentage",
          domainFn: (CategoryBar cate, _) => cate.label,
          measureFn: (CategoryBar cate, _) => cate.probability,
          colorFn: (CategoryBar cate, _) => cate.color,
          data: data)
    ];

    print("got data on the other side: $data");
    category = data[0].label;
    path = widget.path;
    imageFile = File.fromUri(Uri(path: path));

    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Breed: " + category),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Image.file(
            imageFile,
            fit: BoxFit.cover,
            height: height / 2.5,
            width: width,
          ),
          Padding(padding: EdgeInsets.all(10),),
          Text("Probabilities:",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30),textAlign: TextAlign.center,),
          Container(
              padding: EdgeInsets.all(50),
              alignment: Alignment.center,
              child: SizedBox(
                height: height / 4,
                width: width,
                child: charts.BarChart(
                  series,
                  animate: true,
                  animationDuration: Duration(seconds: 1),
                  vertical: false,
                ),
              ))
        ],
      ),
    );
  }
}
