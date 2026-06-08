import 'package:flutter_test/flutter_test.dart';

import 'package:amx_ce_control/actions/action_ids.dart';
import 'package:amx_ce_control/actions/action_models.dart';
import 'package:amx_ce_control/actions/macro_registry.dart';
import 'package:amx_ce_control/ce/ce_irs4_client.dart';
import 'package:amx_ce_control/ce/ce_rel8_client.dart';
import 'package:amx_ce_control/ce/ce_tcp_client.dart';
import 'package:amx_ce_control/config/app_config.dart';
import 'package:amx_ce_control/config/default_buttons.dart';
import 'package:amx_ce_control/models/button_config.dart';
import 'package:amx_ce_control/models/command_result.dart';

/// Records the commands it is asked to send instead of touching the network.
class _FakeTcpClient extends CeTcpClient {
  final List<String> sent = [];

  @override
  Future<CommandResult> sendCommand({
    required String host,
    required int port,
    required String command,
    required Duration timeout,
  }) async {
    sent.add(command);
    return CommandResult.ok('sent', sentCommands: [command.trimRight()]);
  }
}

void main() {
  test('default buttons cover the ids the built-in macros reference', () {
    final ids = {for (final b in defaultButtons()) b.id};
    for (final macro in builtInMacros()) {
      for (final step in macro.steps) {
        expect(ids.contains(step.actionId), isTrue,
            reason: 'macro ${macro.id} references missing ${step.actionId}');
      }
    }
  });

  test('ButtonConfig round-trips through JSON', () {
    const b = ButtonConfig(
      id: 'x1',
      label: 'POWER ON',
      screen: ButtonScreen.ir,
      group: 'TV 1',
      type: ButtonType.ir,
      irPort: 2,
      irSendMode: IrSendMode.named,
      irName: 'POWER_ON',
      confirm: true,
    );
    final copy = ButtonConfig.fromJson(b.toJson());
    expect(copy.id, 'x1');
    expect(copy.irPort, 2);
    expect(copy.irName, 'POWER_ON');
    expect(copy.confirm, isTrue);
    expect(copy.screen, ButtonScreen.ir);
  });

  test('IR ButtonConfig converts to an IrAction with the right port', () {
    const b = ButtonConfig(
      id: 'x2',
      label: 'HDMI 1',
      screen: ButtonScreen.ir,
      group: 'TV 2',
      type: ButtonType.ir,
      irPort: 2,
      irName: 'HDMI1',
    );
    final def = b.toActionDef();
    expect(def, isA<IrAction>());
    expect((def as IrAction).irPort, 2);
    expect(def.irName, 'HDMI1');
  });

  test('CE-IRS4 builds the correct named IR command path', () async {
    final fake = _FakeTcpClient();
    final client = CeIrs4Client(
      fake,
      () => const CeConnection(
        host: '10.0.0.1',
        port: 44197,
        timeout: Duration(seconds: 2),
      ),
    );
    await client.sendNamedIr(1, 'POWER_ON');
    expect(fake.sent.single, 'exec /ir/1/bufferedSendNamedIr "POWER_ON"');
  });

  test('CE-REL8 builds set /relay/#/state commands', () async {
    final fake = _FakeTcpClient();
    final client = CeRel8Client(
      fake,
      () => const CeConnection(
        host: '10.0.0.2',
        port: 44197,
        timeout: Duration(seconds: 2),
      ),
    );
    await client.relayClose(2);
    await client.relayOpen(2);
    expect(fake.sent, [
      'set /relay/2/state true',
      'set /relay/2/state false',
    ]);
  });

  test('built-in system macros exist', () {
    final macroIds = {for (final m in builtInMacros()) m.id};
    expect(macroIds, containsAll(<String>[
      ActionIds.systemOn,
      ActionIds.systemOff,
      ActionIds.presentationMode,
      ActionIds.standbyMode,
    ]));
  });
}
