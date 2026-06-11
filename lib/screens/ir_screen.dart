import 'package:flutter/material.dart';

import '../actions/action_ids.dart';
import '../models/button_config.dart';
import '../widgets/control_button.dart';
import '../widgets/grouped_buttons_view.dart';
import '../widgets/section_card.dart';

/// CE-IRS4 IR control screen. Buttons are user-defined (settings → 버튼 편집)
/// and rendered grouped by section. All IR buttons are single-tap.
class IrScreen extends StatelessWidget {
  const IrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupedButtonsView(
      screen: ButtonScreen.ir,
      header: SectionCard(
        title: 'TV 전체',
        child: ButtonGrid(
          tileWidth: kTileWidth,
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
    );
  }
}
