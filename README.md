## SUBMODULES AND PACKAGES

Run the following command in the root of the dotfiles directory to pull required submodules

    git submodule init
    git submodule update

Run the following command to install all additional tools and apps

    ~/.dotfiles/bin/brews
    ~/.dotfiles/bin/gems
    ~/.dotfiles/bin/fonts

Install vim plugins

    vim +PluginInstall +qall

## SOFT LINK

Run the following command to link all the dotfiles into your home directory.

    ls ~/.dotfiles | xargs -I '{}' ln -s ~/.dotfiles/{} ~/.{}
    
Also softlink colors schemes

   ln -s ~/.dircolors-solarized/dircolors.256dark ~/.dir_colors

## SHELL

I use tmux as my shell. After installation with as above, edit /etc/shells to include the line:

    /usr/local/bin/tmux
    
Then run the following command

    chsh -s /usr/local/bin/tmux

## CAPS LOCK

Reset caps lock to be ctrl, System Preferences > Keyboard > Modifier Keys. I find this a bit better than reaching for the actual control key with my small finger.

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

Add required passwords to keychain. Then use security to fetch them in the environment. E.g. email password and github.token

## Offline imap

Create maildb directories e.g. 

    mkdir -p ~/.maildb/michaelbarton ~/.maildb/jgi

Set up certificates files:

    ruby -ropenssl -e "p OpenSSL::X509::DEFAULT_CERT_FILE"

## Mutt

    mkdir ~/.mutt
    ln -s ~/.dotfiles/solarized/mutt-colors-solarized/mutt-colors-solarized-dark-256.muttrc ~/.mutt/colors
