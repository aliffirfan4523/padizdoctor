import 'package:flutter/material.dart';

import '../../../core/widgets/magnifying_glass.dart';

class ImageQualityLoading extends StatelessWidget {
  final double progress; // 0.0 – 1.0
  final int percent; // 0 – 100
  final ImageProvider image;
  final VoidCallback? onCancel;

  const ImageQualityLoading({
    super.key,
    required this.progress,
    required this.percent,
    required this.image,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Checking Image Quality",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Performing blur check...",
            ),

            const SizedBox(height: 30),

            // Image Preview
            Container(
                height: 280,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: image,
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withOpacity(0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),

                    // magnifying glass animation
                    const Center(
                      child: MagnifyingGlassAnimation(),
                    ),
                  ],
                )),

            const SizedBox(height: 16),

            const Text(
              "Please keep the app open",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
