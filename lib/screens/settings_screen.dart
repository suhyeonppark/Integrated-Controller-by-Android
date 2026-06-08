import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../config/app_config.dart';
import '../models/device_status.dart';

/// Settings screen: device IP/port, timeouts, connection tests, save (spec §10.4).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _irs4Ip;
  late TextEditingController _irs4Port;
  late TextEditingController _rel8Ip;
  late TextEditingController _rel8Port;
  late TextEditingController _timeout;
  late TextEditingController _lock;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final c = AppScope.of(context).config;
    _irs4Ip = TextEditingController(text: c.irs4Ip);
    _irs4Port = TextEditingController(text: '${c.irs4Port}');
    _rel8Ip = TextEditingController(text: c.rel8Ip);
    _rel8Port = TextEditingController(text: '${c.rel8Port}');
    _timeout = TextEditingController(text: '${c.tcpTimeoutMs}');
    _lock = TextEditingController(text: '${c.buttonLockMs}');
    _initialized = true;
  }

  @override
  void dispose() {
    _irs4Ip.dispose();
    _irs4Port.dispose();
    _rel8Ip.dispose();
    _rel8Port.dispose();
    _timeout.dispose();
    _lock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final newConfig = AppConfig(
      irs4Ip: _irs4Ip.text.trim(),
      irs4Port: int.parse(_irs4Port.text.trim()),
      rel8Ip: _rel8Ip.text.trim(),
      rel8Port: int.parse(_rel8Port.text.trim()),
      tcpTimeoutMs: int.parse(_timeout.text.trim()),
      buttonLockMs: int.parse(_lock.text.trim()),
    );
    final ok = await state.saveConfig(newConfig);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? '설정이 저장되었습니다.' : '설정 저장에 실패했습니다.'),
        backgroundColor: ok ? null : Colors.red.shade700,
      ),
    );
    // Re-probe with the new settings.
    state.unawaitedTest();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('CE-IRS4 (IR)'),
          _ipField('CE-IRS4 IP', _irs4Ip),
          _portField('CE-IRS4 Port', _irs4Port),
          _testRow('CE-IRS4', state.irs4Status, () => state.testIrs4()),
          const SizedBox(height: 24),
          _sectionTitle('CE-REL8 (Relay)'),
          _ipField('CE-REL8 IP', _rel8Ip),
          _portField('CE-REL8 Port', _rel8Port),
          _testRow('CE-REL8', state.rel8Status, () => state.testRel8()),
          const SizedBox(height: 24),
          _sectionTitle('공통'),
          _numberField('TCP Timeout (ms)', _timeout, min: 200, max: 30000),
          _numberField('Button Lock Time (ms)', _lock, min: 0, max: 10000),
          const SizedBox(height: 24),
          SizedBox(
            height: 64,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('설정 저장', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('앱 정보'),
            subtitle: Text(
              'AMX CE Control · v1.0.0\n'
              'CE-IRS4 / CE-REL8 standalone tablet controller',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );

  Widget _ipField(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            hintText: '192.168.1.100',
          ),
          keyboardType: TextInputType.text,
          validator: _validateIp,
        ),
      );

  Widget _portField(String label, TextEditingController c) =>
      _numberField(label, c, min: 1, max: 65535);

  Widget _numberField(
    String label,
    TextEditingController c, {
    required int min,
    required int max,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            if (n == null) return '숫자를 입력하세요';
            if (n < min || n > max) return '$min ~ $max 범위로 입력하세요';
            return null;
          },
        ),
      );

  String? _validateIp(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return 'IP를 입력하세요';
    final parts = s.split('.');
    if (parts.length != 4) return '올바른 IPv4 주소를 입력하세요';
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null || n < 0 || n > 255) return '올바른 IPv4 주소를 입력하세요';
    }
    return null;
  }

  Widget _testRow(String name, DeviceStatus status, VoidCallback onTest) {
    Color color;
    String text;
    switch (status.state) {
      case DeviceConnectionState.online:
        color = Colors.green;
        text = '$name: ONLINE';
        break;
      case DeviceConnectionState.offline:
        color = Colors.red;
        text = '$name: OFFLINE${status.detail != null ? ' - ${status.detail}' : ''}';
        break;
      case DeviceConnectionState.checking:
        color = Colors.orange;
        text = '$name: 확인 중...';
        break;
      case DeviceConnectionState.unknown:
        color = Colors.grey;
        text = '$name: 미확인';
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed:
                status.state == DeviceConnectionState.checking ? null : onTest,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('연결 테스트'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
