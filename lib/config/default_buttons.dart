import '../actions/action_ids.dart';
import '../actions/action_models.dart';
import '../models/button_config.dart';

/// The factory-default button set, used the first time the app runs (or after a
/// "기본값 복원"). Ids match the ones the built-in macros reference, so the home
/// macros keep working out of the box.
///
/// IR ports: 1 = prompter TV, 2 = PGM TV. Relays: 1 = audio, 2 = video.
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
      confirm: true, // power buttons confirm before switching
    );
  }

  // ---- TVs (CE-IRS4) ----
  list.addAll([
    ir(ActionIds.tv1PowerOn, '프롬프터 TV', '프롬프터 TV ON', 1, 'POWER_ON'),
    ir(ActionIds.tv1PowerOff, '프롬프터 TV', '프롬프터 TV OFF', 1, 'POWER_OFF',
        danger: true),
    ir(ActionIds.tv2PowerOn, 'PGM TV', 'PGM TV ON', 2, 'POWER_ON'),
    ir(ActionIds.tv2PowerOff, 'PGM TV', 'PGM TV OFF', 2, 'POWER_OFF',
        danger: true),
  ]);

  // ---- Power relays (CE-REL8) ----
  list.addAll([
    power(ActionIds.seq1On, '전원', '음향전원 ON', 1, RelayMode.latchClose),
    power(ActionIds.seq1Off, '전원', '음향전원 OFF', 1, RelayMode.latchOpen,
        danger: true),
    power(ActionIds.seq2On, '전원', '영상전원 ON', 2, RelayMode.latchClose),
    power(ActionIds.seq2Off, '전원', '영상전원 OFF', 2, RelayMode.latchOpen,
        danger: true),
  ]);

  return list;
}
