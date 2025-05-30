import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cotmade/view/add_screen.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';

class AddVideoButton extends StatelessWidget {
  const AddVideoButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InkWell(
          onTap: () {
            Get.to(AddScreen());
          },
          child: Container(
            width: 190,
            height: 50,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8), color: Colors.black),
            child: const Center(
              child: Text(
                'Add Clip',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}
