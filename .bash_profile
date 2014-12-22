# alias ssbg='/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background'
#export PATH=/usr/local/bin:$PATH # /usr/local/bin is already in the PATH
export PATH=~/bin:$PATH
# alias rot13='~/bash/rot13.bash'
# alias manGrowlNotify='man /usr/local/man/man1/growlnotify.1'
alias ..='cd ..'
export EDITOR=/usr/bin/vim
alias tarmake='tar -cpzf'
alias untar='tar -xzf'
alias netusage='lsof -P -i -n | cut -f 1 -d " " | uniq'
alias subl='/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl'
alias realias="$EDITOR ~/.bash_profile; . ~/.bash_profile"
alias ralias='. ~/.bash_profile'
alias mou='open -a Mou'

# Rename the tmux window according to the new directory.
function cd() { builtin cd "$@"; (tmux rename-window $(~/.dotfiles/bin/dirabbrev) >/dev/null 2>&1;) }

if !hash brew 2>/dev/null; then
	alias git='git'
elif hash gh 2>/dev/null; then
	alias git='gh'
elif hash hub 2>/dev/null; then
	alias git='hub'
fi

function gi() { curl http://www.gitignore.io/api/$@ ;}

# iTerm 2 only
# growl() { echo -e $'\e]9;'${1}'\007' ; return  ; }

# Minecraft Server
function mcServer {
	tmux new -s Bukkit "cd ~/Documents/minecraft/publicServer/; java -Xmx2G -Xms1G -jar craftbukkit.jar --log-append true --log-count 5 --log-limit 100000 $*; echo -n 'Exit? '; read -n 1"
}
function mcServerRam {
	tmux new -s Bukkit "cd ~/Documents/minecraft/publicServer/; java -Xmx$1 -Xms$2 -jar craftbukkit.jar --log-append true --log-count 5 --log-limit 100000; echo -n 'Exit? '; read -n 1"
}
alias mcClient='tmux attach -t Bukkit'
function mcRestore {
	BACKUP_VOL=/Volumes/Misc
	BACKUP_DIR=$BACKUP_VOL/rdiffPublicServerBackups
	if [ -d $BACKUP_VOL ]; then
		BUP=$1
		if [ -n $1 ]; then
			echo No backup specified, using latest
			BUP=0B
		fi
		echo External disk mounted, commencing restore
		# ${$1:-0B} is $1, defaulting to '0B' if unset or empty
		rdiff-backup --force -r $BUP $BACKUP_DIR /Users/josh/Documents/minecraft/publicServer
		echo Restore complete\!
	else
		echo External disk not mounted, no backup made
	fi
}

#alias unzipMc='cd ~/Downloads && mkdir mctmp; cd mctmp && jar xf ~/Library/Application\ Support/minecraft/bin/minecraft.jar'
#alias zipMc='cd ~/Downloads/mctmp && rm -r META-INF && jar uf ~/Library/Application\ Support/minecraft/bin/minecraft.jar ./'
alias killMc='killall JavaApplicationStub'
alias forceKillMc='killall -9 JavaApplicationStub'

# NPM
alias pushNpmVersion='git push && git push --tags && npm publish'

# tmux
alias tnew='tmux new -s'
alias tattach='tmux attach -t'

# coding
# alias gitstats='/Users/josh/bash/gitstats/gitstats'
# alias gitstats-zipper='gitstats /Users/josh/Documents/coding/cocoa/Zipper/ /Users/josh/bash/gitstats-output/Zipper && open "file:///Users/josh/bash/gitstats-output/Zipper/index.html"'
# alias gitstats-quizzer='gitstats /Users/josh/Documents/coding/cocoa/Quizzer/ /Users/josh/bash/gitstats-output/Quizzer && open "file:///Users/josh/bash/gitstats-output/Quizzer/index.html"'

# rdiff-backup
# alias backupThumb='echo JOSHO3; rdiff-backup /Volumes/JOSHO3 /Volumes/Misc/thumbdrivebups/rdiff/JOSHO3'

# bup
#export BUP_DIR=/Volumes/Misc/bup
export BUP_DIR=/Volumes/Shared/People/Josh/ThumbDrives/bup
alias backupThumb='echo JOSHO3; bup index /Volumes/JOSHO3 && bup save -n JOSHO3 /Volumes/JOSHO3/'

# brew completion (test command exists for RPi/others)
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

# travis completion
[ -f /Users/josh/.travis/travis.sh ] && source /Users/josh/.travis/travis.sh

# ignore case with completion
bind "set completion-ignore-case on"

# ensure ssh-agent is available
#eval $(ssh-agent)

# promptline
test -f ~/.dotfiles/.promptline.sh && hash brew 2>/dev/null && source ~/.dotfiles/.promptline.sh
