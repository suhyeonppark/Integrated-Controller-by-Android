import 'package:flutter/material.dart';

import '../actions/action_ids.dart';
import '../models/button_config.dart';
import '../widgets/control_button.dart';
import '../widgets/grouped_buttons_view.dart';
import '../widgets/section_card.dart';

/// CE-REL8 power control screen. Buttons are user-defined (settings → 버튼 편집).
///
/// Risky power buttons show a confirmation popup before switching, so an
/// accidental touch can never switch power.
class PowerScreen extends StatelessWidget {
  const PowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupedButtonsView(
      screen: ButtonScreen.power,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: '전원 전체',
            child: ButtonGrid(
              tileWidth: kTileWidth,
              children: [
                ControlButton(
                  label: '전체 ON',
                  actionId: ActionIds.seqAllOn,
                  icon: Icons.power_settings_new,
                ),
                ControlButton(
                  label: '전체 OFF',
                  actionId: ActionIds.seqAllOff,
                  icon: Icons.power_off,
                  danger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
