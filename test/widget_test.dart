import 'package:flutter_test/flutter_test.dart';

import 'package:amx_ce_control/actions/action_ids.dart';
import 'package:amx_ce_control/actions/action_models.dart';
import 'package:amx_ce_control/actions/action_registry.dart';
import 'package:amx_ce_control/ce/ce_irs4_client.dart';
import 'package:amx_ce_control/ce/ce_rel8_client.dart';
import 'package:amx_ce_control/ce/ce_tcp_client.dart';
import 'package:amx_ce_control/config/app_config.dart';
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
  test('registry defines every action id', () {
    const ids = [
      ActionIds.systemOn,
      ActionIds.systemOff,
      ActionIds.presentationMode,
      ActionIds.standbyMode,
      ActionIds.allDisplayOn,
      ActionIds.allDisplayOff,
      ActionIds.tv1PowerOn,
      ActionIds.tv2PowerOn,
      ActionIds.tv2Mute,
      ActionIds.projectorPowerOff,
      ActionIds.seqAllOn,
      ActionIds.seqAllOff,
      ActionIds.seq1On,
      ActionIds.seq2Off,
    ];
    for (final id in ids) {
      expect(ActionRegistry.lookup(id), isNotNull, reason: 'missing $id');
    }
  });

  test('CE-IRS4 builds the correct named IR command path', () async {
    // The trailing newline is appended by CeTcpClient (the transport); the
    // client builds the command body and hands it off.
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

  test('risky actions require confirmation', () {
    expect((ActionRegistry.lookup(ActionIds.systemOff)!).confirm, isTrue);
    expect((ActionRegistry.lookup(ActionIds.seqAllOff)!).confirm, isTrue);
    expect((ActionRegistry.lookup(ActionIds.tv1Hdmi1)!).confirm, isFalse);
  });

  test('sequential power relays are latching on the expected channels', () {
    final allOn = ActionRegistry.lookup(ActionIds.seqAllOn)! as RelayAction;
    expect(allOn.relay, 1);
    expect(allOn.mode, RelayMode.latchClose);

    final allOff = ActionRegistry.lookup(ActionIds.seqAllOff)! as RelayAction;
    expect(allOff.relay, 1);
    expect(allOff.mode, RelayMode.latchOpen);

    expect((ActionRegistry.lookup(ActionIds.seq1On)! as RelayAction).relay, 2);
    expect((ActionRegistry.lookup(ActionIds.seq2On)! as RelayAction).relay, 3);
  });
}
