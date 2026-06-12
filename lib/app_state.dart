import 'package:flutter/widgets.dart';

import 'actions/action_models.dart';
import 'actions/action_router.dart';
import 'actions/interlock_manager.dart';
import 'actions/action_ids.dart';
import 'actions/macro_registry.dart';
import 'ce/ce_irs4_client.dart';
import 'ce/ce_rel8_client.dart';
import 'ce/ce_rel8_subscription.dart';
import 'ce/ce_tcp_client.dart';
import 'ce/wol_client.dart';
import 'config/app_config.dart';
import 'config/button_repository.dart';
import 'config/config_repository.dart';
import 'models/button_config.dart';
import 'models/command_result.dart';
import 'models/device_status.dart';

/// Holds all app-wide state and services and notifies listeners on change.
///
/// Wires the clients to *live* config via closures so editing settings takes
/// effect immediately without rebuilding the object graph.
class AppState extends ChangeNotifier {
  AppState({ConfigRepository? repository, ButtonRepository? buttonRepository})
    : _repo = repository ?? ConfigRepository(),
      _buttonRepo = buttonRepository ?? ButtonRepository() {
    final tcp = CeTcpClient();
    _tcp = tcp;
    final irs4 = CeIrs4Client(tcp, () => _config.irs4);
    final rel8 = CeRel8Client(tcp, () => _config.rel8, onState: _onRelayState);
    _rel8Subscription = CeRel8Subscription(
      connection: () => _config.rel8,
      onState: _onRelayState,
      onStatus: _onRel8SubscriptionStatus,
    );
    router = ActionRouter(
      irs4: irs4,
      interlock: InterlockManager(rel8),
      wol: WolClient(),
      resolve: (id) => _actionMap[id],
    );
  }

  final ConfigRepository _repo;
  final ButtonRepository _buttonRepo;
  late final CeTcpClient _tcp;
  late final CeRel8Subscription _rel8Subscription;
  late final ActionRouter router;

  AppConfig _config = const AppConfig();
  AppConfig get config => _config;

  /// User-editable buttons (IR + power), in saved order.
  List<ButtonConfig> _buttons = const [];
  List<ButtonConfig> get buttons => List.unmodifiable(_buttons);

  /// Combined id → action map: user button actions + built-in macros.
  /// Rebuilt whenever the button list changes; the router resolves through it.
  Map<String, ActionDef> _actionMap = {};

  void _rebuildActionMap() {
    final map = <String, ActionDef>{};
    for (final b in _buttons) {
      map[b.id] = b.toActionDef();
    }
    for (final m in builtInMacros()) {
      map[m.id] = m;
    }
    // Wake-on-LAN actions generated from the configured PC list: one per PC
    // plus a "wake all" macro the home screen targets.
    for (final pc in _config.pcs) {
      map[ActionIds.wol(pc.id)] =
          WolAction(id: ActionIds.wol(pc.id), mac: pc.mac, name: pc.name);
    }
    map[ActionIds.wolAll] = MacroAction(
      id: ActionIds.wolAll,
      confirm: false,
      steps: [
        for (final pc in _config.pcs)
          MacroStep(ActionIds.wol(pc.id), delayAfterMs: 150),
      ],
    );
    _actionMap = map;
  }

  /// Buttons for a screen, grouped by [ButtonConfig.group] preserving order.
  Map<String, List<ButtonConfig>> buttonsByGroup(ButtonScreen screen) {
    final result = <String, List<ButtonConfig>>{};
    final filtered = _buttons.where((b) => b.screen == screen).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    for (final b in filtered) {
      result.putIfAbsent(b.group, () => []).add(b);
    }
    return result;
  }

  DeviceStatus _irs4Status = const DeviceStatus();
  DeviceStatus get irs4Status => _irs4Status;

  DeviceStatus _rel8Status = const DeviceStatus();
  DeviceStatus get rel8Status => _rel8Status;

  /// Last-known latched state per relay number (`true` = ON/closed). Absent =
  /// unknown (no command sent yet this session). Updated from the CE-REL8
  /// client whenever a relay command succeeds.
  final Map<int, bool> _relayClosed = {};

  /// Last-known ON/OFF state of [relay], or null if not yet known.
  bool? relayIsOn(int relay) => _relayClosed[relay];

  void _onRelayState(int relay, bool closed) {
    _relayClosed[relay] = closed;
    notifyListeners();
  }

  void _onRel8SubscriptionStatus(bool connected, String? detail) {
    _rel8Status = DeviceStatus(
      state: connected
          ? DeviceConnectionState.online
          : DeviceConnectionState.offline,
      detail: detail,
    );
    notifyListeners();
  }

