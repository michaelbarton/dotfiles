# Dofiles

## OSX Setup

Run the following command to install plugins and link files.

```console
./ansible/apply_ansible
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fish -c "fisher update"
```

Download and install the Nord colour theme for iterm:
https://github.com/arcticicestudio/nord-iterm2

### OSX Email Setup

Create maildb directories e.g.

    mkdir -p ~/.maildb/michaelbarton

Create offlineimaprc files

    cp ~/.dotfiles/offlineimap/rc.osx ~/.offlineimaprc
    ln -s ~/.dotfiles/offlineimap/offlineimap.py ~/.offlineimap.py

Check the expected openssl file exists: `/usr/local/etc/openssl/cert.pem`. If
not see the openssl certificate section below.

Create a gmail application password in the gmail web page. Then create a
corresponding keychain entry with this password:

    security add-generic-password -a acct.gmail -s acct.gmail -w

Test that this password is correct by running offlineimap once. If there are
any issues make sure the account name in the KeyChain App matches that used in
the `offlineimaprc` file.

Set up launchctl to run offlineimap map automatically.

    ln -s ~/.dotfiles/offlineimap/uk.me.michaelbarton.offlineimap.plist ~/Library/LaunchAgents/
    launchctl load -w ~/Library/LaunchAgents/uk.me.michaelbarton.offlineimap.plist

Setup the mutt colour scheme section.

    mkdir ~/.mutt
    ln -s ~/.dotfiles/solarized/mutt-colors-solarized/mutt-colors-solarized-dark-256.muttrc ~/.mutt/colors

Copy the corresponding msmtprc file. Ensure that the password fetch command is
correct in this file.

    cp ~/.dotfiles/osx.rc ~/.msmtprc

### OpenSSL Certificate on OSX

The offlineimap program requires that a `cert.pem` file is available. The
location of file is configured by the offlineimaprc file. Depending on where
homebrew is installed this may be in a location like `$(brew --prefix)/etc/openssl@1.1/cert.pem`.

### Debugging launchctl agents

- Double check the path of the executable in the plist file points to the
  homebrew installed location of offline imap. If homebrew is installed to a
  different location this path may not be correct.
- See: https://apple.stackexchange.com/a/415074/227087

## Linux setup

Install common apt packages

    # Add gh command line source package repo
    # https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
    sudo apt-add-repository https://cli.github.com/packages
    sudo apt update

    xargs -a data/apt-packages sudo apt install --yes

### Linux Email Setup

Copy the msmtprc file manually, since a symlink is not recognised by the
program.

    cp ~/.dotfiles/msmtprc ~/.msmtprc
    chmod 600 ~/.msmptprc

Disable app armour for msmtp. This is required for it to be able to run the
command that fetches the password from lastpass.

    sudo ln -s /etc/apparmor.d/usr.bin.msmtp /etc/apparmor.d/disable/
    sudo apparmor_parser -R /etc/apparmor.d/usr.bin.msmtp

Store the gmail application password as an ubuntu secret:

    secret-tool store --label='Gmail application password' password gmail

Set up the systemd scripts to run offlineimap as a [systemd timer][].

    ln -s ~/.dotfiles/offlineimap/rc.linux ~/.offlineimaprc
    sudo ln -s ${HOME}/.dotfiles/systemd/user/offlineimap.service /etc/systemd/user/
    sudo ln -s ${HOME}/.dotfiles/systemd/user/offlineimap.timer /etc/systemd/user/

    # Checks the that the timer is valid
    systemd-analyze verify /etc/systemd/user/offlineimap.timer

    # Enable the service and start a first job
    systemctl --user enable offlineimap.service offlineimap.timer
    systemctl --user start offlineimap.timer

    # Check that offlineimap worked successfully
    journalctl | grep offlineimap

[systemd timer]: https://aishpant.dev/blog/mailing-lists/
