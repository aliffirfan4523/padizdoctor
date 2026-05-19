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
  final TextEditingController _confirmPasswordTextController =
      TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _userNameTextController = TextEditingController();
  final userService = UserService();
  final _formKey = GlobalKey<FormState>();

  bool passwordVisible = false;
  bool confirmPasswordVisible = false;
  bool _isLoading = false;
  String _loadingMessage = '';

  void _setLoading(bool loading, [String message = '']) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _loadingMessage = message;
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _setLoading(true, 'Creating your account...');
    try {
      // 1. Create Auth user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailTextController.text.trim(),
        password: _passwordTextController.text.trim(),
      );

      User user = userCredential.user!;

      if (!mounted) return;
      _setLoading(true, 'Setting up your profile...');

      // 2. Firestore reference
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

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

      if (!mounted) return;

      // 4. Navigate after success
      Navigator.pushReplacementNamed(context, "/home");
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign up failed. Please try again.')),
      );
    } catch (e) {
      if (!mounted) return;
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            "Sign Up",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Stack(
          children: [
            // Main content
            Container(
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
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, screenHeight * 0.15, 20, 0),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        // Username
                        reusableTextField(
                            "Enter Name", Icons.person_outline, false,
                            _userNameTextController,
                            borderRadius: 16,
                            passwordVisible: false,
                            onTogglePassword: () {}),
                        const SizedBox(height: 20),

                        // Email
                        reusableTextField(
                            "Enter Email", Icons.email_outlined, false,
                            _emailTextController,
                            borderRadius: 16,
                            passwordVisible: false,
                            onTogglePassword: () {}, validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          if (!emailRegex.hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        }),
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
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password must be at least 6 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password
                        reusableTextField(
                          "Confirm Password",
                          Icons.lock_outline,
                          true,
                          _confirmPasswordTextController,
                          borderRadius: 16,
                          passwordVisible: confirmPasswordVisible,
                          onTogglePassword: () {
                            setState(() {
                              confirmPasswordVisible = !confirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value != _passwordTextController.text) {
                              return 'Passwords do not match.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Sign Up Button
                        signInSignUpButton(
                          context,
                          false,
                          _isLoading ? () {} : _handleSignUp,
                          buttonColor: Colors.white,
                          textColor: hexStringToColor("3E8E41"),
                          borderRadius: 12,
                        ),
                        const SizedBox(height: 20),

                        // Sign In option
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Already have an account?",
                                style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                " Sign In",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _loadingMessage,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ));
  }
}
