

set fish_greeting                                 # Supresses fish's intro message
set TERM "xterm-256color"                         # Sets the terminal type


### SET EITHER DEFAULT EMACS MODE OR VI MODE ###
function fish_user_key_bindings
    fish_default_key_bindings
end 


### AUTOCOMPLETE AND HIGHLIGHT COLORS ###

set fish_color_normal brcyan
set fish_color_autosuggestion '#7d7d7d'
set fish_color_command brcyan
set fish_color_error '#ff6c6b'
set fish_color_param brcyan



### FUNCTIONS ###

# Functions needed for !! and !$
function __history_previous_command
  switch (commandline -t)
  case "!"
    commandline -t $history[1]; commandline -f repaint
  case "*"
    commandline -i !
  end
end

function __history_previous_command_arguments
  switch (commandline -t)
  case "!"
    commandline -t ""
    commandline -f history-token-search-backward
  case "*"
    commandline -i '$'
  end
end

# The bindings for !! and !$
if [ "$fish_key_bindings" = "fish_vi_key_bindings" ];
  bind -Minsert ! __history_previous_command
  bind -Minsert '$' __history_previous_command_arguments
else
  bind ! __history_previous_command
  bind '$' __history_previous_command_arguments
end


### ALIASES ###
# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'


# # Changing "ls" to "exa"
# alias ls='exa -al --color=always --group-directories-first' # my preferred listing
# alias la='exa -a --color=always --group-directories-first'  # all files and dirs
# alias ll='exa -l --color=always --group-directories-first'  # long format
# alias lt='exa -aT --color=always --group-directories-first' # tree listing
# alias l.='exa -a | egrep "^\."'




# Alias LS

alias ll='exa --icons -lh --group-directories-first'
alias la='exa --icons -lgha --group-directories-first'
alias l='exa --icons --group-directories-first'
alias lla='exa --icons -lha --group-directories-first'
alias ls='exa --icons --group-directories-first'
alias lt='exa --icons --tree'
alias lta='exa -lgha --icons --tree'
alias lld='exa --icons -lh -s modified'
alias llad='exa --icons -lha -s modified'


alias cat='batcat'
alias icat="kitty +kitten icat"
# alias remove_mysql_root='/home/dachival/Proyectos/Scripts/rm_mysql.sh'


alias python='/usr/bin/python3'
alias vim="/home/daniel/.appimage/neovim.appimage"
alias emacs="macsclient -c -a 'emacs'"

alias grub-update='sudo grub-mkconfig -o /boot/grub/grub.cfg'

#git

alias gitgraph="git log --all --decorate --oneline --graph"
alias gitupdate="git fetch . && git pull"
alias gitstat="git status"
alias gitad="git add . "
alias gitcom="git commit -m"


#Refresh
# alias refresh="source $HOME/.zshrc "

#Convert Video
alias convi="ffmpeg -i $1 -c:v libx264 -crf 25 $2"

#launch android emulator
alias emulator="$HOME/Android/Sdk/emulator/emulator"



# fzf
alias preview="fzf --preview='batcat --color=always --style=numbers --theme OneHalfDark {}' --preview-window=down"


### SETTING THE STARSHIP PROMPT ###
starship init fish | source

# pnpm
set -gx PNPM_HOME "/home/daniel/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/daniel/anaconda3/bin/conda
    eval /home/daniel/anaconda3/bin/conda "shell.fish" "hook" $argv | source
else
    if test -f "/home/daniel/anaconda3/etc/fish/conf.d/conda.fish"
        . "/home/daniel/anaconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH "/home/daniel/anaconda3/bin" $PATH
    end
end
# <<< conda initialize <<<

