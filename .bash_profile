alias ..='cd ..'
export EDITOR=/usr/bin/vim
alias tarmake='tar -cpzf'
alias untar='tar -xzf'
alias netusage='lsof -P -i -n | cut -f 1 -d " " | uniq'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias realias="$EDITOR ~/.bash_profile; . ~/.bash_profile"
alias ralias='. ~/.bash_profile'
alias pdflatex='pdflatex -halt-on-error'

# utilities
alias c='clear'
alias h='history'

alias vi='vim'

# navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cd..='cd ..'
alias documents='cd ~/Documents'
alias latp='cd ~/Google\ Drive/latex-projects'
alias hons='cd ~/Google\ Drive/Vic/honours'
alias thesis='hons && cd COMP489'

# display
alias l='ls'
alias l.='ls -d .* -G'
alias ls='ls -G'
alias ll='ls -lah'

alias src='source $HOME/.bash_profile'

alias pandoc='pandoc --include-in-header ~/.dotfiles/.pandoc_preamble'

alias path='echo -e ${PATH//:/\\n}'

function mktex {
    pdflatex $1 && bibtex $2 && pdflatex $1 && pdflatex $1
}

function mkpandoc {
    pandoc $1.md -o $1.pdf --include-in-header ~/.dotfiles/.pandoc_preamble
}

# build pandoc slides with metropolis theme
function mtheme {
    pandoc -t beamer -V theme:metropolis -o $2 $1
}

alias powerset='python ~/Documents/scripts/powerset.py'

# system utilities
alias lock='pmset displaysleepnow'

bind Space:magic-space

# Vim style key bindings on the command line
set -o vi

# Configure fzf plugin
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
alias v='vim $(fzf-tmux)'

# Rename the tmux window according to the new directory.
HR_DIRABBREV=~/.dotfiles/bin/dirabbrev

function cd() {
	builtin cd "$@"
	if [ "x$TMUX" != "x" ]; then
		tmux rename-window $($HR_DIRABBREV) >/dev/null 2>&1
	fi
}

# Add an item to $PATH without duplicating it
pathadd() { if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then PATH="${PATH:+"$PATH:"}$1"; fi }

pathadd ~/bin
pathadd /usr/texbin
pathadd /Library/usr/texbin
pathadd /usr/local/texlive/2015/bin/x86_64-darwin
pathadd /Library/Frameworks/Python.framework/Versions/3.6/bin # Python 3.6
pathadd /Users/harryross/anaconda3/bin
pathadd ~/.cabal/bin

function gitignore() { curl http://www.gitignore.io/api/$@ ;}

# tmux
alias tnew='tmux new -s'
alias tattach='tmux attach -t'

# brew completion (don't try without homebrew installed)
# -f tests for regular file, it is a symlink on OS X, so -e
if hash brew 2>/dev/null && [ -e $(brew --prefix)/etc/bash_completion ]; then
	. $(brew --prefix)/etc/bash_completion
fi

# Misc
function pidof {
	# sort to get oldest (lowest pid), the highest pid gets the pid of the grep process
	ps -A | sort | grep -m1 $1 | awk '{print $1}'
}

# brew-cask
export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# ignore case with completion
bind "set completion-ignore-case on"

# promptline (only on OS X with homebrew present)
test -f ~/.dotfiles/.promptline.sh && source ~/.dotfiles/.promptline.sh

if [ "x$TMUX" != "x" ]; then
	tmux rename-window $($HR_DIRABBREV) >/dev/null 2>&1
fi
