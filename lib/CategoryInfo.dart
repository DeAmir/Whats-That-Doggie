import 'package:flutter/material.dart';
import 'dart:io';

class CategoryInfo extends StatefulWidget {
  CategoryInfo(
      {Key key, @required String this.category, @required String this.path})
      : super(key: key);

  final String category;
  final String path;

  @override
  _CategoryInfoState createState() => _CategoryInfoState();
}

var client = HttpClient();
class _CategoryInfoState extends State<CategoryInfo> {
  String category, path;
  File imageFile;
  double height, width;

  @override
  void initState() {
    super.initState();
    category = widget.category;
    path = widget.path;
    imageFile = File.fromUri(Uri(path: path));
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
          Container(alignment: Alignment.center, child: Icon(Icons.category,size: height/3,))
        ],
      ),
    );
  }
}
