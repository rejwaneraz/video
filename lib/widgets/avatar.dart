import 'dart:io';

import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.path,
    required this.name,
    this.size = 72,
    this.ring = false,
  });

  final String? path;
  final String name;
  final double size;
  final bool ring;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFF2D78);
    final hasImage = path != null && File(path!).existsSync();

    Widget child = ClipOval(
      child: hasImage
          ? Image.file(File(path!), width: size, height: size, fit: BoxFit.cover)
          : Container(
              width: size,
              height: size,
              color: Colors.white12,
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );

    if (ring) {
      child = Container(
        padding: EdgeInsets.all(size * 0.045),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [pink, Colors.deepPurpleAccent],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
          ),
          padding: EdgeInsets.all(size * 0.03),
          child: child,
        ),
      );
    }

    return SizedBox(width: ring ? size * 1.16 : size, child: child);
  }
}
