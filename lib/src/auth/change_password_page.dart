import 'package:flutter/material.dart';
import 'package:padizdoctor/src/reusable_widgets/reusable_text_field.dart';
import 'package:padizdoctor/src/reusable_widgets/text_button.dart';
import 'package:padizdoctor/src/user/user_profile/user_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool currentPasswordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: TextColorButton(Colors.green, "Update Password", () async {
          if (_formKey.currentState!.validate()) {
            // Process data.
            final result = await UserService().updatePassword(
                _passwordController.text, _newPasswordController.text);
            if (result == "Password updated successfully!") {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Password updated successfully'),
                ));
                Navigator.pop(context);
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result),
                ));
              }
            }
          }
        }),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 40,
              ),
              Text(
                  "Create a new password for your account. Ensure it differs from previous passwords for security."),
              SizedBox(height: 20),
              Text("Current Password",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 20,
              ),
              reusableTextField(
                "Enter Password",
                Icons.lock_outline,
                true,
                _passwordController,
                borderRadius: 16,
                passwordVisible: currentPasswordVisible,
                onTogglePassword: () {
                  setState(() {
                    currentPasswordVisible = !currentPasswordVisible;
                  });
                },
                validator: (val) {
                  if (val!.isEmpty) return 'Empty';

                  return null;
                },
              ),
              SizedBox(height: 20),
              Divider(),
              SizedBox(height: 20),
              Text("New Password",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 20,
              ),
              reusableTextField(
                "At least 6 characters",
                Icons.lock_outline,
                true,
                _newPasswordController,
                borderRadius: 16,
                passwordVisible: newPasswordVisible,
                onTogglePassword: () {
                  setState(() {
                    newPasswordVisible = !newPasswordVisible;
                  });
                },
              ),
              SizedBox(height: 20),
              Text("Confirm New Password",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(
                height: 20,
              ),
              reusableTextField(
                "Re-enter New Password",
                Icons.lock_outline,
                true,
                _confirmPasswordController,
                borderRadius: 16,
                passwordVisible: confirmPasswordVisible,
                onTogglePassword: () {
                  setState(() {
                    confirmPasswordVisible = !confirmPasswordVisible;
                  });
                },
                validator: (val) {
                  if (val!.isEmpty) return 'Empty';
                  if (val != _newPasswordController.text) return 'Not Match';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
