import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
        ),
        const Align(
          alignment: AlignmentDirectional(0.86, 0.98),
          child: Icon(
            Icons.circle_rounded,
            color: Color(0x4DF9CF58),
            size: 120,
          ),
        ),
        const Align(
          alignment: AlignmentDirectional(-1.36, 0.48),
          child: Icon(
            Icons.circle_rounded,
            color: Color(0x4CEE8B60),
            size: 120,
          ),
        ),
        const Align(
          alignment: AlignmentDirectional(1.37, 0.03),
          child: Icon(
            Icons.circle_rounded,
            color: Color(0x4D39D2C0),
            size: 120,
          ),
        ),
        const Align(
          alignment: AlignmentDirectional(0.35, 0.46),
          child: Icon(
            Icons.circle_rounded,
            color: Color(0x4C39A7D2),
            size: 60,
          ),
        ),
        const Align(
          alignment: AlignmentDirectional(-0.67, 0.8),
          child: Icon(
            Icons.circle_rounded,
            color: Color(0x4C73D239),
            size: 80,
          ),
        ),
      ],
    );
  }
}