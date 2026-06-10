import 'package:flutter/material.dart';

import '../actions/action_ids.dart';
import '../widgets/control_button.dart';
import '../widgets/section_card.dart';

/// Operator home screen with the high-level macro / mode buttons (spec §10.1).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: const [
        SectionCard(
          title: '전체 시스템',
          child: ButtonGrid(
            buttonHeight: 112,
            children: [
              ControlButton(
                label: '전체 시스템 ON',
                actionId: ActionIds.systemOn,
                icon: Icons.power_settings_new,
              ),
              ControlButton(
                label: '전체 시스템 OFF',
                actionId: ActionIds.systemOff,
                icon: Icons.power_off,
                danger: true,
              ),
            ],
          ),
        ),
        SectionCard(
          title: '디스플레이',
          child: ButtonGrid(
            buttonHeight: 112,
            children: [
              ControlButton(
                label: 'TV 전체 ON',
                actionId: ActionIds.allDisplayOn,
                icon: Icons.tv,
              ),
              ControlButton(
                label: 'TV 전체 OFF',
                actionId: ActionIds.allDisplayOff,
                icon: Icons.tv_off,
                danger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
