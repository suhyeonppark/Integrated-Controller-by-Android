/// Connection parameters for a single CE device.
class CeConnection {
  const CeConnection({
    required this.host,
    required this.port,
    required this.timeout,
  });

  final String host;
  final int port;
  final Duration timeout;
}

/// All user-editable settings. Persisted via [ConfigRepository] and kept in
/// memory by the app state. Immutable; use [copyWith] to produce edits.
class AppConfig {
  const AppConfig({
    this.irs4Ip = '192.168.1.101',
    this.irs4Port = 44197,
    this.rel8Ip = '192.168.1.102',
    this.rel8Port = 44197,
    this.tcpTimeoutMs = 2000,
    this.buttonLockMs = 1000,
  });

  final String irs4Ip;
  final int irs4Port;
  final String rel8Ip;
  final int rel8Port;

  /// TCP connect/IO timeout in milliseconds.
  final int tcpTimeoutMs;

  /// How long a control button stays disabled after a press (anti double-tap).
  final int buttonLockMs;

  Duration get tcpTimeout => Duration(milliseconds: tcpTimeoutMs);
  Duration get buttonLock => Duration(milliseconds: buttonLockMs);

  CeConnection get irs4 =>
      CeConnection(host: irs4Ip, port: irs4Port, timeout: tcpTimeout);
  CeConnection get rel8 =>
      CeConnection(host: rel8Ip, port: rel8Port, timeout: tcpTimeout);

  AppConfig copyWith({
    String? irs4Ip,
    int? irs4Port,
    String? rel8Ip,
    int? rel8Port,
    int? tcpTimeoutMs,
    int? buttonLockMs,
  }) {
    return AppConfig(
      irs4Ip: irs4Ip ?? this.irs4Ip,
      irs4Port: irs4Port ?? this.irs4Port,
      rel8Ip: rel8Ip ?? this.rel8Ip,
      rel8Port: rel8Port ?? this.rel8Port,
      tcpTimeoutMs: tcpTimeoutMs ?? this.tcpTimeoutMs,
      buttonLockMs: buttonLockMs ?? this.buttonLockMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'ce_irs4_ip': irs4Ip,
        'ce_irs4_port': irs4Port,
        'ce_rel8_ip': rel8Ip,
        'ce_rel8_port': rel8Port,
        'tcp_timeout_ms': tcpTimeoutMs,
        'button_lock_ms': buttonLockMs,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    const defaults = AppConfig();
    return AppConfig(
      irs4Ip: json['ce_irs4_ip'] as String? ?? defaults.irs4Ip,
      irs4Port: json['ce_irs4_port'] as int? ?? defaults.irs4Port,
      rel8Ip: json['ce_rel8_ip'] as String? ?? defaults.rel8Ip,
      rel8Port: json['ce_rel8_port'] as int? ?? defaults.rel8Port,
      tcpTimeoutMs: json['tcp_timeout_ms'] as int? ?? defaults.tcpTimeoutMs,
      buttonLockMs: json['button_lock_ms'] as int? ?? defaults.buttonLockMs,
    );
  }
}
