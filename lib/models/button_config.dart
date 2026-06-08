import '../actions/action_models.dart';

/// Which control screen a button lives on. (Home is macro-only and not edited.)
enum ButtonScreen { ir, power }

/// What a button does.
enum ButtonType { ir, relay }

/// A user-editable control button. This is the persisted, mutable counterpart
/// of the execution-time [ActionDef]: it carries presentation (label, screen,
/// group, order, danger) plus the device parameters, and converts to an
/// [IrAction] / [RelayAction] via [toActionDef].
class ButtonConfig {
  const ButtonConfig({
    required this.id,
    required this.label,
    required this.screen,
    required this.group,
    required this.type,
    this.order = 0,
    this.confirm = false,
    this.danger = false,
    this.holdMs = 0,
    // IR
    this.irPort = 1,
    this.irSendMode = IrSendMode.named,
    this.irName = '',
    this.irNumber = 1,
    // Relay
    this.relay = 1,
    this.relayMode = RelayMode.latchClose,
    this.durationMs = 500,
  });

  final String id;
  final String label;
  final ButtonScreen screen;

  /// Section heading the button is shown under (e.g. "TV 1", "순차전원 · 전체").
  final String group;
  final int order;

  final ButtonType type;
  final bool confirm;
  final bool danger;

  /// If > 0, button must be press-and-held this long to activate.
  final int holdMs;

  // IR parameters
  final int irPort;
  final IrSendMode irSendMode;
  final String irName;
  final int irNumber;

  // Relay parameters
  final int relay;
  final RelayMode relayMode;
  final int durationMs;

  bool get isHold => holdMs > 0;

  /// Builds the confirmation prompt shown for tap buttons with [confirm].
  String get _confirmMessage => "'$label'을(를) 실행하시겠습니까?";

  /// Convert to the execution-time action consumed by the router.
  ActionDef toActionDef() {
    switch (type) {
      case ButtonType.ir:
        return IrAction(
          id: id,
          irPort: irPort,
          sendMode: irSendMode,
          irName: irName,
          irNumber: irNumber,
          confirm: confirm,
          confirmMessage: confirm ? _confirmMessage : null,
        );
      case ButtonType.relay:
        return RelayAction(
          id: id,
          relay: relay,
          mode: relayMode,
          durationMs: durationMs,
          confirm: confirm,
          confirmMessage: confirm ? _confirmMessage : null,
        );
    }
  }

  ButtonConfig copyWith({
    String? label,
    ButtonScreen? screen,
    String? group,
    int? order,
    ButtonType? type,
    bool? confirm,
    bool? danger,
    int? holdMs,
    int? irPort,
    IrSendMode? irSendMode,
    String? irName,
    int? irNumber,
    int? relay,
    RelayMode? relayMode,
    int? durationMs,
  }) {
    return ButtonConfig(
      id: id,
      label: label ?? this.label,
      screen: screen ?? this.screen,
      group: group ?? this.group,
      order: order ?? this.order,
      type: type ?? this.type,
      confirm: confirm ?? this.confirm,
      danger: danger ?? this.danger,
      holdMs: holdMs ?? this.holdMs,
      irPort: irPort ?? this.irPort,
      irSendMode: irSendMode ?? this.irSendMode,
      irName: irName ?? this.irName,
      irNumber: irNumber ?? this.irNumber,
      relay: relay ?? this.relay,
      relayMode: relayMode ?? this.relayMode,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'screen': screen.name,
        'group': group,
        'order': order,
        'type': type.name,
        'confirm': confirm,
        'danger': danger,
        'holdMs': holdMs,
        'irPort': irPort,
        'irSendMode': irSendMode.name,
        'irName': irName,
        'irNumber': irNumber,
        'relay': relay,
        'relayMode': relayMode.name,
        'durationMs': durationMs,
      };

  factory ButtonConfig.fromJson(Map<String, dynamic> j) {
    return ButtonConfig(
      id: j['id'] as String,
      label: j['label'] as String? ?? '',
      screen: _enumByName(ButtonScreen.values, j['screen'], ButtonScreen.ir),
      group: j['group'] as String? ?? '',
      order: (j['order'] as num?)?.toInt() ?? 0,
      type: _enumByName(ButtonType.values, j['type'], ButtonType.ir),
      confirm: j['confirm'] as bool? ?? false,
      danger: j['danger'] as bool? ?? false,
      holdMs: (j['holdMs'] as num?)?.toInt() ?? 0,
      irPort: (j['irPort'] as num?)?.toInt() ?? 1,
      irSendMode:
          _enumByName(IrSendMode.values, j['irSendMode'], IrSendMode.named),
      irName: j['irName'] as String? ?? '',
      irNumber: (j['irNumber'] as num?)?.toInt() ?? 1,
      relay: (j['relay'] as num?)?.toInt() ?? 1,
      relayMode:
          _enumByName(RelayMode.values, j['relayMode'], RelayMode.latchClose),
      durationMs: (j['durationMs'] as num?)?.toInt() ?? 500,
    );
  }

  static T _enumByName<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is String) {
      for (final v in values) {
        if (v.name == raw) return v;
      }
    }
    return fallback;
  }
}
