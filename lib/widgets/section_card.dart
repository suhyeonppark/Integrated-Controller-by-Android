import 'package:flutter/material.dart';

/// A titled card grouping related control buttons (e.g. "전원", "프롬프터 TV").
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Minimal: no boxed card — a quiet section label over white tile buttons
    // floating on the grey page background, so each tile reads clearly.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF8A8F98),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Lays out control buttons in a responsive grid with [columns] per row and a
/// fixed button height, so buttons look consistent on any screen width.
class ButtonGrid extends StatelessWidget {
  const ButtonGrid({
    super.key,
    required this.children,
    this.columns = 2,
    this.buttonHeight = 92,
  });

  final List<Widget> children;
  final int columns;

  /// Fixed height of each button cell.
  final double buttonHeight;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        mainAxisExtent: buttonHeight,
      ),
      itemBuilder: (context, i) => children[i],
    );
  }
}
