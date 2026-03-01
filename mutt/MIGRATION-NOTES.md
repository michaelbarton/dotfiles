# Email Stack Migration: offlineimap → lieer, mutt → neomutt

Research date: 2026-03-01

## Summary

mutt + offlineimap is no longer best practice. For Gmail users (personal
and Google Workspace/SSO), the recommended stack is:

**neomutt + lieer + notmuch**

For non-Gmail IMAP, the recommendation would be neomutt + mbsync + notmuch,
but since both accounts are Gmail, lieer is the better choice.

## Why lieer over mbsync (for Gmail)?

- Uses Gmail API directly, not IMAP — avoids all Gmail IMAP quirks
  (duplicate messages across labels, weird folder names)
- OAuth2 is built-in and first-class — critical for SSO/Google Workspace
  where app passwords are unavailable (Google killed them March 2025)
- Bidirectional label ↔ notmuch tag sync (archive locally = archive on Gmail)
- No need for cyrus-sasl-xoauth2 plugin, token refresh scripts, or GCP
  consent screen workarounds
- Can also send mail via Gmail API (no msmtp needed, though it's optional)

## Why not offlineimap?

- offlineimap3 is near-abandoned (no formal releases, unresolved issues,
  Gentoo considering removal, crashes on newer Python)
- mbsync is 3-5x faster but still has Gmail IMAP quirks
- Neither handles Gmail OAuth2/SSO gracefully

## Why neomutt over mutt?

- Actively developed fork, backwards compatible with muttrc
- First-class notmuch integration via virtual mailboxes (replaces
  mutt-notmuch-py script)
- Better color support, additional features

## Target architecture

```
Personal Gmail:  lieer → ~/.mail/personal/ → notmuch → neomutt
Work SSO Gmail:  lieer → ~/.mail/work/     → notmuch → neomutt
```

Sync: `gmi sync` per account, or via notmuch pre-new hook.
Send: lieer (Gmail API) or msmtp (SMTP with XOAUTH2).

## Migration steps

1. **Install lieer and neomutt**
   - `pip install lieer` or package manager
   - `brew install neomutt` / `apt install neomutt`

2. **Set up mail directories**
   - `mkdir -p ~/.mail/personal ~/.mail/work`
   - `cd ~/.mail/personal && gmi init personal@gmail.com`
   - `cd ~/.mail/work && gmi init you@company.com`
   - Each `gmi init` opens browser for OAuth2 consent

3. **Initial sync**
   - `cd ~/.mail/personal && gmi pull` (may take a while for large mailboxes)
   - `cd ~/.mail/work && gmi pull`

4. **Configure notmuch**
   - Point notmuch database at ~/.mail/
   - Set `tags_to_apply_to_new_messages` to empty (lieer manages tags)
   - Add `ignore=/.*[.](json|lock|bak)$/` to notmuch config

5. **mutt → neomutt**
   - Existing muttrc works as-is
   - Add virtual mailbox config for notmuch queries:
     ```
     virtual-mailboxes "inbox" "notmuch://?query=tag:inbox"
     virtual-mailboxes "sent"  "notmuch://?query=tag:sent"
     ```
   - Remove mutt-notmuch-py script (replaced by native integration)
   - GPG, mailcap configs unchanged

6. **Automate sync**
   - Create notmuch pre-new hook that runs `gmi sync` for each account
   - Update systemd timer / launchd plist to run `notmuch new`

7. **Sending mail**
   - Option A: `gmi send` (Gmail API, no SMTP config needed)
   - Option B: Keep msmtp with XOAUTH2 if preferred

## SSO / Google Workspace caveat

lieer ships a default OAuth client ID for personal Gmail. For Google
Workspace with SSO, you may need to:
- Create an OAuth credential in your org's GCP project, OR
- Ask IT to allowlist lieer's default client ID
Check with your workspace admin before starting.

## What stays, what goes

| Component       | Action                                      |
|-----------------|---------------------------------------------|
| offlineimap     | DROP — replaced by lieer                    |
| msmtp           | OPTIONAL — lieer can send via Gmail API     |
| notmuch         | KEEP — lieer is built around it             |
| mutt-notmuch-py | DROP — neomutt has native notmuch support   |
| mutt → neomutt  | UPGRADE — backwards compatible              |
| GPG config      | KEEP — unchanged                            |
| mailcap         | KEEP — unchanged                            |

## Alternatives considered

- **mbsync (isync)**: Best for non-Gmail IMAP. For Gmail, IMAP quirks and
  OAuth2 setup complexity make lieer preferable.
- **aerc** (Go TUI): Modern, easier setup, but less mature than neomutt.
  Not worth abandoning existing mutt config.
- **himalaya** (Rust CLI): Scriptable CLI, not a TUI. Different niche.
- **mu vs notmuch**: mu better for folder-based multi-device workflows.
  lieer is designed specifically for notmuch, making notmuch the clear choice.

## References

- https://github.com/gauteh/lieer
- https://www.jevy.org/articles/neomutt-lieer-notmuch/
- https://anarc.at/blog/2021-11-21-mbsync-vs-offlineimap/
- https://neomutt.org/feature/notmuch
- https://support.google.com/a/answer/14114704
- http://blog.onodera.asia/2022/09/how-to-use-google-workspace-oauth2-with.html
- https://blog.flaport.net/configuring-neomutt-for-email.html
