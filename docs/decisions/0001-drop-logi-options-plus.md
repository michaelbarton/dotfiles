# 0001: Stop using Logi Options+

- Status: accepted
- Date: 2026-09-29

## Context

Logi Options+ 1.98.809639 (macOS) became a persistent CPU drain:

- `logioptionsplus_updater`, a root LaunchDaemon, ran at 60-83% CPU for the
  whole 6 days of uptime, and load average peaked at 108.
- After restarting it, `logioptionsplus_agent` returned to ~49% CPU within
  minutes. A stack sample showed macOS code-signature validation
  (`SecStaticCode::validateDirectory`) plus SHA-256 hashing and many file reads,
  so the loop is inside the vendor agent.
- The Options+ window sat on a spinner and never loaded, because the agent it
  talks to never answered.

Other users report Options+ CPU spikes, and Logitech has shipped fixes for a
different one (1.52.456542, CPU on backend shutdown). I found no documented way
to disable only the updater.

The only Logitech input device here is a Trackman Marble (T-BC21), a wired
plain-USB HID trackball that macOS drives without vendor software. Options+ was
not doing anything I could confirm for it.

## Decision

Stop running Options+. Do not manage it from this repo.

Alternatives considered:

- OpenLogi: speaks HID++, which a wired Marble likely does not. Four months old,
  README says "not yet stable", and it has had its own macOS CPU bugs (issues
  541 and 1281).
- Mouser: built for the MX Master 3S.
- LinearMouse: works with any USB mouse and is Homebrew-installable, but is not
  adopted yet because nothing needs remapping so far.

## What was done

Run as the user (no sudo), reversible:

```sh
pkill -x logioptionsplus
launchctl bootout gui/$(id -u) /Library/LaunchAgents/com.logi.optionsplus.plist
launchctl disable gui/$(id -u)/com.logi.optionsplus
```

## Still open

Root-owned pieces remain because removing them needs sudo, and there was no
Options+ uninstaller on disk:

- `/Applications/logioptionsplus.app`
- `/Library/Application Support/Logitech.localized/LogiOptionsPlus`
- `/Library/LaunchDaemons/com.logi.optionsplus.updater.plist`
- `/Library/LaunchAgents/com.logi.optionsplus.plist`

UNVERIFIED: the sudo commands below were not run. To stop the updater:

```sh
sudo launchctl bootout system /Library/LaunchDaemons/com.logi.optionsplus.updater.plist
sudo launchctl disable system/com.logi.optionsplus.updater
```

The Logitech webcam software (LogiSync, LogiRightSight) is separate and was left
alone. This machine is Jamf-managed, so Jamf may reinstall or re-enable
Options+; that is unverified.

## Re-entry

To use Options+ again:

1. Re-enable the agent: `launchctl enable gui/$(id -u)/com.logi.optionsplus`
   then
   `launchctl bootstrap gui/$(id -u) /Library/LaunchAgents/com.logi.optionsplus.plist`.
   If the updater daemon was disabled, run
   `sudo launchctl enable system/com.logi.optionsplus.updater`.
2. Install a current build first. The CPU loop may be fixed upstream, and a
   clean reinstall is the vendor-supported route for a bad signature check.
3. Confirm it is worth it: Options+ must list the device and offer a feature
   macOS does not already provide. Re-check that `logioptionsplus_agent` and
   `logioptionsplus_updater` stay near 0% CPU for a day (`ps -Ao pcpu,command`
   or Activity Monitor) before relying on it.
4. Do not run it alongside OpenLogi; both want exclusive HID++ access.

For button remapping or scroll tuning without Options+, try LinearMouse
(`brew install --cask linearmouse`) and add it to the Brewfile with its config
in this repo. Untested with the T-BC21.
