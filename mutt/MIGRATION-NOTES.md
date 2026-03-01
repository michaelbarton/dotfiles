# Email Stack Migration: offlineimap → mbsync, mutt → neomutt

Research date: 2026-03-01

## Summary

mutt + offlineimap is no longer best practice. The modern consensus is
**neomutt + mbsync (isync)** + msmtp + notmuch.

## Why replace offlineimap with mbsync?

- offlineimap3 is effectively near-abandoned (no formal releases, unresolved
  issues, Gentoo considering removal, crashes on newer Python)
- mbsync is 3-5x faster (~2s vs 8-10s per sync), written in C, no Python dep
- Lower memory usage (offlineimap was notorious for OOM kills)
- Config concepts map directly: Repository → Store, Account → Channel

## Why neomutt over mutt?

- Actively developed fork, backwards compatible with muttrc
- First-class notmuch integration via virtual mailboxes (replaces
  mutt-notmuch-py script)
- Better color support, additional features

## Migration steps

1. **offlineimap → mbsync**: Rewrite offlineimap rc as ~/.mbsyncrc
   - Reuse existing maildir at ~/.maildb/
   - Password retrieval (secret-tool/Keychain) works the same way

2. **mutt → neomutt**: Existing muttrc works as-is
   - Add virtual mailbox config for notmuch
   - Remove mutt-notmuch-py script
   - GPG, mailcap, msmtp configs unchanged

3. **systemd timer**: Change ExecStart to /usr/bin/mbsync -a
   - Add ExecStartPost=/usr/bin/notmuch new

4. **macOS launchd**: Update plist to call mbsync instead of offlineimap

## Alternatives considered

- **aerc** (Go TUI): Modern, easier setup, but less mature. Not worth
  abandoning existing mutt config investment.
- **himalaya** (Rust CLI): Scriptable CLI, not a TUI. Different niche.
- **mu vs notmuch**: mu works better with folder-based multi-device workflows.
  notmuch's tag-based approach is better for single-machine power users.

## References

- https://anarc.at/blog/2021-11-21-mbsync-vs-offlineimap/
- https://vxlabs.com/2019/07/05/mbsync-vs-offlineimap-speed/
- https://people.kernel.org/mcgrof/replacing-offlineimap-with-mbsync
- https://blog.flaport.net/configuring-neomutt-for-email.html
- https://neomutt.org/feature/notmuch
- https://benswift.me/blog/2025/09/12/the-great-2025-email-yak-shave-o365-mbsync-mu-neomutt-msmtp
