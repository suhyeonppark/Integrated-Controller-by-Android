import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../actions/action_models.dart';
import '../app_state.dart';
import '../models/button_config.dart';

/// Add/edit form for a single [ButtonConfig]. Returns the edited button via
/// `Navigator.pop(context, button)`, or null if cancelled.
///
/// The button TYPE is derived from the chosen screen (IR screen → IR button,
/// 전원 screen → relay button) to avoid invalid combinations.
class ButtonEditScreen extends StatefulWidget {
  const ButtonEditScreen({super.key, this.existing});

  /// Null when creating a new button.
  final ButtonConfig? existing;

  @override
  State<ButtonEditScreen> createState() => _ButtonEditScreenState();
}

class _ButtonEditScreenState extends State<ButtonEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _label;
  late final TextEditingController _group;
  late final TextEditingController _irName;
  late final TextEditingController _irNumber;
  late final TextEditingController _duration;

  late ButtonScreen _screen;
  late int _irPort;
  late IrSendMode _irSendMode;
  late int _relay;
  late RelayMode _relayMode;
  late bool _confirm;
  late bool _danger;

  bool get _isIr => _screen == ButtonScreen.ir;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _label = TextEditingController(text: b?.label ?? '');
    _group = TextEditingController(text: b?.group ?? '');
    _irName = TextEditingController(text: b?.irName ?? '');
    _irNumber = TextEditingController(text: '${b?.irNumber ?? 1}');
    _duration = TextEditingController(text: '${b?.durationMs ?? 500}');
    _screen = b?.screen ?? ButtonScreen.ir;
    _irPort = b?.irPort ?? 1;
    _irSendMode = b?.irSendMode ?? IrSendMode.named;
    _relay = b?.relay ?? 1;
    _relayMode = b?.relayMode ?? RelayMode.latchClose;
    _confirm = b?.confirm ?? false;
    _danger = b?.danger ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _group.dispose();
    _irName.dispose();
    _irNumber.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final state = AppScope.read(context);
    final id = widget.existing?.id ?? state.newButtonId();
    final type = _isIr ? ButtonType.ir : ButtonType.relay;

    final button = ButtonConfig(
      id: id,
      label: _label.text.trim(),
      screen: _screen,
      group: _group.text.trim().isEmpty ? '기타' : _group.text.trim(),
      type: type,
      order: widget.existing?.order ?? 0,
      confirm: _confirm,
      danger: _danger,
      irPort: _irPort,
      irSendMode: _irSendMode,
      irName: _irName.text.trim(),
      irNumber: int.tryParse(_irNumber.text.trim()) ?? 1,
      relay: _relay,
      relayMode: _relayMode,
      durationMs: int.tryParse(_duration.text.trim()) ?? 500,
    );
    Navigator.of(context).pop(button);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? '버튼 수정' : '버튼 추가'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('저장', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _label,
              decoration: const InputDecoration(
                labelText: '버튼 이름 (라벨)',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '버튼 이름을 입력하세요' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ButtonScreen>(
              initialValue: _screen,
              decoration: const InputDecoration(
                labelText: '화면',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: ButtonScreen.ir, child: Text('IR 제어 (CE-IRS4)')),
                DropdownMenuItem(
                    value: ButtonScreen.power, child: Text('전원 제어 (CE-REL8)')),
              ],
              onChanged: (v) => setState(() => _screen = v ?? _screen),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _group,
              decoration: InputDecoration(
                labelText: '그룹 (섹션 제목)',
                hintText: _isIr ? '예: 프롬프터 TV' : '예: 전원',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            if (_isIr) ..._irFields() else ..._relayFields(),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('위험 버튼 색상 (빨강)'),
              value: _danger,
              onChanged: (v) => setState(() => _danger = v),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _irFields() {
    return [
      _sectionLabel('IR 설정'),
      DropdownButtonFormField<int>(
        initialValue: _irPort,
        decoration: const InputDecoration(
          labelText: 'IR 포트',
          border: OutlineInputBorder(),
        ),
        items: [
          for (var p = 1; p <= 4; p++)
            DropdownMenuItem(value: p, child: Text('포트 $p')),
        ],
        onChanged: (v) => setState(() => _irPort = v ?? _irPort),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<IrSendMode>(
        initialValue: _irSendMode,
        decoration: const InputDecoration(
          labelText: 'IR 채널 방식',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: IrSendMode.named, child: Text('이름 (named)')),
          DropdownMenuItem(value: IrSendMode.numbered, child: Text('번호 (index)')),
        ],
        onChanged: (v) => setState(() => _irSendMode = v ?? _irSendMode),
      ),
      const SizedBox(height: 16),
      if (_irSendMode == IrSendMode.named)
        TextFormField(
          controller: _irName,
          decoration: const InputDecoration(
            labelText: 'IR 채널 이름',
            hintText: '예: POWER_ON, HDMI1',
            border: OutlineInputBorder(),
          ),
          validator: (v) => (_irSendMode == IrSendMode.named &&
                  (v == null || v.trim().isEmpty))
              ? 'IR 채널 이름을 입력하세요'
              : null,
        )
      else
        TextFormField(
          controller: _irNumber,
          decoration: const InputDecoration(
            labelText: 'IR 채널 번호',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) =>
              (int.tryParse((v ?? '').trim()) == null) ? '숫자를 입력하세요' : null,
        ),
      const SizedBox(height: 8),
      SwitchListTile(
        title: const Text('실행 전 확인 팝업'),
        value: _confirm,
        onChanged: (v) => setState(() => _confirm = v),
      ),
    ];
  }

  List<Widget> _relayFields() {
    return [
      _sectionLabel('릴레이 설정'),
      DropdownButtonFormField<int>(
        initialValue: _relay,
        decoration: const InputDecoration(
          labelText: '릴레이 번호',
          border: OutlineInputBorder(),
        ),
        items: [
          for (var r = 1; r <= 8; r++)
            DropdownMenuItem(value: r, child: Text('릴레이 $r')),
        ],
        onChanged: (v) => setState(() => _relay = v ?? _relay),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<RelayMode>(
        initialValue: _relayMode,
        decoration: const InputDecoration(
          labelText: '동작',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: RelayMode.latchClose, child: Text('ON 유지 (close)')),
          DropdownMenuItem(value: RelayMode.latchOpen, child: Text('OFF 유지 (open)')),
          DropdownMenuItem(
              value: RelayMode.momentary, child: Text('순간 (close→open)')),
        ],
        onChanged: (v) => setState(() => _relayMode = v ?? _relayMode),
      ),
      const SizedBox(height: 16),
      if (_relayMode == RelayMode.momentary)
        TextFormField(
          controller: _duration,
          decoration: const InputDecoration(
            labelText: '순간 동작 시간 (ms)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            final n = int.tryParse((v ?? '').trim());
            if (n == null || n < 50 || n > 10000) return '50 ~ 10000 범위';
            return null;
          },
        ),
      SwitchListTile(
        title: const Text('실행 전 확인 팝업'),
        subtitle: const Text('오작동 방지. 켜면 실행 전 확인 창을 띄웁니다.'),
        value: _confirm,
        onChanged: (v) => setState(() => _confirm = v),
      ),
    ];
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
}
