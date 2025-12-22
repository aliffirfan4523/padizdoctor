import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:padizdoctor/src/homepage/homepage_screen.dart';
import 'package:padizdoctor/src/screens/auth_service.dart';
import 'package:padizdoctor/src/screens/signup_screen.dart';

import '../reusable_widgets/reusable_widget.dart';
import '../utils/colors_utils.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen(BuildContext context, {Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();

  Future<void> _signInToGoogle(GoogleSignInAccount user) async {
    final googleAuth = await user.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            padding: EdgeInsets.fromLTRB(20, screenHeight * 0.2, 20, 0),
            child: Column(
              children: <Widget>[
                // Logo
                logoWidget("assets/images/logo2.png"),
                const SizedBox(height: 30),

                // Username TextField
                reusableTextField(
                  "Enter Email",
                  Icons.person_outline,
                  false,
                  _emailTextController,
                  textColor: Colors.white,
                  iconColor: Colors.white70,
                  hintColor: Colors.white70,
                  borderRadius: 16,
                ),
                const SizedBox(height: 20),

                // Password TextField
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
                const SizedBox(height: 20),

                // Sign In Button
                signInSignUpButton(
                  context,
                  true,
                  () {
                    FirebaseAuth.instance
                        .signInWithEmailAndPassword(
                            email: _emailTextController.text,
                            password: _passwordTextController.text)
                        .then((value) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomepageView()));
                    }).onError((error, stackTrace) {
                      print("Error ${error.toString()}");
                    });
                  },
                  buttonColor: Colors.white,
                  textColor: hexStringToColor("3E8E41"),
                  borderRadius: 16,
                ),
                const SizedBox(height: 20),

                // Sign Up option
                signUpOption(),
                const SizedBox(height: 20),

                // Google Sign In with bottom spacing
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0),
                  child: ElevatedButton(
                    onPressed: AuthService.instance.signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // white button
                      foregroundColor: hexStringToColor("3E8E41"), // green text
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Row signUpOption() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have account?",
            style: TextStyle(color: Colors.white70)),
        GestureDetector(
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SignUpScreen()));
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }
}
