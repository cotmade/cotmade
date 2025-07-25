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
import 'package:cotmade/view/login_screen2.dart';
import 'package:cotmade/view/unregisteredScreens/first_screen.dart';

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
  int selectedIndex = 2;

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
                "Forgot Password!",
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
                    //  Image.asset("images/pikaso.png", height: 230),
                    //    const SizedBox(height: 10),
                    //welcome back you been missed

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          //username
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 25),
                            child: TextFormField(
                              decoration: InputDecoration(
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.email),
                                //  hintText: 'Email',
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                    color: Colors.black, fontSize: 15),
                              ),
                              controller: _emailTextController,
                              validator: (valueEmail) {
                                if (!valueEmail!.contains("@")) {
                                  return "Please enter a valid email.";
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(height: 15),

                          const SizedBox(height: 15),

                          //sign in button
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
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await userViewModel.forgotpassword(
                                      _emailTextController.text.trim(),
                                    );

                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text("Email Sent"),
                                        content: Text(
                                            "A password reset link has been sent to your email address."),
                                        actions: [
                                          TextButton(
                                            child: Text("OK"),
                                            onPressed: () =>
                                                Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    //    showDialog(
                                    //        context: context,
                                    //           builder: (context) {
                                    //            return AlertDialog(
                                    //             title: Text("Invalid login credentials"),
                                    //             actions: [
                                    //               TextButton(
                                    //                 onPressed: () {
                                    //                   Navigator.pop(context);
                                    //                 },
                                    //                 child: Text('OK'),
                                    //               ),
                                    //             ],
                                    //          );
                                    //         },
                                    //       );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                ),
                                child: const Text(
                                  "Submit",
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 22.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          //forgot passowrd

                          Padding(
                            padding: const EdgeInsets.only(left: 35.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Remember now?',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12),
                                ),
                                Padding(
                                    padding: const EdgeInsets.only(left: 2.0),
                                    child: GestureDetector(
                                      child: TextButton(
                                        onPressed: () {
                                          Get.to(FirstScreen());
                                        },
                                        child: Text(
                                          'Back to Login!',
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

                          // continue with
                        ],
                      ),
                    ),
                  ]),
            ),
          ])),
    );
  }
}
