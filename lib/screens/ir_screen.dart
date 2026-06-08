import 'package:flutter/material.dart';

import '../actions/action_ids.dart';
import '../widgets/control_button.dart';
import '../widgets/section_card.dart';

/// CE-IRS4 IR control screen: TV1, TV2 and projector (spec §10.2).
/// All IR buttons are single-tap.
class IrScreen extends StatelessWidget {
  const IrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: const [
        _TvSection(
          title: 'TV 1',
          powerOn: ActionIds.tv1PowerOn,
          powerOff: ActionIds.tv1PowerOff,
          hdmi1: ActionIds.tv1Hdmi1,
          hdmi2: ActionIds.tv1Hdmi2,
          hdmi3: ActionIds.tv1Hdmi3,
          hdmi4: ActionIds.tv1Hdmi4,
          volUp: ActionIds.tv1VolUp,
          volDown: ActionIds.tv1VolDown,
          mute: ActionIds.tv1Mute,
        ),
        _TvSection(
          title: 'TV 2',
          powerOn: ActionIds.tv2PowerOn,
          powerOff: ActionIds.tv2PowerOff,
          hdmi1: ActionIds.tv2Hdmi1,
          hdmi2: ActionIds.tv2Hdmi2,
          hdmi3: ActionIds.tv2Hdmi3,
          hdmi4: ActionIds.tv2Hdmi4,
          volUp: ActionIds.tv2VolUp,
          volDown: ActionIds.tv2VolDown,
          mute: ActionIds.tv2Mute,
        ),
        SectionCard(
          title: 'PROJECTOR',
          child: ButtonGrid(
            children: [
              ControlButton(
                label: 'POWER ON',
                actionId: ActionIds.projectorPowerOn,
              ),
              ControlButton(
                label: 'POWER OFF',
                actionId: ActionIds.projectorPowerOff,
                danger: true,
              ),
              ControlButton(label: 'HDMI 1', actionId: ActionIds.projectorHdmi1),
              ControlButton(label: 'HDMI 2', actionId: ActionIds.projectorHdmi2),
              ControlButton(label: 'MENU', actionId: ActionIds.projectorMenu),
              ControlButton(label: 'BACK', actionId: ActionIds.projectorBack),
            ],
          ),
        ),
      ],
    );
  }
}

/// A full TV control block: power, HDMI 1-4, volume and mute.
class _TvSection extends StatelessWidget {
  const _TvSection({
    required this.title,
    required this.powerOn,
    required this.powerOff,
    required this.hdmi1,
    required this.hdmi2,
    required this.hdmi3,
    required this.hdmi4,
    required this.volUp,
    required this.volDown,
    required this.mute,
  });

  final String title;
  final String powerOn;
  final String powerOff;
  final String hdmi1;
  final String hdmi2;
  final String hdmi3;
  final String hdmi4;
  final String volUp;
  final String volDown;
  final String mute;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: ButtonGrid(
        children: [
          ControlButton(label: 'POWER ON', actionId: powerOn),
          ControlButton(label: 'POWER OFF', actionId: powerOff, danger: true),
          ControlButton(label: 'HDMI 1', actionId: hdmi1),
          ControlButton(label: 'HDMI 2', actionId: hdmi2),
          ControlButton(label: 'HDMI 3', actionId: hdmi3),
          ControlButton(label: 'HDMI 4', actionId: hdmi4),
          ControlButton(label: 'VOL +', actionId: volUp),
          ControlButton(label: 'VOL -', actionId: volDown),
          ControlButton(label: 'MUTE', actionId: mute),
        ],
      ),
    );
  }
}
