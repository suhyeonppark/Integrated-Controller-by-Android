import 'package:flutter/material.dart';

import '../actions/action_ids.dart';
import '../widgets/control_button.dart';
import '../widgets/section_card.dart';

/// Operator home screen with the high-level macro / mode buttons (spec §10.1).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: const [
            SectionCard(
              title: '전체 전원',
              child: ButtonGrid(
                tileWidth: kTileWidth,
                children: [
                  ControlButton(
                    label: '전체 전원 ON',
                    actionId: ActionIds.systemOn,
                    icon: Icons.power_settings_new,
                  ),
                  ControlButton(
                    label: '전체 전원 OFF',
                    actionId: ActionIds.systemOff,
                    icon: Icons.power_off,
                    danger: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
