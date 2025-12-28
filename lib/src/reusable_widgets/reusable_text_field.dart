import 'package:flutter/material.dart';
import 'package:padizdoctor/src/reusable_widgets/view_pass_button.dart';

TextFormField reusableTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller,
    {required int borderRadius,
    required bool passwordVisible,
    required VoidCallback onTogglePassword,
    FormFieldValidator<String>? validator}) {
  return TextFormField(
    controller: controller,
    obscureText: isPasswordType ? !passwordVisible : false,
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
      ),
      suffixIcon: isPasswordType
          ? ViewPasswordButton(
              isVisible: passwordVisible,
              onToggle: onTogglePassword,
            )
          : null,
      labelText: text,
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(width: 0, style: BorderStyle.none)),
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
    validator: validator,
  );
}
