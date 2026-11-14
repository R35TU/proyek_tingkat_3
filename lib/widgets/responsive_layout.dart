import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double desktop = 900;
  static const double maxAppWidth = 1600;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
}

class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= ResponsiveBreakpoints.maxAppWidth) {
          return child;
        }

        return Center(
          child: SizedBox(
            width: ResponsiveBreakpoints.maxAppWidth,
            child: child,
          ),
        );
      },
    );
  }
}
