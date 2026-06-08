import '../config/app_config.dart';
import '../models/command_result.dart';
import 'ce_tcp_client.dart';

/// Builds and sends CE-REL8 relay control commands (spec §7, §17.3).
///
/// This is the ONLY place CE-REL8 wire strings are constructed.
///
/// ┌──────────────────────────────────────────────────────────────────────┐
/// │ ⚠ COMMAND PATH MUST BE VERIFIED AGAINST THE AMX CE-Series MANUAL.      │
/// │                                                                        │
/// │ The exact 3rd-party control path for the CE-REL8 was not available at  │
/// │ build time. The strings below follow the same `exec /…` convention as  │
/// │ the documented CE-IRS4 IR commands and are intentionally isolated here │
/// │ so that fixing the format is a one-file change. Confirm the real       │
/// │ relay close/open verbs in the CE-REL8 section of the manual and update │
/// │ ONLY the two builders [_closeCommand] / [_openCommand] below.          │
/// └──────────────────────────────────────────────────────────────────────┘
class CeRel8Client {
  CeRel8Client(this._tcp, this._connection);

  final CeTcpClient _tcp;
  final CeConnection Function() _connection;

  /// How many times to retry a failed momentary OPEN before giving up.
  static const int _openRetries = 2;

  // --- Wire format (placeholders — verify against manual) -------------------

  String _closeCommand(int relay) => 'exec /relay/$relay/close';
  String _openCommand(int relay) => 'exec /relay/$relay/open';

  // --- Public API -----------------------------------------------------------

  /// Energizes (closes) a relay and leaves it closed (latching ON).
  Future<CommandResult> relayClose(int relayNumber) {
    return _send(_closeCommand(relayNumber));
  }

  /// De-energizes (opens) a relay and leaves it open (latching OFF).
  Future<CommandResult> relayOpen(int relayNumber) {
    return _send(_openCommand(relayNumber));
  }

  /// Momentary: close → wait [duration] → open.
  ///
  /// Safety (spec §11.4): if the trailing OPEN fails after a successful CLOSE,
  /// we retry up to [_openRetries] times. If it still fails we return a
  /// WARNING result (success=true so the chain isn't treated as a hard crash,
  /// but severity=warning so the UI shows a strong alert telling the operator
  /// to physically check the device).
  Future<CommandResult> relayMomentary(int relayNumber, Duration duration) async {
    final sent = <String>[];

    final close = await relayClose(relayNumber);
    sent.addAll(close.sentCommands);
    if (!close.success) {
      return CommandResult.fail(
        'Relay $relayNumber CLOSE 실패: ${close.message}',
        sentCommands: sent,
      );
    }

    await Future<void>.delayed(duration);

    CommandResult open = await relayOpen(relayNumber);
    sent.addAll(open.sentCommands);
    var attempt = 0;
    while (!open.success && attempt < _openRetries) {
      attempt++;
      open = await relayOpen(relayNumber);
      sent.addAll(open.sentCommands);
    }

    if (!open.success) {
      return CommandResult.warn(
        '경고: Relay $relayNumber OPEN 명령 실패. 장비 상태를 즉시 확인하세요.',
        sentCommands: sent,
      );
    }

    return CommandResult.ok('명령 전송됨', sentCommands: sent);
  }

  Future<CommandResult> _send(String command) {
    final c = _connection();
    return _tcp.sendCommand(
      host: c.host,
      port: c.port,
      command: command,
      timeout: c.timeout,
    );
  }
}
