import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cotmade/view/component/auth_service.dart';
import 'package:cotmade/view/signup_screen.dart';
import 'package:cotmade/view/reset_password_screen.dart';
import 'package:cotmade/view/firebase_exceptions.dart';
import 'package:cotmade/global.dart'; // Assuming userViewModel is defined here
import '../view_model/user_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passwordTextController = TextEditingController();

  final userViewModel = Get.find<UserViewModel>(); // GetX ViewModel

  bool showPassword = false;

  void toggleShowPassword() {
    setState(() {
      showPassword = !showPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: [Colors.white, Colors.white, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Image.asset("images/afrikk_prev_ui.png", height: 240),
                const SizedBox(height: 3),
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
                      // Email Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.email),
                            labelText: 'Email',
                            labelStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
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

                      // Password Field
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        child: TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: const BorderSide(color: Colors.black),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            labelText: 'Password',
                            labelStyle: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                            ),
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: toggleShowPassword,
                            ),
                          ),
                          obscureText: !showPassword,
                          controller: _passwordTextController,
                          validator: (valuePassword) {
                            if (valuePassword!.length < 6) {
                              return "Password must be at least 6 characters.";
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Login Button (Reactive)
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

                      // Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Forgot your login details? ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.to(() => const ResetPasswordScreen());
                            },
                            child: const Text(
                              'Get Help!',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // Divider
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
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
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

                      // Sign Up Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Join this Community? ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Get.to(() => const SignupScreen());
                            },
                            child: const Text(
                              'Sign up now',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
