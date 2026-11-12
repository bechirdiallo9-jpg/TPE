import 'dart:io';

import 'package:flutter/material.dart';

/// Affiche une photo, qu'elle vienne des assets ou d'un fichier.
class PhotoView extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const PhotoView({super.key, required this.path, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    Widget broken(_, _, _) => Container(
          color: Colors.grey.shade300,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
    return path.startsWith('assets/')
        ? Image.asset(path, fit: fit, errorBuilder: broken)
        : Image.file(File(path), fit: fit, errorBuilder: broken);
  }
}

class LogoImage extends StatelessWidget {
  final String? path;

  const LogoImage({super.key, this.path});

  @override
  Widget build(BuildContext context) =>
      PhotoView(path: path ?? 'assets/logo_default.png', fit: BoxFit.contain);
}
