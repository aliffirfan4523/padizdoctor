import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:padizdoctor/features/auth/services/auth_service.dart';
import 'package:padizdoctor/core/widgets/theme_toggle_button.dart';
import 'package:padizdoctor/core/widgets/text_button.dart';
import 'package:padizdoctor/features/settings/services/settings_controller.dart';
import 'package:padizdoctor/features/user/services/user_service.dart';

import '../../../model/model.dart';

class MyProfile extends StatefulWidget {
  MyProfile({super.key, required this.controller, required this.user});
  var user = {};
  final SettingsController controller;
  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final _formKey = GlobalKey<FormState>();
  UserService service = UserService();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  bool isNameChanged = false;
  bool isEmailChanged = false;

  void loadUserData() {
    fullNameController.text = widget.user["fullName"] ?? "";
    emailController.text = widget.user["email"] ?? "";
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with Gradient
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
              ),
              Positioned(
                bottom: -50,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.white,
                    backgroundImage: CachedNetworkImageProvider(
                      widget.user["profilePicture"] ??
                          'https://res.cloudinary.com/dijcgzy3v/image/upload/v1766859823/cld-sample-2.jpg',
                    ),
                    onBackgroundImageError: (_, __) =>
                        const Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 65), // Space for the avatar overhang
          Text(
            widget.user["fullName"] ?? "Guest User",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            widget.user["email"] ?? "",
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(
                      "Personal Information", Icons.person_outline),
                  _buildCard(
                    child: Column(
                      children: [
                        _buildTextField(
                          label: "Full Name",
                          controller: fullNameController,
                          isChanged: isNameChanged,
                          onClear: () {
                            loadUserData();
                            setState(() => isNameChanged = false);
                          },
                          onChanged: (value) {
                            setState(() {
                              isNameChanged = widget.user["fullName"] != value;
                            });
                          },
                        ),
                        Divider(
                            height: 1,
                            color: Colors.grey.withValues(alpha: 0.2)),
                        _buildTextField(
                          label: "Email Address",
                          controller: emailController,
                          isChanged: isEmailChanged,
                          isEmail: true,
                          onClear: () {
                            loadUserData();
                            setState(() => isEmailChanged = false);
                          },
                          onChanged: (value) {
                            setState(() {
                              isEmailChanged = widget.user["email"] != value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildSectionHeader("Account Settings", Icons.security),
                  _buildCard(
                    child: Column(
                      children: [
                        if (AuthService.instance.isGoogleOnly)
                          _buildListTile(
                            icon: Icons.link,
                            title: "Set Password",
                            subtitle: "Enable email + password login",
                            onTap: _showSetPasswordDialog,
                          ),
                        if (!AuthService.instance.isGoogleOnly)
                          _buildListTile(
                            icon: Icons.lock_outline,
                            title: "Change Password",
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.changePassword),
                          ),
                        if (!AuthService.instance.isGoogleOnly) ...[
                          Divider(
                              height: 1,
                              color: Colors.grey.withValues(alpha: 0.2)),
                          _buildListTile(
                            icon: Icons.lock_reset,
                            title: "Forgot Password?",
                            subtitle: "Send a reset link to your email",
                            onTap: () async {
                              final email =
                                  FirebaseAuth.instance.currentUser?.email ??
                                      '';
                              if (email.isEmpty) return;
                              final result = await AuthService.instance
                                  .sendPasswordReset(email);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(result == 'success'
                                        ? 'Password reset email sent to $email'
                                        : result)),
                              );
                            },
                          ),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildSectionHeader("App Settings", Icons.settings_outlined),
                  _buildCard(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: const Text("Theme",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(FluentIcons.paint_brush_24_regular,
                            color: Colors.blue),
                      ),
                      trailing: ToggleButtons(
                        borderRadius: BorderRadius.circular(1000),
                        constraints:
                            const BoxConstraints(minHeight: 36, minWidth: 48),
                        isSelected: options
                            .map((option) =>
                                widget.controller.themeMode == option.theme)
                            .toList(),
                        onPressed: (index) {
                          widget.controller
                              .updateThemeMode(options[index].theme);
                        },
                        children:
                            options.map((option) => option.widget).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Action Buttons
                  if (isNameChanged || isEmailChanged)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          service.updateUserInfo(
                            fullNameController.text,
                            emailController.text,
                          );
                          setState(() {
                            isEmailChanged = false;
                            isNameChanged = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Profile updated!")));
                        }
                      },
                      child: const Text("Save Changes",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  if (isNameChanged || isEmailChanged)
                    const SizedBox(height: 15),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.red.withValues(alpha: 0.1)
                          : Colors.red.shade50,
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text("Log Out",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (_) => false,
                      );
                      await AuthService.instance.signOut();
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool isChanged,
    required VoidCallback onClear,
    required Function(String) onChanged,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          suffixIcon: isChanged
              ? IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: onClear,
                  tooltip: "Restore original",
                )
              : null,
        ),
        validator: isEmail
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                }
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'Invalid email address';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.green.shade700),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showSetPasswordDialog() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Set Password"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Create a password so you can also sign in with your email and password.",
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);

                final result = await AuthService.instance
                    .linkEmailPassword(passwordController.text);

                if (!mounted) return;
                if (result == 'success') {
                  setState(
                      () {}); // Refresh UI to show "Change Password" instead
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Password set! You can now sign in with email and password."),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                }
              },
              child: const Text("Set Password"),
            ),
          ],
        ),
      ),
    );
  }
}
