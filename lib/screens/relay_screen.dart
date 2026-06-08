import 'package:flutter/material.dart';

import '../models/button_config.dart';
import '../widgets/grouped_buttons_view.dart';

/// CE-REL8 power control screen. Buttons are user-defined (settings → 버튼 편집).
///
/// Power buttons default to a 2-second press-and-hold (set per button), so an
/// accidental touch can never switch power.
class PowerScreen extends StatelessWidget {
  const PowerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupedButtonsView(
      screen: ButtonScreen.power,
      header: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(
          children: [
            Icon(Icons.touch_app, size: 18),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                '길게 누르기가 설정된 전원 버튼은 2초간 눌러야 작동합니다.',
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
