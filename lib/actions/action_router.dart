// Named constructor params map to private fields, so initializing formals
// (this._x) aren't usable here.
// ignore_for_file: prefer_initializing_formals
import '../ce/ce_irs4_client.dart';
import '../ce/wol_client.dart';
import '../models/command_result.dart';
import 'action_models.dart';
import 'interlock_manager.dart';

/// Central dispatcher: turns an action_id into actual device commands
/// (spec §4, §17.4). The UI only ever calls [run] / [requiresConfirm];
/// it never builds TCP strings.
///
/// Actions are resolved through [_resolve], an injected lookup so the action
/// set can be edited at runtime (user-defined buttons + built-in macros).
class ActionRouter {
  ActionRouter({
    required CeIrs4Client irs4,
    required InterlockManager interlock,
    required WolClient wol,
    required ActionDef? Function(String id) resolve,
  })  : _irs4 = irs4,
        _interlock = interlock,
        _wol = wol,
        _resolve = resolve;

  final CeIrs4Client _irs4;
  final InterlockManager _interlock;
  final WolClient _wol;
  final ActionDef? Function(String id) _resolve;

  ActionDef? lookup(String actionId) => _resolve(actionId);

  /// Whether this action needs a confirmation dialog before running.
  bool requiresConfirm(String actionId) => _resolve(actionId)?.confirm ?? false;

  /// Custom confirmation prompt, or a sensible default.
  String confirmMessage(String actionId) {
    final def = _resolve(actionId);
    return def?.confirmMessage ?? '이 동작을 실행하시겠습니까?';
  }

  /// Runs an action. Never throws — always returns a [CommandResult].
  Future<CommandResult> run(String actionId) {
    final def = _resolve(actionId);
    if (def == null) {
      return Future.value(
        CommandResult.fail('정의되지 않은 동작입니다: $actionId'),
      );
    }
    return switch (def) {
      IrAction() => _runIr(def),
      RelayAction() => _interlock.executeRelay(def),
      WolAction() => _wol.wake(def.mac, name: def.name),
      MacroAction() => _runMacro(def),
    };
  }

  Future<CommandResult> _runIr(IrAction a) {
    switch (a.sendMode) {
      case IrSendMode.named:
        return _irs4.sendNamedIr(a.irPort, a.irName ?? '');
      case IrSendMode.numbered:
        return _irs4.sendNumberedIr(a.irPort, a.irNumber ?? 0);
    }
  }

  Future<CommandResult> _runMacro(MacroAction macro) async {
    if (macro.steps.isEmpty) {
      // Only happens for "wake all PCs" when none are configured yet.
      return CommandResult.fail('등록된 PC가 없습니다. 설정에서 추가하세요.');
    }

    final sent = <String>[];
    var sawWarning = false;

    for (var i = 0; i < macro.steps.length; i++) {
      final step = macro.steps[i];
      final result = await run(step.actionId);
      sent.addAll(result.sentCommands);

      if (!result.success) {
        // Stop on first hard failure and report which step (spec §22.9).
        return CommandResult.fail(
          '매크로 실패: ${i + 1}단계(${step.actionId}) - ${result.message}',
          sentCommands: sent,
        );
      }
      if (result.isWarning) {
        sawWarning = true;
      }

      if (step.delayAfterMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: step.delayAfterMs));
      }
    }

    if (sawWarning) {
      return CommandResult.warn(
        '매크로 완료(경고 포함). 장비 상태를 확인하세요.',
        sentCommands: sent,
      );
    }
    return CommandResult.ok('매크로 완료', sentCommands: sent);
  }
}
