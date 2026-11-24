import 'dart:async';

import 'package:flutter/material.dart';

/// Widget yang muncul bertahap (fade + geser ke atas) setelah [delay].
/// Dipakai untuk entrance login, grid produk, dan kartu statistik
/// supaya terasa halus tanpa mengubah layout.
class StaggerEnter extends StatefulWidget {
  const StaggerEnter({
    super.key,
    required this.delay,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.offset = 0.1,
  });

  /// Jeda sebelum animasi mulai.
  final Duration delay;

  /// Pergeseran awal sebagai fraksi tinggi widget (0.1 = 10%).
  final double offset;

  final Duration duration;
  final Widget child;

  @override
  State<StaggerEnter> createState() => _StaggerEnterState();
}

class _StaggerEnterState extends State<StaggerEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = curved;
    _slide = Tween<Offset>(begin: Offset(0, widget.offset), end: Offset.zero)
        .animate(curved);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
