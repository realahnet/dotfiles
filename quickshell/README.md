# Quickshell rice

The Quickshell shell for this rice. It replaces waybar, swaync, swayosd,
hyprlock and hypridle.

## Running / autostart

Quickshell is started by Hyprland's autostart in hypr/hyprland.lua. It is not
a systemd user service, so it stays inside the Hyprland session and does not
start in a KDE Plasma session.

To restart it manually:

~~~bash
pkill -x qs
qs -p ~/.config/quickshell &
~~~

Quickshell auto-reloads when a .qml file changes, so you can leave it running
while editing.

## Notifications

Quickshell owns org.freedesktop.Notifications, with a notification center and
stacked toasts. Clicking outside the center closes it.

## Polkit

Quickshell also registers the polkit authentication agent, replacing
polkit-gnome. Requests show a centered, blurred card with the action message
and the same password pill used on the lock screen. Enter submits, Esc cancels.

Polkit uses pam.d/polkit-1 (installed by install.sh), which keeps
pam_unix.so nodelay and skips faillock, so repeated wrong attempts are not
deliberately slowed down.

## Lock / idle

Super+M locks through Quickshell. Idle timers: 5 min on
battery / 10 min on AC lock and turn off the display; 90 min on battery
suspends. The lock screenshot is captured before locking and reused after
DPMS/suspend, so waking a powered-off display does not show a black screen.

While the lock is secure, Quickshell switches Hyprland to an empty locked
submap, so global keybinds cannot fire. PAM is configured in
pam.d/quickshell-lock with pam_unix.so nodelay; there is no faillock and no
artificial delay between wrong password attempts.

## File map

```
quickshell/
├── shell.qml                    # entry point; what gets mounted
├── components/
│   ├── Bar.qml                  # one top bar per monitor
│   ├── BarWorkspaces.qml        # workspace pills + window icons
│   ├── BarGreeting.qml          # time-based greeting
│   ├── BarTray.qml              # tray icons + right-click menus
│   ├── TrayMenu.qml             # themed tray context menu
│   ├── TrayMenuCatcher.qml      # closes the menu on outside clicks
│   ├── BarAudio.qml             # PipeWire volume
│   ├── BarMedia.qml             # media pill that morphs into a player card
│   ├── MediaCard.qml            # art, seek bar, controls, art colour sampling
│   ├── BarBattery.qml           # UPower battery
│   ├── BarClock.qml             # clock + date
│   ├── BarNotificationButton.qml# bell -> notification center
│   ├── HoverPopup.qml           # shared hover card window
│   ├── BatteryMenu.qml          # battery hover card
│   ├── ClockMenu.qml            # clock/calendar hover card
│   ├── AudioMenu.qml            # volume + device picker
│   ├── VolumeSlider.qml         # monochrome slider
│   ├── GreetingMenu.qml         # greeting + weather card
│   ├── NotificationCenter.qml   # click-driven notification panel
│   ├── NotificationCard.qml     # one notification row
│   ├── NotificationToast.qml    # stacked top-right toasts
│   ├── ToastCard.qml            # one toast card + lifetime line
│   ├── Osd.qml                  # volume/brightness OSD pill
│   ├── OsdWatcher.qml           # volume + brightness change watcher
│   ├── LockScreen.qml           # WlSessionLock wrapper
│   ├── LockSurface.qml          # lock UI + PAM
│   ├── PolkitPrompt.qml         # polkit auth agent + password card
│   ├── Idle.qml                 # idle timers, DPMS, suspend, sleep lock
│   └── StyledText.qml           # Text with our font/colour defaults
└── services/
    ├── Theme.qml                # colours, font, measurements
    ├── ShellState.qml           # shared booleans/state
    ├── AppIcons.qml             # window class -> Nerd Font glyph
    ├── Weather.qml              # wttr.in weather singleton
    ├── Notifications.qml        # NotificationServer + toast queue
    ├── LockState.qml            # lock state + cached screenshot
    └── qmldir                   # tells QML these files are singletons
```

## Phases

- [x] Phase 1 — top bar: workspaces, greeting, tray, audio, battery, clock, bell
- [x] Phase 2 — notifications: center, cards, toast
- [x] Phase 3 — OSD for volume/brightness (swayosd replacement)
- [x] Phase 4 — lock screen + idle (hyprlock + hypridle replacement)
- [x] Phase 5 — tray context menus; launcher/emoji stays on rofi
- [x] Phase 6 — minimal polkit agent (polkit-gnome replacement)

## The one-sentence mental model

Quickshell is a QML app. Each `.qml` file is a component; `PanelWindow` is a
bar/window; the `Quickshell.Services.*` imports are live views of Hyprland,
PipeWire, UPower, notifications, etc. There is no CSS and no shell scripting
needed for the widgets themselves.