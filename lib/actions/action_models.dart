/// Which CE device an action targets.
enum CeDevice { irs4, rel8 }

/// IR send strategy (spec §6).
enum IrSendMode { named, numbered }

/// Relay behaviour (spec §11.2).
enum RelayMode {
  /// Close for [RelayAction.duration], then open. Used for screen/lift pulses.
  momentary,

  /// Latch closed (ON) and stay closed.
  latchClose,

  /// Latch open (OFF) and stay open.
  latchOpen,
}

/// Base type for everything the [ActionRouter] can run.
sealed class ActionDef {
  const ActionDef({
    required this.id,
    required this.confirm,
    this.confirmMessage,
  });

  final String id;

  /// Whether a confirmation dialog must be shown before running (spec §11.3).
  final bool confirm;

  /// Optional custom Korean confirmation prompt.
  final String? confirmMessage;
}

/// An IR command sent through CE-IRS4.
class IrAction extends ActionDef {
  const IrAction({
    required super.id,
    required this.irPort,
    this.sendMode = IrSendMode.named,
    this.irName,
    this.irNumber,
    super.confirm = false,
    super.confirmMessage,
  });

  final int irPort;
  final IrSendMode sendMode;
  final String? irName;
  final int? irNumber;
}

/// A relay command sent through CE-REL8.
class RelayAction extends ActionDef {
  const RelayAction({
    required super.id,
    required this.relay,
    required this.mode,
    this.durationMs = 500,
    this.interlockGroup,
    this.openBeforeClose = const [],
    super.confirm = false,
    super.confirmMessage,
  });

  final int relay;
  final RelayMode mode;

  /// Momentary pulse length.
  final int durationMs;

  /// Logical group for mutual exclusion (e.g. "screen", "lift").
  final String? interlockGroup;

  /// Relays that must be opened BEFORE this relay closes (spec §11.1), to
  /// prevent opposite directions energizing simultaneously.
  final List<int> openBeforeClose;

  Duration get duration => Duration(milliseconds: durationMs);
}

/// A Wake-on-LAN magic packet sent to a PC's MAC address.
class WolAction extends ActionDef {
  const WolAction({
    required super.id,
    required this.mac,
    required this.name,
    super.confirm = false,
    super.confirmMessage,
  });

  final String mac;
  final String name;
}

/// One step of a macro: run [actionId], then wait [delayAfterMs].
class MacroStep {
  const MacroStep(this.actionId, {this.delayAfterMs = 0});

  final String actionId;
  final int delayAfterMs;
}

/// A sequence of other actions run in order (spec §9.3).
class MacroAction extends ActionDef {
  const MacroAction({
    required super.id,
    required this.steps,
    super.confirm = false,
    super.confirmMessage,
  });

  final List<MacroStep> steps;
}
