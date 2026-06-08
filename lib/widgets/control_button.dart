import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/command_result.dart';
import 'confirm_dialog.dart';

/// The primary touch control. One button = one action_id.
///
/// Two activation modes:
///  - **tap** (default): single tap runs the action. Risky actions first show a
///    confirmation dialog.
///  - **hold** ([holdMs] > 0): the operator must press and hold for [holdMs]
///    before the action fires (used for power control). A progress fill shows
///    the hold. Releasing early cancels. The deliberate hold replaces the
///    confirmation dialog, so hold buttons never also pop a confirm.
///
/// Shared behaviour (spec §11.3, §14, §15, §16):
///  - anti double-tap lock for `button_lock_ms` after each activation
///  - disabled while a macro is running (global busy)
///  - "command sent" feedback (never claims device state); strong alert on a
///    warning result
///  - NEVER builds TCP strings; only calls [AppState.runAction]
class ControlButton extends StatefulWidget {
  const ControlButton({
    super.key,
    required this.label,
    required this.actionId,
    this.icon,
    this.danger = false,
    this.expand = true,
    this.holdMs = 0,
  });

  final String label;
  final String actionId;
  final IconData? icon;
  final bool danger;
  final bool expand;

  /// If > 0, the button must be held this long to activate.
  final int holdMs;

  bool get isHold => holdMs > 0;

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton>
    with SingleTickerProviderStateMixin {
  bool _locked = false;
  AnimationController? _hold;

  @override
  void initState() {
    super.initState();
    if (widget.isHold) {
      _hold = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.holdMs),
      )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _activate(); // hold reached — fire (no confirm dialog)
            _hold?.reset();
          }
        });
    }
  }

  @override
  void dispose() {
    _hold?.dispose();
    super.dispose();
  }

  bool get _disabled => _locked || AppScope.read(context).isBusy;

  // --- Tap mode ---
  Future<void> _onTap() async {
    final state = AppScope.read(context);
    if (state.router.requiresConfirm(widget.actionId)) {
      final ok = await showConfirmDialog(
        context,
        message: state.router.confirmMessage(widget.actionId),
      );
      if (!ok) return;
    }
    await _activate();
  }

  // --- Hold mode gesture handlers ---
  void _onHoldStart() {
    if (_disabled) return;
    _hold?.forward();
  }

  void _onHoldEnd() {
    final c = _hold;
    if (c != null && c.status != AnimationStatus.completed) {
      c.reverse();
    }
  }

  /// Runs the action and shows feedback. Shared by both modes.
  Future<void> _activate() async {
    if (_locked) return;
    final state = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _locked = true);

    CommandResult result;
    try {
      result = await state.runAction(widget.actionId);
    } catch (e) {
      result = CommandResult.fail('예기치 못한 오류: $e');
    }

    if (!mounted) return;

    if (result.isWarning) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded,
              color: Colors.orange, size: 40),
          title: const Text('경고'),
          content: Text(result.message, style: const TextStyle(fontSize: 18)),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${widget.label}: ${result.message}'),
          backgroundColor: result.success ? null : Colors.red.shade700,
          duration: const Duration(milliseconds: 1800),
        ),
      );
    }

    await Future<void>.delayed(state.config.buttonLock);
    if (mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final disabled = _locked || state.isBusy;
    final scheme = Theme.of(context).colorScheme;
    final bg = widget.danger ? Colors.red.shade700 : scheme.primaryContainer;
    final fg = widget.danger ? Colors.white : scheme.onPrimaryContainer;

    final Widget core = widget.isHold
        ? _buildHoldButton(disabled, bg, fg)
        : _buildTapButton(disabled, bg, fg);

    return widget.expand ? SizedBox(width: double.infinity, child: core) : core;
  }

  Widget _buildTapButton(bool disabled, Color bg, Color fg) {
    return FilledButton(
      onPressed: disabled ? null : _onTap,
      style: _style(bg, fg),
      child: _content(fg, showSpinner: _locked),
    );
  }

  Widget _buildHoldButton(bool disabled, Color bg, Color fg) {
    return GestureDetector(
      onTapDown: (_) => _onHoldStart(),
      onTapUp: (_) => _onHoldEnd(),
      onTapCancel: _onHoldEnd,
      child: AnimatedBuilder(
        animation: _hold!,
        builder: (context, _) {
          final progress = _hold!.value;
          final effectiveBg = disabled ? bg.withValues(alpha: 0.35) : bg;
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Base
                Container(
                  height: 72,
                  color: effectiveBg,
                ),
                // Hold progress fill
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 72,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                // Content
                Positioned.fill(
                  child: Center(
                    child: _content(
                      disabled ? fg.withValues(alpha: 0.5) : fg,
                      showSpinner: _locked,
                      holdHint: progress == 0 && !_locked,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ButtonStyle _style(Color bg, Color fg) => FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.35),
        disabledForegroundColor: fg.withValues(alpha: 0.5),
        minimumSize: const Size(0, 72), // ≥72dp touch target (spec §12)
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _content(Color fg, {bool showSpinner = false, bool holdHint = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSpinner)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else if (holdHint)
          Icon(Icons.touch_app, size: 22, color: fg)
        else if (widget.icon != null)
          Icon(widget.icon, size: 24, color: fg),
        if (showSpinner || holdHint || widget.icon != null)
          const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.isHold && holdHint ? '${widget.label} (길게)' : widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ],
    );
  }
}
