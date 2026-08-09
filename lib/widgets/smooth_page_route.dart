import 'package:flutter/material.dart';

class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  SmoothPageRoute({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.06, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            final slideTween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: curve));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
        );
}
