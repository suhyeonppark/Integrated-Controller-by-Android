import 'package:flutter/widgets.dart';

import 'actions/action_models.dart';
import 'actions/action_router.dart';
import 'actions/interlock_manager.dart';
import 'ce/ce_irs4_client.dart';
import 'ce/ce_rel8_client.dart';
import 'ce/ce_tcp_client.dart';
import 'config/app_config.dart';
import 'config/config_repository.dart';
import 'models/command_result.dart';
import 'models/device_status.dart';

/// Holds all app-wide state and services and notifies listeners on change.
///
/// Wires the clients to *live* config via closures so editing settings takes
/// effect immediately without rebuilding the object graph.
class AppState extends ChangeNotifier {
  AppState({ConfigRepository? repository})
      : _repo = repository ?? ConfigRepository() {
    final tcp = CeTcpClient();
    _tcp = tcp;
    final irs4 = CeIrs4Client(tcp, () => _config.irs4);
    final rel8 = CeRel8Client(tcp, () => _config.rel8);
    router = ActionRouter(irs4, InterlockManager(rel8));
  }

  final ConfigRepository _repo;
  late final CeTcpClient _tcp;
  late final ActionRouter router;

  AppConfig _config = const AppConfig();
  AppConfig get config => _config;

  DeviceStatus _irs4Status = const DeviceStatus();
  DeviceStatus get irs4Status => _irs4Status;

  DeviceStatus _rel8Status = const DeviceStatus();
  DeviceStatus get rel8Status => _rel8Status;

  /// True while a macro (or any multi-step action) is running. The UI disables
  /// control buttons during this window (spec §15).
  bool _busy = false;
  bool get isBusy => _busy;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Load persisted config at startup, then probe both devices once.
  Future<void> init() async {
    _config = await _repo.load();
    _loaded = true;
    notifyListeners();
    // Fire-and-forget initial connectivity probe.
    unawaitedTest();
  }

  void unawaitedTest() {
    testIrs4();
    testRel8();
  }

  /// Persist new settings and refresh status. Returns true on success.
  Future<bool> saveConfig(AppConfig newConfig) async {
    _config = newConfig;
    notifyListeners();
    final ok = await _repo.save(newConfig);
    return ok;
  }

  Future<DeviceStatus> testIrs4() async {
    _irs4Status = _irs4Status.copyWith(state: DeviceConnectionState.checking);
    notifyListeners();
    final c = _config.irs4;
    final result =
        await _tcp.testConnection(host: c.host, port: c.port, timeout: c.timeout);
    _irs4Status = DeviceStatus(
      state: result.success ? DeviceConnectionState.online : DeviceConnectionState.offline,
      detail: result.success ? null : result.message,
    );
    notifyListeners();
    return _irs4Status;
  }

  Future<DeviceStatus> testRel8() async {
    _rel8Status = _rel8Status.copyWith(state: DeviceConnectionState.checking);
    notifyListeners();
    final c = _config.rel8;
    final result =
        await _tcp.testConnection(host: c.host, port: c.port, timeout: c.timeout);
    _rel8Status = DeviceStatus(
      state: result.success ? DeviceConnectionState.online : DeviceConnectionState.offline,
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
}

/// Inherited access to [AppState]. Rebuilds dependents on notify.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

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
