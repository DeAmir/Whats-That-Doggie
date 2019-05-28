import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

class CategoryInfo extends StatefulWidget{
  CategoryInfo({Key key, @required String this.category}) : super(key: key);

  final String category;


  @override
  _CategoryInfoState createState() => _CategoryInfoState();
}

class _CategoryInfoState extends State<CategoryInfo>{
  String category;

  @override
  void initState() {
    category = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category),),
      body: Text("working?"),
    );
  }
}