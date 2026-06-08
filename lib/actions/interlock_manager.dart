import '../ce/ce_rel8_client.dart';
import '../models/command_result.dart';
import 'action_models.dart';

/// Executes relay actions with the safety logic from spec §11.
///
/// For an interlocked momentary action (screen/lift), the sequence is:
///   1. OPEN every relay in [RelayAction.openBeforeClose]
///      (e.g. for screen_up: open screen_down + screen_stop relays)
///   2. CLOSE the target relay
///   3. wait [RelayAction.duration]
///   4. OPEN the target relay (with retry — see [CeRel8Client.relayMomentary])
///
/// This guarantees opposite directions can never be energized at the same time.
class InterlockManager {
  InterlockManager(this._rel8);

  final CeRel8Client _rel8;

  Future<CommandResult> executeRelay(RelayAction action) async {
    final sent = <String>[];

    // Step 1: drop any conflicting relays first.
    for (final relay in action.openBeforeClose) {
      final r = await _rel8.relayOpen(relay);
      sent.addAll(r.sentCommands);
      if (!r.success) {
        return CommandResult.fail(
          'Interlock 해제 실패 (relay $relay): ${r.message}',
          sentCommands: sent,
        );
      }
    }

    // Steps 2–4 depend on mode.
    switch (action.mode) {
      case RelayMode.momentary:
        final r = await _rel8.relayMomentary(action.relay, action.duration);
        return CommandResult(
          success: r.success,
          severity: r.severity,
          message: r.message,
          sentCommands: [...sent, ...r.sentCommands],
        );
      case RelayMode.latchClose:
        final r = await _rel8.relayClose(action.relay);
        return CommandResult(
          success: r.success,
          severity: r.severity,
          message: r.success ? '명령 전송됨' : r.message,
          sentCommands: [...sent, ...r.sentCommands],
        );
      case RelayMode.latchOpen:
        final r = await _rel8.relayOpen(action.relay);
        return CommandResult(
          success: r.success,
          severity: r.severity,
          message: r.success ? '명령 전송됨' : r.message,
          sentCommands: [...sent, ...r.sentCommands],
        );
    }
  }
}
