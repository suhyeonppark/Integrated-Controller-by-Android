import 'package:flutter/material.dart';

import '../actions/action_ids.dart';
import '../widgets/control_button.dart';
import '../widgets/section_card.dart';

/// CE-REL8 sequential-power (순차전원) control screen.
///
/// Power buttons require a 2-second press-and-hold to activate (not a single
/// tap), so an accidental touch can never switch power. The deliberate hold
/// replaces the confirmation dialog.
class PowerScreen extends StatelessWidget {
  const PowerScreen({super.key});

  /// Hold duration for power actions.
  static const int _holdMs = 2000;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              Icon(Icons.touch_app, size: 18),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  '전원 버튼은 오작동 방지를 위해 2초간 길게 눌러야 작동합니다.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: '순차전원 · 전체',
          child: ButtonGrid(
            children: [
              ControlButton(
                label: '전체 ON',
                actionId: ActionIds.seqAllOn,
                icon: Icons.power_settings_new,
                holdMs: _holdMs,
              ),
              ControlButton(
                label: '전체 OFF',
                actionId: ActionIds.seqAllOff,
                icon: Icons.power_off,
                danger: true,
                holdMs: _holdMs,
              ),
            ],
          ),
        ),
        SectionCard(
          title: '순차전원 · 개별',
          child: ButtonGrid(
            children: [
              ControlButton(
                label: '순차 1 ON',
                actionId: ActionIds.seq1On,
                holdMs: _holdMs,
              ),
              ControlButton(
                label: '순차 1 OFF',
                actionId: ActionIds.seq1Off,
                danger: true,
                holdMs: _holdMs,
              ),
              ControlButton(
                label: '순차 2 ON',
                actionId: ActionIds.seq2On,
                holdMs: _holdMs,
              ),
              ControlButton(
                label: '순차 2 OFF',
                actionId: ActionIds.seq2Off,
                danger: true,
                holdMs: _holdMs,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
