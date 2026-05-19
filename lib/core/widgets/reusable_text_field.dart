import 'package:flutter/material.dart';
import 'package:padizdoctor/core/widgets/view_pass_button.dart';

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
    style: const TextStyle(color: Colors.black54),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      fillColor: Colors.white,
      suffixIcon: isPasswordType
          ? ViewPasswordButton(
              isVisible: passwordVisible,
              onToggle: onTogglePassword,
            )
          : null,
      labelText: text,
      labelStyle: const TextStyle(color: Colors.black45),
      errorStyle:
          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
