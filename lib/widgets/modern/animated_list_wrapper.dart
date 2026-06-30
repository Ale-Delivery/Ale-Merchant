import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedListWrapper extends StatelessWidget {
  final List<Widget> children;
  final bool isHorizontal;
  
  const AnimatedListWrapper({
    Key? key,
    required this.children,
    this.isHorizontal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isHorizontal
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children.animate(interval: 50.ms).fade(duration: 300.ms).slideX(
                    begin: 0.2,
                    end: 0,
                    duration: 400.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.animate(interval: 50.ms).fade(duration: 300.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
          );
  }
}
