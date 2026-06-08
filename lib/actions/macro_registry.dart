import 'action_ids.dart';
import 'action_models.dart';

/// Built-in macros (system on/off, modes, all-display). These are fixed in v1
/// — they are not user-editable — and reference the default button ids so they
/// keep working as long as those buttons exist. If a referenced button is
/// deleted, the macro step fails gracefully (router reports which step).
List<MacroAction> builtInMacros() => const [
      MacroAction(
        id: ActionIds.systemOn,
        confirm: true,
        confirmMessage: '시스템을 켜시겠습니까?',
        steps: [
          MacroStep(ActionIds.seqAllOn, delayAfterMs: 1500),
          MacroStep(ActionIds.projectorPowerOn, delayAfterMs: 500),
          MacroStep(ActionIds.tv1PowerOn, delayAfterMs: 500),
          MacroStep(ActionIds.tv2PowerOn, delayAfterMs: 0),
        ],
      ),
      MacroAction(
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
      MacroAction(
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
      MacroAction(
        id: ActionIds.standbyMode,
        confirm: true,
        confirmMessage: '대기 모드로 전환하시겠습니까?',
        steps: [
          MacroStep(ActionIds.projectorPowerOff, delayAfterMs: 300),
          MacroStep(ActionIds.tv1PowerOff, delayAfterMs: 0),
          MacroStep(ActionIds.tv2PowerOff, delayAfterMs: 0),
        ],
      ),
      MacroAction(
        id: ActionIds.allDisplayOn,
        confirm: false,
        steps: [
          MacroStep(ActionIds.tv1PowerOn, delayAfterMs: 400),
          MacroStep(ActionIds.tv2PowerOn, delayAfterMs: 400),
          MacroStep(ActionIds.projectorPowerOn, delayAfterMs: 0),
        ],
      ),
      MacroAction(
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
