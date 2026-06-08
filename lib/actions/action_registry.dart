import 'action_ids.dart';
import 'action_models.dart';

/// The single source of truth mapping action_id → concrete [ActionDef].
///
/// Per spec §9, definitions live in code as constants for the initial version,
/// but are isolated here so they can later be loaded from JSON / a settings
/// screen without touching the UI or router.
///
/// Relay channel assignment (CE-REL8) — sequential power (순차전원):
///   relay 1 = 전체 (master)   relay 2 = 순차1   relay 3 = 순차2
///   latching: close = ON / open = OFF
class ActionRegistry {
  ActionRegistry._();

  static const int _tv1Port = 1;
  static const int _tv2Port = 2;
  static const int _projectorPort = 3;

  static final Map<String, ActionDef> _actions = _build();

  static ActionDef? lookup(String id) => _actions[id];

  static Map<String, ActionDef> get all => Map.unmodifiable(_actions);

  static Map<String, ActionDef> _build() {
    final list = <ActionDef>[
      // ---- TV1 / Display 1 IR (port 1) ----
      const IrAction(id: ActionIds.tv1PowerOn, irPort: _tv1Port, irName: 'POWER_ON'),
      const IrAction(
        id: ActionIds.tv1PowerOff,
        irPort: _tv1Port,
        irName: 'POWER_OFF',
      ),
      const IrAction(id: ActionIds.tv1Hdmi1, irPort: _tv1Port, irName: 'HDMI1'),
      const IrAction(id: ActionIds.tv1Hdmi2, irPort: _tv1Port, irName: 'HDMI2'),
      const IrAction(id: ActionIds.tv1Hdmi3, irPort: _tv1Port, irName: 'HDMI3'),
      const IrAction(id: ActionIds.tv1Hdmi4, irPort: _tv1Port, irName: 'HDMI4'),
      const IrAction(id: ActionIds.tv1VolUp, irPort: _tv1Port, irName: 'VOL_UP'),
      const IrAction(id: ActionIds.tv1VolDown, irPort: _tv1Port, irName: 'VOL_DOWN'),
      const IrAction(id: ActionIds.tv1Mute, irPort: _tv1Port, irName: 'MUTE'),

      // ---- TV2 / Display 2 IR (port 2) ----
      const IrAction(id: ActionIds.tv2PowerOn, irPort: _tv2Port, irName: 'POWER_ON'),
      const IrAction(
        id: ActionIds.tv2PowerOff,
        irPort: _tv2Port,
        irName: 'POWER_OFF',
      ),
      const IrAction(id: ActionIds.tv2Hdmi1, irPort: _tv2Port, irName: 'HDMI1'),
      const IrAction(id: ActionIds.tv2Hdmi2, irPort: _tv2Port, irName: 'HDMI2'),
      const IrAction(id: ActionIds.tv2Hdmi3, irPort: _tv2Port, irName: 'HDMI3'),
      const IrAction(id: ActionIds.tv2Hdmi4, irPort: _tv2Port, irName: 'HDMI4'),
      const IrAction(id: ActionIds.tv2VolUp, irPort: _tv2Port, irName: 'VOL_UP'),
      const IrAction(id: ActionIds.tv2VolDown, irPort: _tv2Port, irName: 'VOL_DOWN'),
      const IrAction(id: ActionIds.tv2Mute, irPort: _tv2Port, irName: 'MUTE'),

      // ---- Projector IR (port 3) ----
      const IrAction(
        id: ActionIds.projectorPowerOn,
        irPort: _projectorPort,
        irName: 'POWER_ON',
      ),
      const IrAction(
        id: ActionIds.projectorPowerOff,
        irPort: _projectorPort,
        irName: 'POWER_OFF',
        confirm: true,
        confirmMessage: '프로젝터를 끄시겠습니까?',
      ),
      const IrAction(
        id: ActionIds.projectorHdmi1,
        irPort: _projectorPort,
        irName: 'HDMI1',
      ),
      const IrAction(
        id: ActionIds.projectorHdmi2,
        irPort: _projectorPort,
        irName: 'HDMI2',
      ),
      const IrAction(
        id: ActionIds.projectorMenu,
        irPort: _projectorPort,
        irName: 'MENU',
      ),
      const IrAction(
        id: ActionIds.projectorBack,
        irPort: _projectorPort,
        irName: 'BACK',
      ),

      // ---- Sequential power (순차전원) relays (latching: close=ON, open=OFF) ----
      // relay 1 = 전체(master), relay 2 = 순차1, relay 3 = 순차2.
      // No interlock (these are power circuits, not motors).
      const RelayAction(id: ActionIds.seqAllOn, relay: 1, mode: RelayMode.latchClose),
      const RelayAction(
        id: ActionIds.seqAllOff,
        relay: 1,
        mode: RelayMode.latchOpen,
        confirm: true,
        confirmMessage: '전체 전원을 끄시겠습니까?',
      ),
      const RelayAction(id: ActionIds.seq1On, relay: 2, mode: RelayMode.latchClose),
      const RelayAction(
        id: ActionIds.seq1Off,
        relay: 2,
        mode: RelayMode.latchOpen,
        confirm: true,
        confirmMessage: '순차 1 전원을 끄시겠습니까?',
      ),
      const RelayAction(id: ActionIds.seq2On, relay: 3, mode: RelayMode.latchClose),
      const RelayAction(
        id: ActionIds.seq2Off,
        relay: 3,
        mode: RelayMode.latchOpen,
        confirm: true,
        confirmMessage: '순차 2 전원을 끄시겠습니까?',
      ),

      // ---- Macros / modes ----
      const MacroAction(
        id: ActionIds.systemOn,
        confirm: true,
        confirmMessage: '시스템을 켜시겠습니까?',
        steps: [
          // Master power first; give the sequencer time to ramp its outlets.
          MacroStep(ActionIds.seqAllOn, delayAfterMs: 1500),
          MacroStep(ActionIds.projectorPowerOn, delayAfterMs: 500),
          MacroStep(ActionIds.tv1PowerOn, delayAfterMs: 500),
          MacroStep(ActionIds.tv2PowerOn, delayAfterMs: 0),
        ],
      ),
      const MacroAction(
        id: ActionIds.systemOff,
        confirm: true,
        confirmMessage: '시스템을 끄시겠습니까?',
        steps: [
          MacroStep(ActionIds.tv1PowerOff, delayAfterMs: 300),
          MacroStep(ActionIds.tv2PowerOff, delayAfterMs: 300),
          MacroStep(ActionIds.projectorPowerOff, delayAfterMs: 500),
          MacroStep(ActionIds.seqAllOff, delayAfterMs: 0),
        ],
      ),
      const MacroAction(
        id: ActionIds.presentationMode,
        confirm: false,
        steps: [
          MacroStep(ActionIds.projectorPowerOn, delayAfterMs: 500),
          MacroStep(ActionIds.projectorHdmi1, delayAfterMs: 300),
          MacroStep(ActionIds.tv1PowerOn, delayAfterMs: 300),
          MacroStep(ActionIds.tv1Hdmi1, delayAfterMs: 0),
          MacroStep(ActionIds.tv2PowerOn, delayAfterMs: 300),
          MacroStep(ActionIds.tv2Hdmi1, delayAfterMs: 0),
        ],
      ),
      const MacroAction(
        id: ActionIds.standbyMode,
        confirm: true,
        confirmMessage: '대기 모드로 전환하시겠습니까?',
        steps: [
          MacroStep(ActionIds.projectorPowerOff, delayAfterMs: 300),
          MacroStep(ActionIds.tv1PowerOff, delayAfterMs: 0),
          MacroStep(ActionIds.tv2PowerOff, delayAfterMs: 0),
        ],
      ),
      const MacroAction(
        id: ActionIds.allDisplayOn,
        confirm: false,
        steps: [
          MacroStep(ActionIds.tv1PowerOn, delayAfterMs: 400),
          MacroStep(ActionIds.tv2PowerOn, delayAfterMs: 400),
          MacroStep(ActionIds.projectorPowerOn, delayAfterMs: 0),
        ],
      ),
      const MacroAction(
        id: ActionIds.allDisplayOff,
        confirm: true,
        confirmMessage: '전체 디스플레이를 끄시겠습니까?',
        steps: [
          MacroStep(ActionIds.tv1PowerOff, delayAfterMs: 400),
          MacroStep(ActionIds.tv2PowerOff, delayAfterMs: 400),
          MacroStep(ActionIds.projectorPowerOff, delayAfterMs: 0),
        ],
      ),
    ];

    return {for (final a in list) a.id: a};
  }
}
