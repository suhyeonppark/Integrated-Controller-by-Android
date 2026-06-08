import 'package:flutter/material.dart';

import '../models/button_config.dart';
import '../widgets/grouped_buttons_view.dart';

/// CE-IRS4 IR control screen. Buttons are user-defined (settings → 버튼 편집)
/// and rendered grouped by section. All IR buttons are single-tap.
class IrScreen extends StatelessWidget {
  const IrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupedButtonsView(screen: ButtonScreen.ir);
  }
}
