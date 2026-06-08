import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models/device_status.dart';

/// Top status strip showing IRS4 / REL8 connectivity (spec §10.1).
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _StatusChip(label: 'IRS4', status: state.irs4Status),
          const SizedBox(width: 12),
          _StatusChip(label: 'REL8', status: state.rel8Status),
          const Spacer(),
          IconButton(
            tooltip: '연결 상태 새로고침',
            icon: const Icon(Icons.refresh),
            onPressed: state.isBusy ? null : state.unawaitedTest,
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final DeviceStatus status;

  Color _color() {
    switch (status.state) {
      case DeviceConnectionState.online:
        return Colors.green;
      case DeviceConnectionState.offline:
        return Colors.red;
      case DeviceConnectionState.checking:
        return Colors.orange;
      case DeviceConnectionState.unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color(), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: _color()),
          const SizedBox(width: 8),
          Text(
            '$label: ${status.label}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
