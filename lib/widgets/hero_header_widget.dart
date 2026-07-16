import 'package:flutter/material.dart';

class HeroHeaderWidget extends StatelessWidget {
  final String imagePath;
  final double height;
  final double overlap;
  final Widget? child;

  const HeroHeaderWidget({
    Key? key,
    required this.imagePath,
    this.height = 200,
    this.overlap = 60,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark background extension
        Container(
          height: height - overlap,
          color: const Color(0xFF161622), // Matching the dark appbar theme
        ),
        // Hero Image Card
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: child != null
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: child,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
