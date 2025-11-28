import 'package:flutter/material.dart';

class PomodoroLogo extends StatelessWidget {
  final double size;
  final String? label;

  /// If [imageUrl] is provided, the widget will try to show that image inside the
  /// circular badge. If the network image fails, it falls back to the gradient + icon.
  final String? imageUrl;
  const PomodoroLogo({super.key, this.size = 40, this.label, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.18 * 255).round()),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Builder(
              builder: (context) {
                // Prefer provided imageUrl; if null, show the gradient/icon fallback
                final url =
                    imageUrl ??
                    'https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/14/a0/b4/14a0b468-7bd9-84a1-f8d7-2413bce12dbe/AppIcon-0-0-1x_U007epad-0-1-85-220.png/512x512bb.jpg';

                return Image.network(
                  url,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback: gradient circle with timer icon
                    return Container(
                      width: size,
                      height: size,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6EA98D), Color(0xFF3D7A61)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: size * 0.56,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ],
    );
  }
}
