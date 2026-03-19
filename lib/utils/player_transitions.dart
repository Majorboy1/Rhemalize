import 'package:flutter/material.dart';

class PlayerTransition {
  static Route slideUpRoute(Widget page) {
    return PageRouteBuilder(
      // The page we are going to (FullScreenPlayer)
      pageBuilder: (context, animation, secondaryAnimation) => page,

      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // This offset defines the "Slide from Bottom" logic
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;

        // We apply the 'easeOutQuart' curve here to make it feel premium
        // It starts fast and settles into place smoothly
        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: Curves.easeOutQuart),
        );

        // We also want a slight fade-in for that "modern" look
        var fadeTween = CurveTween(curve: Curves.easeIn);

        return SlideTransition(
          position: animation.drive(slideTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
      // 600ms is the "sweet spot" for a full-screen transition
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 500),
    );
  }
}
