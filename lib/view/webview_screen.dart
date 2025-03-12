import 'package:cotmade/model/posting_model.dart';
import 'package:cotmade/view/view_posting_screen.dart';
import 'package:cotmade/view/widgets/posting_grid_tile_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/unregisteredScreens/view_post_screen.dart';
import 'package:cotmade/view/widgets/posting_grid2_tile_ui.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_html/flutter_html.dart';

// New screen for displaying HTML content
class HTMLScreen extends StatelessWidget {
  final String url;

  HTMLScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HTML Content')),
      body: SingleChildScrollView(
        child: Html(
          data: '<a href="$url">$url</a>',
        ),
      ),
    );
  }
}
