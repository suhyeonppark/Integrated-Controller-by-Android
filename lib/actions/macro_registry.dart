import 'action_ids.dart';
import 'action_models.dart';

/// Built-in macros. These are fixed in v1 — they are not user-editable — and
/// reference the default button ids so they keep working as long as those
/// buttons exist. If a referenced button is deleted, the macro step fails
/// gracefully (router reports which step).
List<MacroAction> builtInMacros() => const [
      MacroAction(
        id: ActionIds.seqAllOn,
        confirm: false,
        steps: [
          MacroStep(ActionIds.seq1On, delayAfterMs: 300),
          MacroStep(ActionIds.seq2On, delayAfterMs: 0),
        ],
      ),
      MacroAction(
        id: ActionIds.seqAllOff,
        confirm: true,
        confirmMessage: '전체 전원을 끄시겠습니까?',
        steps: [
          MacroStep(ActionIds.seq2Off, delayAfterMs: 300),
          MacroStep(ActionIds.seq1Off, delayAfterMs: 0),
        ],
      ),
      MacroAction(
        id: ActionIds.systemOn,
        confirm: true,
        confirmMessage: '시스템을 켜시겠습니까?',
        steps: [
          MacroStep(ActionIds.seqAllOn, delayAfterMs: 1500),
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
          MacroStep(ActionIds.seqAllOff, delayAfterMs: 0),
        ],
      ),
      MacroAction(
        id: ActionIds.allDisplayOn,
        confirm: false,
        steps: [
          MacroStep(ActionIds.tv1PowerOn, delayAfterMs: 400),
          MacroStep(ActionIds.tv2PowerOn, delayAfterMs: 400),
        ],
      ),
      MacroAction(
        id: ActionIds.allDisplayOff,
        confirm: true,
        confirmMessage: 'TV 전체를 끄시겠습니까?',
        steps: [
          MacroStep(ActionIds.tv1PowerOff, delayAfterMs: 400),
          MacroStep(ActionIds.tv2PowerOff, delayAfterMs: 400),
        ],
      ),
    ];
