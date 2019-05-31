import 'package:flutter/material.dart';
import 'dart:io';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/services.dart';

// labels already formatted in the colab notebook.
var LABELS = [
  'Chihuahua',
  'Japanese spaniel',
  'Maltese dog',
  'Pekinese',
  'Tzu',
  'Blenheim spaniel',
  'papillon',
  'toy terrier',
  'Rhodesian ridgeback',
  'Afghan hound',
  'basset',
  'beagle',
  'bloodhound',
  'bluetick',
  'tan coonhound',
  'Walker hound',
  'English foxhound',
  'redbone',
  'borzoi',
  'Irish wolfhound',
  'Italian greyhound',
  'whippet',
  'Ibizan hound',
  'Norwegian elkhound',
  'otterhound',
  'Saluki',
  'Scottish deerhound',
  'Weimaraner',
  'Staffordshire bullterrier',
  'American Staffordshire terrier',
  'Bedlington terrier',
  'Border terrier',
  'Kerry blue terrier',
  'Irish terrier',
  'Norfolk terrier',
  'Norwich terrier',
  'Yorkshire terrier',
  'haired fox terrier',
  'Lakeland terrier',
  'Sealyham terrier',
  'Airedale',
  'cairn',
  'Australian terrier',
  'Dandie Dinmont',
  'Boston bull',
  'miniature schnauzer',
  'giant schnauzer',
  'standard schnauzer',
  'Scotch terrier',
  'Tibetan terrier',
  'silky terrier',
  'coated wheaten terrier',
  'West Highland white terrier',
  'Lhasa',
  'coated retriever',
  'coated retriever',
  'golden retriever',
  'Labrador retriever',
  'Chesapeake Bay retriever',
  'haired pointer',
  'vizsla',
  'English setter',
  'Irish setter',
  'Gordon setter',
  'Brittany spaniel',
  'clumber',
  'English springer',
  'Welsh springer spaniel',
  'cocker spaniel',
  'Sussex spaniel',
  'Irish water spaniel',
  'kuvasz',
  'schipperke',
  'groenendael',
  'malinois',
  'briard',
  'kelpie',
  'komondor',
  'Old English sheepdog',
  'Shetland sheepdog',
  'collie',
  'Border collie',
  'Bouvier des Flandres',
  'Rottweiler',
  'German shepherd',
  'Doberman',
  'miniature pinscher',
  'Greater Swiss Mountain dog',
  'Bernese mountain dog',
  'Appenzeller',
  'EntleBucher',
  'boxer',
  'bull mastiff',
  'Tibetan mastiff',
  'French bulldog',
  'Great Dane',
  'Saint Bernard',
  'Eskimo dog',
  'malamute',
  'Siberian husky',
  'affenpinscher',
  'basenji',
  'pug',
  'Leonberg',
  'Newfoundland',
  'Great Pyrenees',
  'Samoyed',
  'Pomeranian',
  'chow',
  'keeshond',
  'Brabancon griffon',
  'Pembroke',
  'Cardigan',
  'toy poodle',
  'miniature poodle',
  'standard poodle',
  'Mexican hairless',
  'dingo',
  'dhole',
  'African hunting dog'
];

class CategoryBar {
  final String label;
  final double probability;
  final charts.Color color;

  CategoryBar(this.label, this.probability, Color c)
      : this.color = charts.Color(r: c.red, g: c.green, b: c.blue, a: c.alpha);
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

  String findBiggestCategory() {
    var ls = widget.categoryBars;
    double biggest = ls.first.probability;
    String biggest_label = ls.first.label;
    for (int idx = 1; idx < ls.length; idx++) {
      if (ls[idx].probability > biggest) {
        biggest = ls[idx].probability;
        biggest_label = ls[idx].label;
      }
    }
    return biggest_label;
  }

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
    category = findBiggestCategory();
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
            height: height / 2,
            width: width,
          ),
          Container(
              padding: EdgeInsets.all(50),
              alignment: Alignment.center,
              child: SizedBox(
                height: height / 4,
                width: width/2,
                child: charts.BarChart(
                  series,
                  animate: true,
                  animationDuration: Duration(seconds: 2),
                ),
              ))
        ],
      ),
    );
  }
}
