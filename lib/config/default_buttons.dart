import '../actions/action_ids.dart';
import '../actions/action_models.dart';
import '../models/button_config.dart';

/// The factory-default button set, used the first time the app runs (or after a
/// "기본값 복원"). Ids match the ones the built-in macros reference, so the home
/// macros keep working out of the box.
///
/// IR ports: 1 = TV1, 2 = TV2, 3 = projector. Relays: 1 = 전체, 2 = 순차1, 3 = 순차2.
List<ButtonConfig> defaultButtons() {
  var order = 0;
  final list = <ButtonConfig>[];

  ButtonConfig ir(
    String id,
    String group,
    String label,
    int port,
    String irName, {
    bool danger = false,
    bool confirm = false,
  }) {
    return ButtonConfig(
      id: id,
      label: label,
      screen: ButtonScreen.ir,
      group: group,
      order: order++,
      type: ButtonType.ir,
      irPort: port,
      irSendMode: IrSendMode.named,
      irName: irName,
      danger: danger,
      confirm: confirm,
    );
  }

  ButtonConfig power(
    String id,
    String group,
    String label,
    int relay,
    RelayMode mode, {
    bool danger = false,
  }) {
    return ButtonConfig(
      id: id,
      label: label,
      screen: ButtonScreen.power,
      group: group,
      order: order++,
      type: ButtonType.relay,
      relay: relay,
      relayMode: mode,
      danger: danger,
      holdMs: 2000, // power buttons require a 2-second hold
    );
  }

  // ---- TV 1 (IR port 1) ----
  list.addAll([
    ir(ActionIds.tv1PowerOn, 'TV 1', 'POWER ON', 1, 'POWER_ON'),
    ir(ActionIds.tv1PowerOff, 'TV 1', 'POWER OFF', 1, 'POWER_OFF', danger: true),
    ir(ActionIds.tv1Hdmi1, 'TV 1', 'HDMI 1', 1, 'HDMI1'),
    ir(ActionIds.tv1Hdmi2, 'TV 1', 'HDMI 2', 1, 'HDMI2'),
    ir(ActionIds.tv1Hdmi3, 'TV 1', 'HDMI 3', 1, 'HDMI3'),
    ir(ActionIds.tv1Hdmi4, 'TV 1', 'HDMI 4', 1, 'HDMI4'),
    ir(ActionIds.tv1VolUp, 'TV 1', 'VOL +', 1, 'VOL_UP'),
    ir(ActionIds.tv1VolDown, 'TV 1', 'VOL -', 1, 'VOL_DOWN'),
    ir(ActionIds.tv1Mute, 'TV 1', 'MUTE', 1, 'MUTE'),
  ]);

  // ---- TV 2 (IR port 2) ----
  list.addAll([
    ir(ActionIds.tv2PowerOn, 'TV 2', 'POWER ON', 2, 'POWER_ON'),
    ir(ActionIds.tv2PowerOff, 'TV 2', 'POWER OFF', 2, 'POWER_OFF', danger: true),
    ir(ActionIds.tv2Hdmi1, 'TV 2', 'HDMI 1', 2, 'HDMI1'),
    ir(ActionIds.tv2Hdmi2, 'TV 2', 'HDMI 2', 2, 'HDMI2'),
    ir(ActionIds.tv2Hdmi3, 'TV 2', 'HDMI 3', 2, 'HDMI3'),
    ir(ActionIds.tv2Hdmi4, 'TV 2', 'HDMI 4', 2, 'HDMI4'),
    ir(ActionIds.tv2VolUp, 'TV 2', 'VOL +', 2, 'VOL_UP'),
    ir(ActionIds.tv2VolDown, 'TV 2', 'VOL -', 2, 'VOL_DOWN'),
    ir(ActionIds.tv2Mute, 'TV 2', 'MUTE', 2, 'MUTE'),
  ]);

  // ---- Projector (IR port 3) ----
  list.addAll([
    ir(ActionIds.projectorPowerOn, 'PROJECTOR', 'POWER ON', 3, 'POWER_ON'),
    ir(ActionIds.projectorPowerOff, 'PROJECTOR', 'POWER OFF', 3, 'POWER_OFF',
        danger: true, confirm: true),
    ir(ActionIds.projectorHdmi1, 'PROJECTOR', 'HDMI 1', 3, 'HDMI1'),
    ir(ActionIds.projectorHdmi2, 'PROJECTOR', 'HDMI 2', 3, 'HDMI2'),
    ir(ActionIds.projectorMenu, 'PROJECTOR', 'MENU', 3, 'MENU'),
    ir(ActionIds.projectorBack, 'PROJECTOR', 'BACK', 3, 'BACK'),
  ]);

  // ---- Sequential power (순차전원) ----
  list.addAll([
    power(ActionIds.seqAllOn, '순차전원 · 전체', '전체 ON', 1, RelayMode.latchClose),
    power(ActionIds.seqAllOff, '순차전원 · 전체', '전체 OFF', 1, RelayMode.latchOpen,
        danger: true),
    power(ActionIds.seq1On, '순차전원 · 개별', '순차 1 ON', 2, RelayMode.latchClose),
    power(ActionIds.seq1Off, '순차전원 · 개별', '순차 1 OFF', 2, RelayMode.latchOpen,
        danger: true),
    power(ActionIds.seq2On, '순차전원 · 개별', '순차 2 ON', 3, RelayMode.latchClose),
    power(ActionIds.seq2Off, '순차전원 · 개별', '순차 2 OFF', 3, RelayMode.latchOpen,
        danger: true),
  ]);

  return list;
}
