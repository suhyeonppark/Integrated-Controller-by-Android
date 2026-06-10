import 'package:flutter/material.dart';

import '../actions/action_models.dart';
import '../app_state.dart';
import '../models/button_config.dart';
import 'control_button.dart';
import 'section_card.dart';

/// Renders all user-defined buttons for a [screen], grouped into [SectionCard]s
/// by `group` and laid out in a [ButtonGrid]. Data-driven: edits made in the
/// settings button editor appear here immediately.
class GroupedButtonsView extends StatelessWidget {
  const GroupedButtonsView({
    super.key,
    required this.screen,
    this.header,
    this.columns = 2,
  });

  final ButtonScreen screen;

  /// Optional widget shown above the first section (e.g. a hint).
  final Widget? header;
  final int columns;

  /// Whether [b] represents the relay's current latched state, so the button
  /// can be highlighted. Only latch ON/OFF relay buttons have a meaningful
  /// state; momentary pulses and IR buttons never do.
  bool _isActive(AppState state, ButtonConfig b) {
    if (b.type != ButtonType.relay) return false;
    final on = state.relayIsOn(b.relay);
    if (on == null) return false;
    return switch (b.relayMode) {
      RelayMode.latchClose => on == true,
      RelayMode.latchOpen => on == false,
      RelayMode.momentary => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final groups = state.buttonsByGroup(screen);

    if (groups.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          ?header,
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                '버튼이 없습니다.\n설정 탭에서 버튼을 추가하세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        ?header,
        for (final entry in groups.entries)
          SectionCard(
            title: entry.key,
            child: ButtonGrid(
              columns: columns,
              children: [
                for (final b in entry.value)
                  ControlButton(
                    label: b.label,
                    actionId: b.id,
                    danger: b.danger,
                    active: _isActive(state, b),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
