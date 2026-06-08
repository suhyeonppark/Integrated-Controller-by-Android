/// Canonical list of every action_id the app knows about (spec §18).
///
/// Keep all ids here so they are never scattered as magic strings across the
/// UI. The UI references [ActionIds.xxx]; the [ActionRegistry] maps each id to
/// its concrete definition.
class ActionIds {
  ActionIds._();

  // Macros / modes
  static const String systemOn = 'system_on';
  static const String systemOff = 'system_off';
  static const String presentationMode = 'presentation_mode';
  static const String standbyMode = 'standby_mode';
  static const String allDisplayOn = 'all_display_on';
  static const String allDisplayOff = 'all_display_off';

  // Display 1 (TV1) IR
  static const String tv1PowerOn = 'tv1_power_on';
  static const String tv1PowerOff = 'tv1_power_off';
  static const String tv1Hdmi1 = 'tv1_hdmi1';
  static const String tv1Hdmi2 = 'tv1_hdmi2';
  static const String tv1Hdmi3 = 'tv1_hdmi3';
  static const String tv1Hdmi4 = 'tv1_hdmi4';
  static const String tv1VolUp = 'tv1_vol_up';
  static const String tv1VolDown = 'tv1_vol_down';
  static const String tv1Mute = 'tv1_mute';

  // Display 2 (TV2) IR
  static const String tv2PowerOn = 'tv2_power_on';
  static const String tv2PowerOff = 'tv2_power_off';
  static const String tv2Hdmi1 = 'tv2_hdmi1';
  static const String tv2Hdmi2 = 'tv2_hdmi2';
  static const String tv2Hdmi3 = 'tv2_hdmi3';
  static const String tv2Hdmi4 = 'tv2_hdmi4';
  static const String tv2VolUp = 'tv2_vol_up';
  static const String tv2VolDown = 'tv2_vol_down';
  static const String tv2Mute = 'tv2_mute';

  // Projector IR
  static const String projectorPowerOn = 'projector_power_on';
  static const String projectorPowerOff = 'projector_power_off';
  static const String projectorHdmi1 = 'projector_hdmi1';
  static const String projectorHdmi2 = 'projector_hdmi2';
  static const String projectorMenu = 'projector_menu';
  static const String projectorBack = 'projector_back';

  // Sequential power (순차전원) relays.
  //   relay 1 = master (전체), relay 2 = circuit 1 (개별1), relay 3 = circuit 2 (개별2)
  //   latching: close = ON, open = OFF.
  static const String seqAllOn = 'seq_all_on';
  static const String seqAllOff = 'seq_all_off';
  static const String seq1On = 'seq1_on';
  static const String seq1Off = 'seq1_off';
  static const String seq2On = 'seq2_on';
  static const String seq2Off = 'seq2_off';
}
