# Dofiles


## OSX Setup

- Install homebrew `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Install ansible `pip3 install ansible`

Run the following command to install plugins and link files.

    bin/apply_ansible

## Linux setup

Install common apt packages

    # Add gh command line source package repo
    # https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
    sudo apt-add-repository https://cli.github.com/packages
    sudo apt update

    xargs -a data/apt-packages sudo apt install --yes

## Set up email

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

## ITERM2

Iterm2 has better all round support for colours, tmux and accessing the the clipboard. This is installed using Caskroom in the section above.

  * Set "Allow clipboard access to terminal apps"
  * Profiles > Terminal > "Silence bell"
  * Profiles > Colors and click the drop down menu and select import. Select
    the file: 'solarized/iterm2-colors-solarized/Solarized Dark.terminal.' You
    may need to copy this file to the desktop first if you can access in in the
    file chooser box.
  * Set font to inconsolate-dz size 14


## Offlineimap

Create maildb directories e.g.

    mkdir -p ~/.maildb/michaelbarton

Create offlineimaprc files

    cp ~/.dotfiles/offlineimap/rc.osx ~/.offlineimaprc
    ln -s ~/.dotfiles/offlineimap/offlineimap.py ~/.offlineimap.py

Check the expected openssl file exists. This is configured in the RC file:
    - /usr/local/etc/openssl/cert.pem

Create a gmail application password and create a corresponding keychain entry with
this password:

    security add-generic-password -a acct.gmail -s acct.gmail -w

Set up launctl to run offlineimap map automatically.

    ln -s ~/.dotfiles/launchd_agents/uk.me.michaelbarton.offlineimap.plist ~/Library/LaunchAgents/
    launchctl load -w ~/Library/LaunchAgents/uk.me.michaelbarton.offlineimap.plist

## Mutt

    mkdir ~/.mutt
    ln -s ~/.dotfiles/solarized/mutt-colors-solarized/mutt-colors-solarized-dark-256.muttrc ~/.mutt/colors
