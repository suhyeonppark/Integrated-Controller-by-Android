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
      padding: const EdgeInsets.all(8),
      children: const [
        SectionCard(
          title: '시스템',
          child: ButtonGrid(
            children: [
              ControlButton(
                label: '시스템 ON',
                actionId: ActionIds.systemOn,
                icon: Icons.power_settings_new,
              ),
              ControlButton(
                label: '시스템 OFF',
                actionId: ActionIds.systemOff,
                icon: Icons.power_off,
                danger: true,
              ),
              ControlButton(
                label: '발표 모드',
                actionId: ActionIds.presentationMode,
                icon: Icons.slideshow,
              ),
              ControlButton(
                label: '대기 모드',
                actionId: ActionIds.standbyMode,
                icon: Icons.bedtime,
              ),
            ],
          ),
        ),
        SectionCard(
          title: '디스플레이',
          child: ButtonGrid(
            children: [
              ControlButton(
                label: '전체 디스플레이 ON',
                actionId: ActionIds.allDisplayOn,
                icon: Icons.tv,
              ),
              ControlButton(
                label: '전체 디스플레이 OFF',
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
