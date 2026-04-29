import 'package:flutter/material.dart';

class MagnifyingGlassAnimation extends StatefulWidget {
  const MagnifyingGlassAnimation({super.key});

  @override
  State<MagnifyingGlassAnimation> createState() =>
      _MagnifyingGlassAnimationState();
}

class _MagnifyingGlassAnimationState extends State<MagnifyingGlassAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _position;
  late Animation<double> _rotation;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _position = Tween<Offset>(
      begin: const Offset(-0.2, 0.0),
      end: const Offset(0.2, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _rotation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(_controller);

    _scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _position,
      child: RotationTransition(
        turns: _rotation,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.25),
            ),
            child: const Icon(
              Icons.search,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
