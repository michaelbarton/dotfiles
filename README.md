## SUBMODULES

Run the following command in the root of the directory

    git submodule init
    git submodule update

This will fetch all the git submodules in this directory.

## COLORS

Go into Terminal Preferences > Settings > Advanced. Make sure declare terminal as 'xterm-256color.' I think this may only work on OSX Lion upwards. Go to the bottom of the Preferences > Settings page and click the drop down menu and select import. Select the file: 'solarized/osx-terminal.app-colors-solarized/Solarized Dark ansi.terminal.' You may need to copy this file to the desktop first if you can access in in the file chooser box.

## CAPS LOCK

I reset caps lock to be ctrl. I find this a bit better than reaching for the actual control key with my small finger. You can do this by going into keyboard in system preferences and changing the modifier keys.

## FONTS

I use consolas. Follow the directions [on this page][consolas] to set the font up correctly. Go into terminal settings and specific a font size that won't strain the eyes. I use 16pt. I also enable the increased font smoothing described on the post above

    defaults -currentHost write -globalDomain AppleFontSmoothing -int 2

[consolas]: http://www.wezm.net/technical/2010/08/howto-install-consolas-font-mac/

## SOFT LINK

Run the following command to link all the dotfiles into your home directory.

    ls ~/.dotfiles | xargs -I '{}' ln -s ~/.dotfiles/{} ~/.{}
    
Also softlink dir colors

   ln ~/.dircolors-solarized/dircolors.256dark ~/.dir_colors

## INSTALL SOFTWARE

Install additional required software through homebrew. I keep a list of this software in the file brews.

## SHELL

I use tmux as my shell. After installation with hombrew, edit /etc/shells to include the line:

    /usr/local/bin/tmux
    
Then run the following command

    chsh -s /usr/local/bin/tmux
    
## VIM

Soft link the vim solarized color scheme into the vim colors directory. I only use solarized for colors but if you use others, you'll have to link just the files you want into that directory.

    ln -s solarized/vim-colors-solarized/colors vim/colors

If you experience any problems with this make sure that terminal colors are correctly set as above in 'COLORS.'

## MACTEX

Download and install mactex - http://tug.org/mactex/.

## PASSWORDS

Add required passwords to keychain. Then use security to fetch them in the environment. E.g. email password and github.token

## Offline imap

Create maildb directories e.g. 

    mkdir -p ~/.maildb/michaelbarton ~/.maildb/jgi

Set up gmail certificates:

    openssl s_client -connect imap.gmail.com:993 >| imap.cert.pub
    openssl x509 -noout -fingerprint -in imap.cert.pub \
      | cut -d = -f 2 \
      | tr -d ':' \
      | tr '[:upper:]' '[:lower:]'

Add the generated fingerprint to the offlinemaprc file if required.

## Mutt

    mkdir ~/.mutt ln -s
    ~/.dotfiles/solarized/mutt-colors-solarized/mutt-colors-solarized-dark-256.muttrc
    ~/.mutt/colors

## iterm2

Set terminal type as xterm-256color for best colors.
