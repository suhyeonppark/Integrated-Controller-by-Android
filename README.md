# AMX CE Control (Android tablet, standalone)

Standalone Android tablet app to control **AMX CE-IRS4** (IR) and **AMX CE-REL8**
(relay) over TCP, with **no server**. The tablet connects directly to each device
on TCP port **44197** using the CE-Series 3rd-party ASCII control protocol.

```
[Android Tablet App]
   ├── TCP 44197 → CE-IRS4 → IR devices (TV, projector, …)
   └── TCP 44197 → CE-REL8 → relays (screen, lift, PDU, AMP)
```

## Architecture

UI never builds TCP strings. Everything flows through the Action Router:

```
UI Button → ActionRouter.run(actionId)
                 ├── IR action     → CeIrs4Client → CeTcpClient
                 ├── Relay action  → InterlockManager → CeRel8Client → CeTcpClient
                 └── Macro action  → runs sub-actions in order with delays
```

| Layer | File |
|-------|------|
| TCP transport (connect→send→close, timeouts, error→message) | `lib/ce/ce_tcp_client.dart` |
| CE-IRS4 command builder (only place IR strings exist) | `lib/ce/ce_irs4_client.dart` |
| CE-REL8 command builder (only place relay strings exist) | `lib/ce/ce_rel8_client.dart` |
| Action definitions (ids, models, registry) | `lib/actions/` |
| Relay safety / interlock | `lib/actions/interlock_manager.dart` |
| Dispatcher | `lib/actions/action_router.dart` |
| App state + services (ChangeNotifier) | `lib/app_state.dart` |
| Screens (home / IR / relay / settings) | `lib/screens/` |
| Reusable widgets | `lib/widgets/` |

## Wire protocol (verified against AMX CE-Series manual)

TCP port **44197**, raw ASCII socket, messages delimited by `\n`. Paths use
1-based port numbers.

**CE-IRS4 (IR)** — `exec` commands:

```
exec /ir/3/bufferedSendNamedIr "PLAY"   # named IR
exec /ir/3/bufferedSendIr 1             # IR by index
exec /ir/3/loadIrFile "samsung01.irl"   # load .irl
```

**CE-REL8 (relay)** — single boolean parameter `/relay/#/state`, set with the
`set` message (not `exec`):

```
set /relay/1/state true    # ON  / close (engaged)
set /relay/1/state false   # OFF / open
```

The protocol has no native relay pulse, so momentary mode is done in software
(set true → wait → set false). All relay wire strings are isolated to
`_closeCommand` / `_openCommand` in `lib/ce/ce_rel8_client.dart`.

## Relay channel map (CE-REL8) — sequential power (순차전원)

| Relay | Function | Mode |
|-------|----------|------|
| 1 | 전체 (master) on/off | latching (close = ON, open = OFF) |
| 2 | 순차 1 on/off | latching |
| 3 | 순차 2 on/off | latching |

Power circuits, so no motor interlock. The interlock framework
(`InterlockManager`, `openBeforeClose`, momentary mode) remains in place for
future motorized loads (screen/lift).

## IR map (CE-IRS4)

| IR port | Device |
|---------|--------|
| 1 | TV1 (Display 1) |
| 2 | TV2 (Display 2) |
| 3 | Projector |

## Tap vs. hold

- **IR buttons (TV1 / TV2 / projector): single tap.**
- **Power buttons (순차전원): press-and-hold for 2 seconds** to activate. A
  progress fill shows the hold; releasing early cancels. The deliberate hold
  replaces the confirmation dialog, preventing accidental power switching.

## Settings (persisted via shared_preferences)

- **Devices:** CE-IRS4 IP/port, CE-REL8 IP/port, TCP timeout (default 2000 ms),
  button lock (default 1000 ms), with connection test.
- **버튼 편집 (button editor):** add / delete / edit every IR and power button.
  Buttons are data-driven (`ButtonConfig`, stored under `buttons_v1`), so the IR
  and 전원 screens render whatever is configured. Editable per button:
  - IR: label, group, **IR port (1–4)** + **IR channel (named or by index)**,
    confirm dialog, danger color.
  - Power (relay): label, group, **relay number (1–8)**, mode (ON-latch /
    OFF-latch / momentary), 2-second hold, confirm/danger.
  - "기본값 복원" restores the factory button set.

Home-screen macros (system on/off, modes) are built-in (fixed in v1) and
reference the default button ids.

## Safety & UX

- Risky tap buttons (system off, all-display off, projector off) show a
  confirmation dialog. Power buttons use the 2-second hold instead.
- Anti double-tap: each button is locked for `button_lock_ms` after a press;
  all controls are disabled while a macro runs.
- A momentary relay whose trailing OPEN fails is retried, then raises a strong
  warning dialog (spec §11.4).
- IR/relay are one-way: the UI only reports "command sent", never device state.
- Network errors are caught and shown as friendly messages — the app never
  crashes on a failed command.
- Screen kept awake (`wakelock_plus`); landscape-first.

## Build & run

```bash
flutter pub get
flutter test
flutter run                 # on a connected tablet
flutter build apk --release # installable APK at build/app/outputs/flutter-apk/
```

Requires `INTERNET` permission (already in `AndroidManifest.xml`) for LAN TCP.
