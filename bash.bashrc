RED='\[\e[0;31m\]'
GREEN='\[\e[0;32m\]'
CL='\[\e[0m\]'

if [[ $UID -eq 0 ]]; then
	PS1="[${RED}\u${CL}@\h ${RED}\w${CL}]\$ "
else
	PS1="[${GREEN}\u${CL}@\h ${GREEN}\w${CL}]\$ "
fi

export EDITOR=vim
