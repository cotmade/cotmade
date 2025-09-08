import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cotmade/view/component/square_tile.dart';
import 'package:cotmade/global.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cotmade/view/component/auth_service.dart';
import 'package:cotmade/view/signup_screen.dart';
import 'package:flutter/src/widgets/basic.dart';
import 'package:flutter/services.dart';
import 'package:cotmade/view/reset_password_screen.dart';
import 'package:cotmade/view/firebase_exceptions.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();

  bool _isSubmitting = false;
  String password = ''; // Initialize the password variable
  bool showPassword = false; // Initialize the showPassword flag

  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword; // Toggle the showPassword flag
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //  backgroundColor: Colors.white,
        body: SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white,
              //  Colors.black12,
            ],
          ),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 10),
            //logo
            Image.asset("images/afrikk_prev_ui.png", height: 240),
            const SizedBox(height: 3),
            //welcome back you been missed

            Text(
              'Welcome back you\'ve been missed',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 15),

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
                        labelStyle:
                            TextStyle(color: Colors.black, fontSize: 15),
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
                  //password
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
                        labelText: 'Password',
                        labelStyle:
                            TextStyle(color: Colors.black, fontSize: 15),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.visibility_off),
                          selectedIcon: const Icon(Icons.visibility),
                          onPressed: toggleShowPassword,
                          // _textFocusNode.requestFocus();
                          // handlePressed(controller);
                        ),
                      ),
                      obscureText: !showPassword,
                      controller: _passwordTextController,
                      validator: (valuePassword) {
                        if (valuePassword!.length < 5) {
                          return "Password must be at least 6 or more characters.";
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          password =
                              value; // Update the password when input changes
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  //sign in button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Obx(() {
                      return SizedBox(
                        width: 360,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: userViewModel.isSubmitting.value
                              ? null
                              : () {
                                  if (_formKey.currentState!.validate()) {
                                    userViewModel.login(
                                      _emailTextController.text.trim(),
                                      _passwordTextController.text.trim(),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: userViewModel.isSubmitting.value
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 22.0,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  //forgot passowrd

                  Padding(
                    padding: const EdgeInsets.only(left: 35.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Forgot your login details? ',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                        Padding(
                            padding: const EdgeInsets.only(left: 2.0),
                            child: GestureDetector(
                              child: TextButton(
                                onPressed: () {
                                  Get.to(ResetPasswordScreen());
                                },
                                child: Text(
                                  'Get Help!',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8, right: 8),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 0.5,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),

                  //google + apple button

                  //    Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  // google buttom
                  //   SquareTile(
                  //   onTap: () => AuthService().signInWithGoogle(),
                  //   imagePath: 'images/google.svg',
                  //
                  //    height: 30,
                  //  ),

                  //   SizedBox(width: 20),
                  // apple buttom
                  //    SquareTile(
                  //     onTap: () {},
                  //     imagePath: 'images/Vector.svg',
                  //     height: 70,
                  //   ),
                  //   ],
                  //  ),
                  //  const SizedBox(
                  //    height: 20,
                  //  ),

                  // not a memeber ? register now

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Join this Community? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      GestureDetector(
                        child: TextButton(
                          onPressed: () {
                            Get.to(SignupScreen());
                          },
                          child: Text(
                            'Sign up now',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 17),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    ));
  }
}
