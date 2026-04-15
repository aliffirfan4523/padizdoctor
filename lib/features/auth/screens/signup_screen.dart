import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/core/utils/colors_utils.dart';
import 'package:padizdoctor/core/widgets/reusable_text_field.dart';
import 'package:padizdoctor/core/widgets/reusable_widget.dart';
import 'package:padizdoctor/features/user/services/user_service.dart';

import '../../settings/services/settings_controller.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen(BuildContext context,
      {super.key, required this.controller});

  final SettingsController controller;
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final userService = UserService();

  bool passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Sign Up",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              hexStringToColor("A8E063"), // light green
              hexStringToColor("56AB2F"), // medium green
              hexStringToColor("3E8E41"), // dark green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 20),

                // Username
                reusableTextField("Enter Name", Icons.person_outline, false,
                    _userNameTextController,
                    borderRadius: 16,
                    passwordVisible: false,
                    onTogglePassword: () {}),
                const SizedBox(height: 20),

                // Email
                reusableTextField("Enter Email", Icons.email_outlined, false,
                    _emailTextController,
                    borderRadius: 16,
                    passwordVisible: false,
                    onTogglePassword: () {}),
                const SizedBox(height: 20),

                // Password
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                  borderRadius: 16,
                  passwordVisible: passwordVisible,
                  onTogglePassword: () {
                    setState(() {
                      passwordVisible = !passwordVisible;
                    });
                  },
                ),
                const SizedBox(height: 30),

                // Sign Up Button
                signInSignUpButton(
                  context,
                  false,
                  () async {
                    try {
                      // 1. Create Auth user
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                        email: _emailTextController.text.trim(),
                        password: _passwordTextController.text.trim(),
                      );

                      User user = userCredential.user!;

                      // 2. Firestore reference
                      final docRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid);

                      // 3. Check if Firestore document exists
                      final doc = await docRef.get();

                      if (!doc.exists) {
                        await userService.createUser(
                          firebaseUser: user,
                          fullName: _userNameTextController.text.trim() ?? '',
                          profilePicture: user.photoURL ??
                              'https://res.cloudinary.com/dijcgzy3v/image/upload/v1766859823/cld-sample-2.jpg',
                        );
                      }

                      // 4. Navigate after success
                      Navigator.pushReplacementNamed(
                        context,
                        "/home",
                      );
                    } on FirebaseAuthException catch (e) {
                      print("Auth Error: ${e.message}");
                    } catch (e) {
                      print("Unexpected Error: $e");
                    }
                  },
                  buttonColor: Colors.white,
                  textColor: hexStringToColor("3E8E41"),
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
