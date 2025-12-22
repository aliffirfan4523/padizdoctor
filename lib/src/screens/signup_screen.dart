import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/src/homepage/homepage_screen.dart';
import 'package:padizdoctor/src/reusable_widgets/reusable_widget.dart';

import '../utils/colors_utils.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();

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
                reusableTextField(
                  "Enter Name",
                  Icons.person_outline,
                  false,
                  _userNameTextController,
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                  hintColor: Colors.white70,
                  borderRadius: 16,
                ),
                const SizedBox(height: 20),

                // Email
                reusableTextField(
                  "Enter Email",
                  Icons.email_outlined,
                  false,
                  _emailTextController,
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                  hintColor: Colors.white70,
                  borderRadius: 16,
                ),
                const SizedBox(height: 20),

                // Password
                reusableTextField(
                  "Enter Password",
                  Icons.lock_outline,
                  true,
                  _passwordTextController,
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                  hintColor: Colors.white70,
                  borderRadius: 16,
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
                        await docRef.set({
                          'email': user.email,
                          'fullName': _userNameTextController.text.trim() ?? '',
                          'isAdmin': false,
                          'lastActive': DateTime.now(),
                          'phone': '',
                          'profilePicture': '',
                        });
                      }

                      // 4. Navigate after success
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomepageView(),
                        ),
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
