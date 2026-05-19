import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/features/auth/services/auth_service.dart';
import 'package:padizdoctor/features/auth/screens/forgot_password_dialog.dart';
import 'package:padizdoctor/core/utils/colors_utils.dart';
import 'package:padizdoctor/core/widgets/reusable_text_field.dart';
import 'package:padizdoctor/features/settings/services/settings_controller.dart';
import 'package:padizdoctor/model/model.dart';

import '../../../core/widgets/reusable_widget.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen(BuildContext context,
      {super.key, required this.controller});

  final SettingsController controller;
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _emailTextController = TextEditingController();
  bool passwordVisible = false;
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

  Future<void> _handleEmailSignIn() async {
    _setLoading(true, 'Signing in...');
    try {
      final value = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );
      if (!mounted) return;
      if (value.user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        _setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _setLoading(false);
      String message = 'Login failed. Please try again.';
      if (error.code == 'invalid-credential') {
        message =
            'Invalid credentials. Please check your email and password.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      debugPrint("FirebaseAuthException: ${error.toString()}");
    } catch (error) {
      if (!mounted) return;
      _setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred.')),
      );
      debugPrint("Error: ${error.toString()}");
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true, 'Connecting to Google...');
    try {
      final value = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;
      if (value?.user != null) {
        Navigator.pushReplacementNamed(context, "/home");
      } else {
        _setLoading(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please try again.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      _setLoading(false);
      debugPrint("Google Sign-In Error: ${error.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, screenHeight * 0.2, 20, 0),
                child: Column(
                  children: <Widget>[
                    // Logo
                    logoWidget("assets/images/logo2.png"),
                    const SizedBox(height: 30),

                    // Username TextField
                    reusableTextField(
                        "Enter Email", Icons.person_outline, false,
                        _emailTextController,
                        borderRadius: 16,
                        passwordVisible: false,
                        onTogglePassword: () {}),
                    const SizedBox(height: 20),

                    // Password TextField
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
                    const SizedBox(height: 20),

                    // Sign In Button
                    signInSignUpButton(
                      context,
                      true,
                      _isLoading ? () {} : _handleEmailSignIn,
                      buttonColor: Colors.white,
                      textColor: hexStringToColor("3E8E41"),
                      borderRadius: 12,
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => _showForgotPasswordDialog(),
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Sign Up option
                    signUpOption(),
                    const SizedBox(height: 20),

                    // Google Sign In with bottom spacing
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: hexStringToColor("3E8E41"),
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
            Navigator.pushNamed(context, AppRoutes.signup);
          },
          child: const Text(
            " Sign Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        )
      ],
    );
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ForgotPasswordDialog(
        initialEmail: _emailTextController.text.trim(),
      ),
    );
  }
}
