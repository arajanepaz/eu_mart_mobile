import 'package:flutter/material.dart';

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path.lineTo(0, size.height - 70);

    path.quadraticBezierTo(
      size.width * .25,
      size.height,
      size.width * .5,
      size.height - 40,
    );

    path.quadraticBezierTo(
      size.width * .75,
      size.height - 90,
      size.width,
      size.height - 30,
    );

    path.lineTo(size.width, 0);

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
