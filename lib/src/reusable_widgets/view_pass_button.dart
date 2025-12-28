import 'package:flutter/material.dart';

class ViewPasswordButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;

  const ViewPasswordButton({
    super.key,
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isVisible ? Icons.visibility : Icons.visibility_off,
        color: Theme.of(context).primaryColorDark,
      ),
    );
  }
}
