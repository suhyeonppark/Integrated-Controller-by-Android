import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/command_result.dart';
import 'confirm_dialog.dart';

/// The primary touch control. One button = one action_id.
///
/// Activation is a single tap. Risky actions (those whose action def sets
/// `confirm`) first show a large confirmation dialog — this replaced the old
/// press-and-hold gesture, which testers found awkward.
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
    this.active = false,
  });

  final String label;
  final String actionId;
  final IconData? icon;
  final bool danger;
  final bool expand;

  /// True when this button represents the device's current state (e.g. the
  /// "ON" button while the relay is currently ON). Rendered with a restrained
  /// tinted surface and accent rail so the operator can see state without
  /// turning the controls into bright warning blocks.
  final bool active;

  @override
  State<ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool _locked = false;

  bool get _disabled => _locked || AppScope.read(context).isBusy;

  Future<void> _onTap() async {
    final state = AppScope.read(context);
    if (state.router.requiresConfirm(widget.actionId)) {
      final ok = await showConfirmDialog(
        context,
        message: state.router.confirmMessage(widget.actionId),
        danger: widget.danger,
      );
      if (!ok) return;
    }
    await _activate();
  }

  /// Runs the action and shows feedback.
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
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 40,
          ),
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text('${widget.label}: ${result.message}'),
          backgroundColor: result.success ? null : Colors.red.shade700,
          duration: const Duration(milliseconds: 1800),
        ),
      );
    }

    await Future<void>.delayed(state.config.buttonLock);
    if (mounted) setState(() => _locked = false);
  }

  // Quiet industrial palette: enough colour to read state at a glance, but
  // muted enough for a control room UI.
  static const Color _ink = Color(0xFF20242B);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceActive = Color(0xFFF5F8F7);
  static const Color _dangerSurface = Color(0xFFFBF7F6);
  static const Color _danger = Color(0xFFA94A3D);
  static const Color _dangerSoft = Color(0xFFD7A098);
  static const Color _on = Color(0xFF3F7568);
  static const Color _onSoft = Color(0xFF9DBDB4);
  static const Color _border = Color(0xFFE2E5E8);
  static const Color _muted = Color(0xFF7D848D);

  @override
  Widget build(BuildContext context) {
    final disabled = _disabled;
    final active = widget.active;
    final Color activeColor = widget.danger ? _danger : _on;
    final Color accentSoft = widget.danger ? _dangerSoft : _onSoft;

    final Color bg = active
        ? (widget.danger ? _dangerSurface : _surfaceActive)
        : _surface;
    final Color fg = active ? activeColor : (widget.danger ? _danger : _ink);
    final Color iconColor = active ? activeColor : _muted;
    final Color role = activeColor;
    final Color border = active ? accentSoft : _border;

    final Widget core = Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: bg,
        elevation: active ? 1 : 0,
        shadowColor: activeColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border, width: active ? 1.4 : 1.1),
        ),
        child: InkWell(
          onTap: disabled ? null : _onTap,
          splashColor: role.withValues(alpha: 0.08),
          highlightColor: role.withValues(alpha: 0.04),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 76),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: active ? 5 : 3,
                    color: active
                        ? activeColor
                        : (widget.danger
                              ? _danger.withValues(alpha: 0.34)
                              : Colors.transparent),
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (_locked)
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: iconColor,
                              ),
                            )
                          else if (widget.icon != null)
                            Icon(widget.icon, size: 22, color: iconColor),
                          if (_locked || widget.icon != null)
                            const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: fg,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          if (active) ...[
                            const SizedBox(width: 10),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: activeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return widget.expand ? SizedBox(width: double.infinity, child: core) : core;
  }
}
