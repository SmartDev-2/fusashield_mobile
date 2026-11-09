import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';

/// Daftar ala iOS "inset grouped" versi dark glassmorphism.
class GlassGroup extends StatelessWidget {
  final List<Widget> children;

  const GlassGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: 26,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 70,
                color: Colors.white.o(0.08),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
