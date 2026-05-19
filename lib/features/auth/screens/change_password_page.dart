import 'package:flutter/material.dart';
import 'package:padizdoctor/features/user/services/user_service.dart';

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

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildSecurityTipCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security_outlined,
            color: Colors.green.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Security Recommendations",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color:
                        isDark ? Colors.green.shade300 : Colors.green.shade800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Create a strong password that differs from your previous one. It must be at least 6 characters and should ideally include numbers or special symbols.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPasswordField({
    required String labelText,
    required String hintText,
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required IconData prefixIcon,
    FormFieldValidator<String>? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      enabled: !_isLoading,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        hintStyle: TextStyle(
          color: theme.hintColor.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: Colors.green.shade700,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          onPressed: onToggleVisibility,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.4)
            : Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.green.shade600,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade400,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.red.shade600,
            width: 2,
          ),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _submitChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserService().updatePassword(
        _passwordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;

      if (result == "Password updated successfully!") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Password updated successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.startsWith("Error:")
                        ? result.substring(6).trim()
                        : result,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text("An error occurred: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Change Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSecurityTipCard(),
                const SizedBox(height: 24),
                _buildCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPasswordField(
                        labelText: "Current Password",
                        hintText: "Enter your current password",
                        controller: _passwordController,
                        isVisible: _currentPasswordVisible,
                        prefixIcon: Icons.lock_open_outlined,
                        onToggleVisibility: () {
                          setState(() {
                            _currentPasswordVisible = !_currentPasswordVisible;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(thickness: 1, height: 1),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        labelText: "New Password",
                        hintText: "At least 6 characters",
                        controller: _newPasswordController,
                        isVisible: _newPasswordVisible,
                        prefixIcon: Icons.lock_outline,
                        onToggleVisibility: () {
                          setState(() {
                            _newPasswordVisible = !_newPasswordVisible;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your new password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          if (val == _passwordController.text) {
                            return 'New password must differ from current password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        labelText: "Confirm New Password",
                        hintText: "Re-enter your new password",
                        controller: _confirmPasswordController,
                        isVisible: _confirmPasswordVisible,
                        prefixIcon: Icons.gpp_good_outlined,
                        onToggleVisibility: () {
                          setState(() {
                            _confirmPasswordVisible = !_confirmPasswordVisible;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (val != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitChangePassword,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "Update Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
