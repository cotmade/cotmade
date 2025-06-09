import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/component/square_tile.dart';
import 'package:cotmade/global.dart';
//import 'package:nestcrib/view/components/my_buttom.dart';
//import 'package:nestcrib/view/components/my_textfield.dart';
//import 'package:nestcrib/view/components/square_tile.dart';
//import 'package:nestcrib/view/services/auth_service.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cotmade/view/component/auth_service.dart';
import 'package:cotmade/view/signup_screen.dart';
//import 'package:nestcrib/view_model/user_view_model.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/services.dart';
//import 'package:alarmplayer/alarmplayer.dart';
import 'package:cotmade/view/reset_password_screen.dart';
import 'package:cotmade/view/firebase_exceptions.dart';
import 'package:cotmade/view/login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  TextEditingController email = TextEditingController();
  // EmailOTP myauth = EmailOTP();

  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Colors.white,
              ],
              begin: FractionalOffset(0, 0),
              end: FractionalOffset(1, 0),
              stops: [0, 1],
              tileMode: TileMode.clamp,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.black12,
            ],
          ),
        ),
        child: ListView(children: [
          Padding(
            padding: const EdgeInsets.only(left: 30.0, right: 20.0),
            child: const Text(
              "",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 25.0,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 25),
                //logo
                Image.asset("images/reset.png", height: 230),
                const SizedBox(height: 10),
                //welcome back you been missed

                const SizedBox(height: 10),

                //forgot passowrd
                Padding(
                    padding: const EdgeInsets.only(left: 2.0),
                    child: GestureDetector(
                      child: TextButton(
                        onPressed: () {
                          Get.to(LoginScreen());
                        },
                        child: Text(
                          'Password Link sent Successfully',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.only(left: 35.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Padding(
                          padding: const EdgeInsets.only(left: 2.0),
                          child: GestureDetector(
                            child: TextButton(
                              onPressed: () {
                                Get.to(LoginScreen());
                              },
                              child: Text(
                                'Check your email to complete the password change',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                    width: 360,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 22.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // continue with
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
