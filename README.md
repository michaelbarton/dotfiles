# Generic instructions

Run the following command in the root of the dotfiles directory to pull
required submodules:

    git submodule update --init --recursive

Run the following command to link all the dotfiles into your home directory.

    ls ~/.dotfiles | xargs -I '{}' ln -s ~/.dotfiles/{} ~/.{}

Set up shell scripts.

    mkdir ${HOME}/.zsh_cache/

    echo "#!/bin/bash" > ${HOME}/.local_bash_settings.sh
    chmod 700 ${HOME}/.local_bash_settings.sh


Install required vim plugins

    vim +PluginInstall +qall

# Linux instructions

Install common apt packages

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

# OSX specific instructions

Run the following command to install all additional tools, apps, and fonts
using rubygems and homebrew.

    ~/.dotfiles/bin/brews
    ~/.dotfiles/bin/gems
    ~/.dotfiles/bin/fonts

Reset caps lock to be ctrl, System Preferences > Keyboard > Modifier Keys. I
find this a bit better than reaching for the actual control key with my small
finger.

## ITERM2

Iterm2 has better all round support for colours, tmux and accessing the the clipboard. This is installed using Caskroom in the section above.

  * Set "Allow clipboard access to terminal apps"
  * Profiles > Terminal > "Silence bell"
  * Profiles > Colors and click the drop down menu and select import. Select
    the file: 'solarized/iterm2-colors-solarized/Solarized Dark.terminal.' You 
    may need to copy this file to the desktop first if you can access in in the 
    file chooser box.
  * Set font to inconsolate-dz size 14

## MACTEX

Download and install mactex - http://tug.org/mactex/.

## PASSWORDS

Add required passwords to keychain. Then use security to fetch them in the
environment. E.g. email password and github.token

## Offline imap

Create maildb directories e.g. 

    mkdir -p ~/.maildb/michaelbarton ~/.maildb/jgi

Set up certificates files:

    ruby -ropenssl -e "p OpenSSL::X509::DEFAULT_CERT_FILE"

## Mutt

    mkdir ~/.mutt
    ln -s ~/.dotfiles/solarized/mutt-colors-solarized/mutt-colors-solarized-dark-256.muttrc ~/.mutt/colors