  /// True while a macro (or any multi-step action) is running. The UI disables
  /// control buttons during this window (spec §15).
  bool _busy = false;
  bool get isBusy => _busy;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Load persisted config + buttons at startup, then probe both devices once.
  Future<void> init() async {
    _config = await _repo.load();
    _buttons = await _buttonRepo.load();
    _rebuildActionMap();
    _loaded = true;
    notifyListeners();
    _rel8Subscription.start();
    // Fire-and-forget initial connectivity probe.
    unawaitedTest();
  }

  // --- Button editing (settings) ------------------------------------------

  Future<bool> _persistButtons() async {
    _rebuildActionMap();
    notifyListeners();
    return _buttonRepo.save(_buttons);
  }

  /// Adds a new button (appended to the end of its group's order).
  Future<bool> addButton(ButtonConfig button) {
    final maxOrder = _buttons.isEmpty
        ? 0
        : _buttons.map((b) => b.order).reduce((a, b) => a > b ? a : b);
    _buttons = [..._buttons, button.copyWith(order: maxOrder + 1)];
    return _persistButtons();
  }

  /// Replaces the button with the same id.
  Future<bool> updateButton(ButtonConfig button) {
    _buttons = [
      for (final b in _buttons)
        if (b.id == button.id) button else b,
    ];
    return _persistButtons();
  }

  Future<bool> deleteButton(String id) {
    _buttons = [
      for (final b in _buttons)
        if (b.id != id) b,
    ];
    return _persistButtons();
  }

  /// Restores the factory-default button set.
  Future<bool> resetButtons() async {
    await _buttonRepo.reset();
    _buttons = await _buttonRepo.load();
    return _persistButtons();
  }

  /// Unique id for a newly created button.
  String newButtonId() => 'btn_${DateTime.now().microsecondsSinceEpoch}';

  void unawaitedTest() {
    testIrs4();
  }

  /// Persist new settings and refresh status. Returns true on success.
  Future<bool> saveConfig(AppConfig newConfig) async {
    _config = newConfig;
    _relayClosed.clear();
    // PC list lives in config, so regenerate the WoL actions/macro.
    _rebuildActionMap();
    notifyListeners();
    _rel8Subscription.restart();
    final ok = await _repo.save(newConfig);
    return ok;
  }

  /// Tests CE-IRS4 reachability. [hostOverride]/[portOverride] let the settings
  /// screen probe the address currently typed in the form without saving first.
  Future<DeviceStatus> testIrs4({
    String? hostOverride,
    int? portOverride,
  }) async {
    _irs4Status = _irs4Status.copyWith(state: DeviceConnectionState.checking);
    notifyListeners();
    final c = _config.irs4;
    final result = await _tcp.testConnection(
      host: hostOverride ?? c.host,
      port: portOverride ?? c.port,
      timeout: c.timeout,
    );
    _irs4Status = DeviceStatus(
      state: result.success
          ? DeviceConnectionState.online
          : DeviceConnectionState.offline,
      detail: result.success ? null : result.message,
    );
    notifyListeners();
    return _irs4Status;
  }

  /// Tests CE-REL8 reachability. [hostOverride]/[portOverride] let the settings
  /// screen probe the address currently typed in the form without saving first.
  Future<DeviceStatus> testRel8({
    String? hostOverride,
    int? portOverride,
  }) async {
    _rel8Status = _rel8Status.copyWith(state: DeviceConnectionState.checking);
    notifyListeners();
    final c = _config.rel8;
    final result = await _tcp.testConnection(
      host: hostOverride ?? c.host,
      port: portOverride ?? c.port,
      timeout: c.timeout,
    );
    _rel8Status = DeviceStatus(
      state: result.success
          ? DeviceConnectionState.online
          : DeviceConnectionState.offline,
      detail: result.success ? null : result.message,
    );
    notifyListeners();
    return _rel8Status;
  }

  /// Runs an action. If it is a macro, marks the app busy so the UI can
  /// disable all control buttons for the duration.
  Future<CommandResult> runAction(String actionId) async {
    final isMacro = router.lookup(actionId) is MacroAction;
    if (isMacro) {
      _busy = true;
      notifyListeners();
    }
    try {
      return await router.run(actionId);
    } finally {
      if (isMacro) {
        _busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _rel8Subscription.stop();
    super.dispose();
  }
}

/// Inherited access to [AppState]. Rebuilds dependents on notify.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }

  /// Read without subscribing to rebuilds (for one-off calls in callbacks).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope?.notifier != null, 'AppScope not found in widget tree');
    return scope!.notifier!;
  }
}
