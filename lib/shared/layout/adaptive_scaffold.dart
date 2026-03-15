import 'package:flutter/material.dart';
import 'responsive_builder.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget mobile;
  final Widget desktop;
  final Widget? web;

  const AdaptiveScaffold({
    super.key,
    required this.mobile,
    required this.desktop,
    this.web,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: mobile,
      desktop: desktop,
      tablet: desktop, // For now, tablets get studio mode
    );
  }
}
