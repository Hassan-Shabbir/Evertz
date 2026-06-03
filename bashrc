# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
#if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
#    . /etc/bash_completion
#fi

export PATH="~/j9.4:$HOME/.emacs.d/bin:$PATH"

function ,odlink () {
  source ~/.bashrc
  var="$(curl -u hshabbir@evertz.com: "https://evertz.atlassian.net/rest/api/3/issue/$1?expand=renderedFields" | jq '{key: .key, summary: .fields.summary}')"
  key=$(echo $var | jq -r '.key')
  summary=$(echo $var | jq -r '.summary' | gawk -v OFS=' ' '{for (i=3; i<=NF; i++) print $i}')
  dir=$(echo $key - $summary)

  echo ""
  echo "Creating the folder named if it does not exist: \"$dir\""
  rmkdir "$(echo od:/$dir)"
  echo ""
  if [ $# -eq 2 ]; then 
    echo "Uploading \"$2\" to the drive." 
    rcp $2 "$(echo od:/$dir)"
  else 
    echo "Did not upload a file/directory to the drive." 
  fi
}

function ,filesdash () {
    for file in *; do rename 's/[^a-zA-Z0-9._-]/-/g' "$file"; done
}

function ,fileslower () {
    for file in *; do rename 's/[^a-zA-Z0-9._-]/-/g' "$file"; done
}

function ,img () {
    echo 'starting to rename images in ~/notes/'
    cd /root/notes/
    for file in *; do rename 's/[^a-zA-Z0-9._-]/-/g' "$file"; done
    for file in *; do rename 'y/A-Z/a-z/' "$file"; done
    for file in *; do rename 's/[_-]+/-/g' "$file"; done
    echo 'done; going back to original dir'
    cd -
}

function ,up () { 
	if [[ $# = 0 ]]; then
		cd ..
	fi
	x=$1
	while [[ $x > 0 ]]; do
		cd ..
		x=$(($x-1))
	done
}

function ,unique () {
	while getopts ":h" var; do
	    case $var in
		h) # display Help
		    echo "First occurrence of unique lines, ignoring numbers and matching the provided pattern."
		    echo
		    echo "unique [pattern] [input-file] [output-file]"
		    echo "example: unique '//' zeus.log zeus-uniq";;
	    esac
	done
	gawk "BEGIN{IGNORECASE=1; print \"Summary (first occurrence of match ignoring numbers):\"} $1 {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,\"\",a); print \$0, \"###\", a}" "$2" | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > "$3"
}

function ,count () {
	while getopts ":h" var; do
	    case $var in
		h) # display Help
		    echo "Count of similar lines, ignoring numbers and matching the provided pattern."
		    echo
		    echo "count [pattern] [input-file] [output-file]"
		    echo "example: count '//' zeus.log zeus-count";;
	    esac
	done
	gawk "BEGIN{IGNORECASE=1; print \"Summary (first occurrence of match ignoring numbers):\"} $1 {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,\"\",a); print a}" "$2" | sort | uniq -c | sort -nrk 1 > "$3"
}

function ,uniques () {
	while getopts ":h" var; do
	    case $var in
		h) # display Help
		    echo "First occurrence of unique lines, ignoring numbers and matching the provided pattern."
		    echo
		    echo "unique [pattern] [input-file] [output-file]"
		    echo "example: uniques '//'";;
	    esac
	done
	for file in $(ls *log*); do
		gawk "BEGIN{IGNORECASE=1; print \"Summary (first occurrence of match ignoring numbers):\"} $1 {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,\"\",a); print \$0, \"###\", a}" "$file" | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > "$file-uniq"
	done
}

function ,tempo () {
	# NOTE: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	# Tempo ID: https://evertz.atlassian.net/rest/api/3/myself
	# Tempo Automation Bearer Token (regenerate every year):
	# Only run the commands when the new month has started (or change to ~cal -m nov 2023~ and the startDate value/expression)
	# NOTE: this will be the first time the startDate will be using expressions to generate the month and year


	# Testing: Grab worklogs
	#curl -H "Content-Type: application/json" -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs/user/6340172374831bfcb85274f7" | jq '.results[] | {ticket: .self, startDate, startTime, account: .attributes.values[0].value}'

	
	# Testing: single break in morning
	#curl -X POST -H 'Content-Type: application/json' -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": '380788', "startDate": "2024-08-01", "startTime": "9:00:00", "timeSpentSeconds": "900"}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs" | jq


	# Monday Evertz Internal - General tasks from 9:15am for 15min
	for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330494, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "09:15:00", "timeSpentSeconds": 900}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Tues-Fri Evertz Internal - General tasks from 9:15am for 45min
	for i in $(cal | cut -c 7-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330494, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "09:15:00", "timeSpentSeconds": 2700}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Monday BAM EvTOC Weekly Sync (Internal) - from 9:30am for 30min
	for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "BAM"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330494, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "09:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Monday WBD - Evertz VUE/Reflex Touch Base - Admin Meetings at 10:00am for 30min
	for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "10:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Wednesday Internal follow-up meeting with Mark at 10:00am for 30min
	for i in $(cal | cut -c 10-11 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "10:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Mon-Thur WBD Planning Session - Evertz Internal - Admin Meetings at 10:30am for 30min
	for i in $(cal | cut -c 4-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "10:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Monday UND Weekly Standup - Evertz Internal - Admin Meetings at 11:00am for 30min
	for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "UND"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "11:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Thursday Discuss VUE tasks across WBD at 11:00am for 30min
	for i in $(cal | cut -c 13-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "11:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# NOTE: THIS HAS BEEN CANCELLED: Friday evTOC Review Session with Mark at 11:00am for 30min
	#for i in $(cal | cut -c 16-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "11:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Friday Warner Ticket Review at 11:30am for 30min
	for i in $(cal | cut -c 16-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "11:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Wednesday WFS-CNN evTOC Ticket Review at 12:00pm for 30min
	for i in $(cal | cut -c 10-11 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "12:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# TIME CHANGE 3/13: Friday Prayers Jumuah Evertz Internal - Break and Vacation at 1:30pm for 30min (technically for 1h30min; until 3:00pm); and then return back to work
	for i in $(cal | cut -c 16-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 380788, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "13:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq
	for i in $(cal | cut -c 16-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330494, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "15:00:00", "timeSpentSeconds": 900}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Monday BAM PaaS project team sync at 1:00pm for 30min
	for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "BAM"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "13:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# *Bi-Weekly* Thursday WBD-Evertz and GBI Roundtable at 1:00pm for 45min
	for i in $(cal | cut -c 13-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "13:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# *Bi-Weekly* Thursday Notre Dame meeting at 1:30pm for 30min; NOTE: This is set for every week, not bi-weekly
	for i in $(cal | cut -c 13-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "UND"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "13:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# *Bi-Weekly* Monday HBO HY Ticket Review at 2:00pm for 30min
	for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "14:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# REMOVED! Tuesday BAM/Evertz Sync up at 2:00pm for 30min (technically, it is for 1 hour)
	#for i in $(cal | cut -c 7-8 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "BAM"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "14:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Thursday 230PAS/CNN HY at 2:00pm for 45min
	for i in $(cal | cut -c 13-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "14:00:00", "timeSpentSeconds": 2700}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Tuesday Evertz Weekly Meeting (Live Production) at 2:30pm for 30min
	for i in $(cal | cut -c 7-8 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "14:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# *Bi-Weekly* Tuesday GBE evTOC ticket discussion at 3:30pm for 30min
	for i in $(cal | cut -c 7-8 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "15:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Wednesday Studios Magnum Arch - Orchestration/VUE at 4:00pm for 60min
	for i in $(cal | cut -c 10-11 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "WMG"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "16:00:00", "timeSpentSeconds": 3600}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq

	# Mon-Thur Evertz Internal - Break and Vacation at 7:00pm for 30min
	for i in $(cal | cut -c 4-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 380788, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "19:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer " "https://api.tempo.io/4/worklogs"; done | jq


	# Weekdays
	# Mon	Tues	Wed	Thurs	Fri
	# 4-5	7-8	10-11	13-14	16-17

	# TODO:
	echo "################################################################################"
	echo "COMPLETE!!! Tempo times have been filled out"
	echo "WARNING: JSON results should have shown up every few seconds (if not, update API token)"
	echo "WARNING: Delete to Bi-Weekly: Thursday WBD-Evertz and GBI Roundtable at 1:00pm for 45min"
	echo "WARNING: Delete to Bi-Weekly: Thursday Notre Dame meeting at 1:30pm for 30min"
	echo "WARNING: Delete to Bi-Weekly: Monday HBO HY Ticket Review at 2:00pm for 30min"
	echo "WARNING: Delete to Bi-Weekly: Tuesday GBE evTOC ticket discussion at 3:30pm for 30min"
}



#function tempo () {
	## NOTE: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	## Tempo Automation Bearer Token (regenerate every year?): 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us
	## Only run the commnads when the new month has started (or change to ~cal -m nov 2023~ and the startDate value/expression)
	## NOTE: this will be the first time the startDate will be using expressions to generate the month and year
#
	## Testing: Grab worklogs
	## curl -H "Content-Type: application/json" -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs/user/6340172374831bfcb85274f7" | jq '.results[] | {ticket: .self, startDate, startTime, account: .attributes.values[0].value}'
#
	#function helper() {
		#echo for i in $(cal | cut -c $1 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H 'Content-Type: application/json' -d '{"attributes": [{"key": "_Account_", "value": "'$2'"}], "authorAccountId": "'$3'", "issueId": '$4', "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "'$5':00", "timeSpentSeconds": '$6'}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
	#}
#
	## Daily Evertz Internal - Break and Vacation at 9:00am for 15min
	##helper days  group      authorAccountId            issueID    time24h duration 
	#helper "4-17" "Internal" "6340172374831bfcb85274f7"  "380788" "09:00" "900"
	#for i in $(cal | cut -c 4-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 380788, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "09:00:00", "timeSpentSeconds": 900}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Daily Evertz Internal - General tasks from 9:15am for 45min
	#for i in $(cal | cut -c 4-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330494, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "09:15:00", "timeSpentSeconds": 2700}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Monday Planning Session with Mark at 10:00am for 30min
	#for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "10:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Wednesday Internal follow-up meeting with Mark at 10:00am
	#for i in $(cal | cut -c 10-11 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "10:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Monday Internal Sync Up with Vishal at 10:30am for 30min
	#for i in $(cal | cut -c 4-5 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "10:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Weekly Notre Dame Bi-Weekly meeting on Thursday at 2:00pm for 30min; NOTE: This is set for every week, not bi-weekly
	#for i in $(cal | cut -c 13-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "UND"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 330493, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "14:00:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Monday to Thursday Evertz Internal - Break and Vacation at 2:30pm for 30min
	#for i in $(cal | cut -c 4-14 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 380788, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "14:30:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Friday Prayers Evertz Internal - Break and Vacation at 3:15pm for 30min
	#for i in $(cal | cut -c 15-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 380788, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "15:15:00", "timeSpentSeconds": 1800}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	## Daily Evertz Internal - Break and Vacation at 5:15pm for 15min
	#for i in $(cal | cut -c 4-17 | tail -n +3 | tr ' ' '\n' | sed -e 's/^\([1-9]\)$/0\1/g'); do curl -X POST -H "Content-Type: application/json" -d '{"attributes": [{"key": "_Account_", "value": "Internal"}], "authorAccountId": "6340172374831bfcb85274f7", "issueId": 380788, "startDate": "'"$(date +'%Y')"'-'"$(date +'%m')"'-'"$i"'", "startTime": "17:15:00", "timeSpentSeconds": 900}' -H "Authorization: Bearer 6kNYlDYqObnOwllVJuJX3u32KCPIFA-us" "https://api.tempo.io/4/worklogs"; done | jq
#
	#
	#echo "################################################################################"
	#echo "COMPLETE!!! Tempo times have been filled out"
	#echo "WARNING: JSON results should have shown up every few seconds (if not, update API token)"
	#echo "WARNING: Delete UND meetings so that they are Bi-Weekly"
#}
#

function ,save () {
	echo "saving:"
	fc -ln -1 | sed '1s/^[[:space:]]*//' | sed 's/^/\#/' | sed 's/$/ \#save\#/' | tee -a ~/.bashrc
}


# Unzip and combine all files for a Magnum service into one file (chronological)
# Syntax:
#     combine [magnum-service]
# Example:
#     combine reflex
function ,combine () {
    ls | gawk "/$1\./ && /\.gz/" | xargs gzip -dk
    ls | gawk '/'"$1"'\.log.+/ && !/\.gz/' | xargs -I{} cat {} "$1".log > "$1"
}

function ,combine-vue-syslog () {
    ls | gawk "/syslog\./ && /\.gz/" | xargs gzip -dk
    mv syslog syslog.0
    cat syslog.{20..0} > syslog-full

    # to show restarts
    #gawk '/Start|Stop|Load|Reached|Shut|Power|System|stack trace/ && !/Journal Syslog|magselfmonsrv|NTP/' syslog-full
    # stack traces
    #gawk '/end of stack trace/' syslog-full
    # health
    #gawk '/magselfmonsrv/' syslog-full
    # audio
    #gawk '/Sound|pulseaudio/' syslog-full > syslog-full-audio


    #ls | gawk "/top\./ && /\.gz/" | xargs gzip -dk
    #mv top.log top.log.0
    #cat top.log.{20..0} > top-full

}

function ,combine-vue () {
    ls | gawk "/$1\./ && /\.gz/" | xargs gzip -dk
    mv $1 $1.0
    cat $1.{20..0} > $1-full
}

function ,combine-all () {
    for file in $(ls *.gz | gawk -F '.' '{print $1}' | uniq); do ,combine $file; done
    cd magselfmonsrv
    for file in $(ls *.gz | gawk -F '.' '{print $1}' | uniq); do ,combine $file; done
    cd ..
}


function ,toc () {
	# NUSHELL VERSION:
	#~>def toc [tickets:list<string>] { $tickets | each {|r| str upcase} | each {|r| print -n $"($r): "; http get -H ["Authorization" "Basic " "Content-Type" "application/json"] $"https://evertz.atlassian.net/rest/api/3/issue/($r)/properties/k15t.backbone.syncinfo" | get value.remoteIssueKey.0 } | to text }
	#~> toc [ wbd-790 wbd-1236 ]

	input=${1^^} # uppercase
	if [[ "$input" =~ "-" ]]; then # have jira project already
		ticket="${input}"
	else
		ticket="WBD-${input}"
	fi

	echo curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}/properties/k15t.backbone.syncinfo" 
	printf "Error: "
	curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}/properties/k15t.backbone.syncinfo" | jq '.errorMessages[0]' # error message
	curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}/properties/k15t.backbone.syncinfo" | jq '.value.remoteIssueKey[0]' | grep -o 'TOC-[0-9]\{5\}'
	echo 'Copied ticket to clipboard!'
	curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}/properties/k15t.backbone.syncinfo" | jq '.value.remoteIssueKey[0]' | grep -o 'TOC-[0-9]\{5\}' | clip.exe
}


function ,untoc () {
	input=${1^^} # uppercase
	if [[ "$input" =~ "TOC-" ]]; then # have jira project already
		ticket="${input}"
	else
		ticket="TOC-${input}"
	fi

	curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}" | jq '.fields.customfield_11700' | sed 's/"//g'

	curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}" | jq '.fields.summary' | sed 's/"//g'

	# TODO: gets overwritten by the ticket, and does not show up in `WIN-v`
	# echo 'Copied summary to clipboard!'
	# curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}" | jq '.fields.summary' | sed 's/"//g' | clip.exe

	echo 'Copied ticket to clipboard!'
	curl -s -X GET -H "Authorization: Basic " -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/${ticket}" | jq '.fields.customfield_11700' | sed 's/"//g' | clip.exe
}

# Aliases
alias python='python3'
alias ,hshabbir='cd "/mnt/c/Users/hshabbir/OneDrive - Evertz Micro Systems"'
alias ,desktop='cd "/mnt/c/Users/hshabbir/OneDrive - Evertz Micro Systems/Desktop"'
alias ,dt='cd "/mnt/c/Users/hshabbir/OneDrive - Evertz Micro Systems/Desktop"'
alias ,dk='cd "/mnt/c/Users/hshabbir/OneDrive - Evertz Micro Systems/Desktop"'
alias ,downloads='cd /mnt/c/Users/hshabbir/Downloads'
alias ,dl='cd /mnt/c/Users/hshabbir/Downloads'
alias ,tickets='cd /mnt/c/Users/hshabbir/Downloads/T'
alias ,t='cd /mnt/c/Users/hshabbir/Downloads/T'
alias ,videos='cd /mnt/c/Users/hshabbir/Videos'
alias ,v='cd /mnt/c/Users/hshabbir/Videos'
alias ,nushell="~/nu/nu-0.97.1-x86_64-unknown-linux-gnu/nu"
alias ,nu="~/nu/nu-0.97.1-x86_64-unknown-linux-gnu/nu"
alias ,lsh="ls -t | head"

alias ,magclust=""
alias ,insite=""

alias ,dhanya=""

#alias r='rclone'
#alias rcfg='rclone config'
#alias rcp='rclone copy -P'
#alias rsync='rclone sync'
#alias rmv='rclone move'
#alias rdel='rclone delete'
#alias rmkdir='rclone mkdir'
#alias rcheck='rclone check'
#alias rls='rclone ls'
#alias rl='rclone link --expire 1y'

alias ,d='emacsclient -t -a ""'
alias ,dr='doom run'
alias ,sortdate='sort -k1M -k2n -k3 -s'
alias ,uz='ls OneDrive_*.zip | sort -r | head -n 1 | xargs unzip; cd "$(ls -t | head -n 1)"'
alias feh='feh -F'
#alias j='cd "$(cat ~/wd)"'
#alias js='echo "$(pwd)" > ~/wd'
alias ,beep='powershell.exe "[console]::beep(1000,1000)"'

# Rogers' Magnum ATP/SDVN setup
#alias nat=''
#alias magnumlinux=''
#alias magnumlinux2=''
#alias magnumsdvn=""
#alias insite=''



HISTSIZE=-1
HISTFILESIZE=-1

export PATH=/root/bin:$PATH


function path_len () {
	max_path=80
	currentPath=$(pwd)
	pathLen=${#currentPath}
	[ ${pathLen} -gt ${max_path} ] && printf "\n:"
}

#export PS1="\n\[\033[1;31m\][\$(cat /root/msg_ip)\w]\[\033[32m\]\$(path_len)\$ "
export PS1="\n\[\033[1;31m\][\$()\w]\[\033[32m\]\$(path_len)\$ "


#eval "$(zoxide init bash --cmd j --hook prompt)"
function _z_cd() {
    cd "$@" || return "$?"
    if [ "$_ZO_ECHO" = "1" ]; then
        echo "$PWD"
    fi
}

function j () {
    if [ "$#" -eq 0 ]; then
        _z_cd ~
    elif [ "$#" -eq 1 ] && [ "$1" = '-' ]; then
        if [ -n "$OLDPWD" ]; then
            _z_cd "$OLDPWD"
        else
            echo 'zoxide: $OLDPWD is not set'
            return 1
        fi
    else
        _zoxide_result="$(zoxide query -- "$@")" && _z_cd "$_zoxide_result"
    fi
}

function ji() {
    _zoxide_result="$(zoxide query -i -- "$@")" && _z_cd "$_zoxide_result"
}


alias ja='zoxide add'
#alias jq='zoxide query'
#alias jqi='zoxide query -i'

alias jr='zoxide remove'
function jri() {
    _zoxide_result="$(zoxide query -i -- "$@")" && zoxide remove "$_zoxide_result"
}

function _zoxide_hook() {
    zoxide add "$(pwd -L)"
}

case "$PROMPT_COMMAND" in
    *_zoxide_hook*) ;;
    *) PROMPT_COMMAND="_zoxide_hook${PROMPT_COMMAND:+;${PROMPT_COMMAND}}" ;;
esac

alias func='declare -F | grep -v _'	


function displaytime () {
	local T=$1
	local D=$((T/60/60/24))
	local H=$((T/60/60%24))
	local M=$((T/60%60))
	local S=$((T%60))
	(( $D > 0 )) && printf '%d days ' $D
	(( $H > 0 )) && printf '%d hours ' $H
	(( $M > 0 )) && printf '%d minutes ' $M
	(( $D > 0 || $H > 0 || $M > 0 )) && printf 'and '
	printf '%d seconds\n' $S
}


function ,range () { 
	for file in "$@"; do
		echo "==> $file <=="
		log_start=$(head -n1 $file | gawk '{print $1}')
		echo $log_start
		log_end=$(  tail -n1 $file | gawk '{print $1}')
		echo $log_end
		log_range=$(( $(date -d $log_end '+%s') - $(date -d $log_start '+%s') ))
		displaytime $log_range
	done
}





# ALIAS HELPERS
alias odlink=',odlink'
alias filesdash=',filesdash'
alias fileslower=',fileslower'
alias img=',img'
alias up=',up'
alias unique=',unique'
alias count=',count'
alias uniques=',uniques'
alias tempo=',tempo'
alias save=',save'
alias combine=',combine'
alias combine-all=',combine-all'
alias toc=',toc'
alias untoc=',untoc'
alias hshabbir=',hshabbir'
alias desktop=',desktop'
alias dt=',dt'
alias dk=',dk'
alias downloads=',downloads'
alias dl=',dl'
alias tickets=',tickets'
alias t=',t'
alias videos=',videos'
alias v=',v'
alias nushell=',nushell'
alias nu=',nu'
alias lsh=',lsh'
alias d=',d'
alias dr=',dr'
alias sortdate=',sortdate'
alias uz=',uz'
alias beep=',beep'
alias reflexbrandon=',reflexbrandon'
alias reflexzaki=',reflexzaki'
alias reflexpersonal=',reflexpersonal'
alias pa=',pa'
alias ip=',ip'
alias vim='nvim'
alias pp=",pp"
alias range=",range"

# GO TO DOWNLOADS!
#dl
# GO TO Tickets!
,t

function ,vue-extract-opt-med-smll-time () { 
	while getopts ":h" var; do
	    case $var in
		h) # display Help
		    echo "First arg is going to be the file"
		    echo "Followed by the optional medium time range (eg., hour-level)"
		    echo "Followed by the optional small time range (eg., minute-level)"
		    echo
		    echo ",vue-extract-vue-opt-med-smll-time [input-file] [medium-time] [small-time]"
		    echo "example: ,vue-extract-vue-opt-med-smll-time LPVUE10_logs_2025-07-14_22-09.zip '^2025-06-30T1[012]' '^2025-06-30T11:15'";;
	    esac
	done

	echo "TODO: memory usage of vueweb-graphql process in top"

	start=$(date '+%s')
	if [[ $1 == *.zip ]]; then
		echo "extracting .zip file $(date)"
		unzip $1
	fi
	echo "extracting .tgz file $(date)"
	tar xzvf ${1%.*}.tgz
	echo "cd into log dir $(date)"
	cd ${1%.*}/var/log
	echo "make work dir"
	mkdir work


	if [ -f vue.log ]; then
		echo "vue.log file found"
		echo "generate vue-full $(date)"
		zgrep -ih "" vue.*gz vue.log | sort -nk1 > work/vue-full
	fi


	if [ ! -f vue.log ]; then
		echo "rename syslog to syslog.0"
		mv syslog syslog.0
		echo "vue.log file not found; using syslog"
		echo "generate vue-full from syslog $(date)"
		zgrep -ih "" syslog*gz syslog.1 syslog.0 | sort -nk1 > work/vue-full
	fi

	echo "generate nginx-access-full $(date)"
	zgrep -ih "" nginx/access.log.{14..2}.gz nginx/access.log.1 nginx/access.log | sort -nk1 > work/nginx-access-full

	echo "cd into work/"
	cd work

	#echo "generate vue-full-simple $(date)"
	#grep -ihv 'com\.evertz\.magnum\.devnetdisco\.v1\.0\.discoveries\.advertise"\|com\.evertz\.magnum\.reflex\.v1\..*\.ping"\|wamp\.registration\.lookup\|QVariant conversion time:\|Received ping\.\|contexts\.magclientsrv\.magselfmonsrv\|parse time:\|received {"jsonrpc":"2\.0","id":1,"result":"pong"}\|send {"id":1,"jsonrpc":"2\.0", "method":"ping","params":{}}\|wamp\.client\.deferred\|watchdog: frame rate\|Implicitly defined onFoo properties in Connections are deprecated\|get\.token\.validity\|"expires":"2025\|This behavior is deprecated\|You have to import QtQml\|the restoreMode of the binding\|In Qt\|restoreMode has not been set\|Cannot read property .* of undefined' vue-full > vue-full-simple
	echo "generate vue-full-restart $(date)"
	grep -ih "Starting VUE\|Ctrl+Alt+R restart requested" vue-full > vue-full-restart
	echo "generate vue-full-keyer $(date)"
	grep -ih "keyer\(In\|Out\|On\|Off\)  keyerName\|Clear ALL\|Cueing template_id\|No file extension found for file\|sending command.*loadTemplate\|keyer()" vue-full > vue-full-keyer
	echo "generate vue-full-buttons $(date)"
	grep -ih "MUIWidgetButtons:" vue-full > vue-full-buttons
	echo "generate vue-full-gui-froze $(date)"
	grep -ih "GUI froze" vue-full > vue-full-gui-froze
	#echo "generate vue-full-gui-froze-long $(date)"
	#grep -ih "" vue-full-gui-froze > vue-full-gui-froze-long

	echo "generate top-full $(date)"
	#zgrep -ih "" top.*gz top.log | sort -nk1 > top-full
	zgrep -ih "" ../top.log.{20..1}.gz ../top.log > top-full # cannot sort the normal way due to the date being in the wrong format; file in parent
	echo "generate top-full-load $(date)"
	grep -ih 'top - ' top-full > top-full-load
	echo "generate top-full-mem $(date)"
	grep -ih 'MiB Mem' top-full > top-full-mem
	echo "generate top-medium-mem-free-graph $(date)"
	(gawk '{print $9}' top-full-mem | tr '\n' ' '; echo) | sed "s/^/'title Memory Free (Full Range) (MiB); xcaption Time (15 min); ycaption Memory (MiB)' plot /" | sed "s/plot/plot $(tail -n 1 top-full-mem | gawk '{print $7}') , 0 ,:/" > top-full-mem-free-graph
	echo "generate top-medium-mem-used-graph $(date)"
	(gawk '{print $11}' top-full-mem | tr '\n' ' '; echo) | sed "s/^/'title Memory Used (Full Range) (MiB); xcaption Time (15 min); ycaption Memory (MiB)' plot /" | sed "s/plot/plot $(tail -n 1 top-full-mem | gawk '{print $7}') , 0 ,:/" > top-full-mem-used-graph
	echo "generate top-full-vue $(date)"
	grep -ih '\/opt\/vue\/vue ' top-full > top-full-vue

	echo "generate kern-full-out-of-memory $(date)"
	grep -ih 'Out of memory' ../kern.log* | sort > kern-full-out-of-memory

	echo "generate nginx-access-full-refresh-token $(date)"
	grep -ih 'GET /refresh_token' nginx-access-full > nginx-access-full-refresh-token

	echo "generate overview-full $(date)" # removed top-full-mem
	cat vue-full-restart vue-full-keyer vue-full-buttons vue-full-gui-froze top-full-load kern-full-out-of-memory | sort -nk1 > overview-full

	if [ ! -z "$2" ]; then
		#cat vue-medium-* | sort -nk1 | uniq -c | sed 's/^\s*//' > vue-medium-overview

		#echo "generate vue-medium-simple $(date)"
		#grep "$2" vue-full-simple > vue-medium-simple
		echo "generate vue-medium $(date)"
		grep "$2" vue-full > vue-medium
		echo "generate vue-medium-restart $(date)"
		grep "$2" vue-full-restart > vue-medium-restart
		echo "generate vue-medium-keyer $(date)"
		grep "$2" vue-full-keyer > vue-medium-keyer
		echo "generate vue-medium-buttons $(date)"
		grep "$2" vue-full-buttons > vue-medium-buttons
		echo "generate vue-medium-gui-froze $(date)"
		grep "$2" vue-full-gui-froze > vue-medium-gui-froze

		echo "generate top-medium $(date)"
		grep "$2" top-full > top-medium
		echo "generate top-medium-load $(date)"
		grep "$2" top-full-load > top-medium-load
		echo "generate top-medium-mem $(date)"
		grep "$2" top-full-mem > top-medium-mem
		echo "generate top-medium-mem-free-graph $(date)"
		(grep "$2" top-full-mem | gawk '{print $9}' | tr '\n' ' '; echo) | sed "s/^/'title Memory Free (Medium Range) (MiB); xcaption Time (15 min); ycaption Memory (MiB)' plot /" | sed "s/plot/plot $(tail -n 1 top-full-mem | gawk '{print $7}') , 0 ,:/" > top-medium-mem-free-graph
		echo "generate top-medium-mem-used-graph $(date)"
		(grep "$2" top-full-mem | gawk '{print $11}' | tr '\n' ' '; echo) | sed "s/^/'title Memory Used (Medium Range) (MiB); xcaption Time (15 min); ycaption Memory (MiB)' plot /" | sed "s/plot/plot $(tail -n 1 top-full-mem | gawk '{print $7}') , 0 ,:/" > top-medium-mem-used-graph
		echo "generate top-medium-vue $(date)"
		grep "$2" top-full | grep -ih '\/opt\/vue\/vue ' > top-medium-vue

		echo "generate kern-medium-out-of-memory"
		grep "$2" kern-full-out-of-memory > kern-medium-out-of-memory

		# TODO: doesn't work due to date formatting issue
		#echo "generate nginx-access-medium-refresh-token $(date)"
		#grep "$2" nginx-access-full-refresh-token > nginx-access-medium-refresh-token

		echo "generate overview-medium $(date)"
		cat vue-medium-restart vue-medium-keyer vue-medium-buttons vue-medium-gui-froze top-medium-load top-medium-mem kern-medium-out-of-memory | sort -nk1 > overview-medium
	fi

	if [ ! -z "$3" ]; then
		#echo "generate vue-small-simple $(date)"
		#grep "$3" vue-medium-simple > vue-small-simple
		echo "generate vue-small $(date)"
		grep "$3" vue-medium > vue-small
		echo "generate vue-small-restart $(date)"
		grep "$3" vue-medium-restart > vue-small-restart
		echo "generate vue-small-keyer $(date)"
		grep "$3" vue-medium-keyer > vue-small-keyer
		echo "generate vue-small-buttons $(date)"
		grep "$3" vue-medium-buttons > vue-small-buttons
		echo "generate vue-small-gui-froze $(date)"
		grep "$3" vue-medium-gui-froze > vue-small-gui-froze

		echo "generate kern-small-out-of-memory"
		grep "$3" kern-medium-out-of-memory > kern-small-out-of-memory

		# TODO: doesn't work due to date formatting issue
		#echo "generate nginx-access-small-refresh-token $(date)"
		#grep "$3" nginx-access-medium-refresh-token > nginx-access-small-refresh-token

		echo "generate overview-vue-small $(date)"
		cat vue-small-restart vue-small-keyer vue-small-buttons vue-small-gui-froze kern-small-out-of-memory | sort -nk1 > overview-small
	fi


	echo $start
	end=$(date '+%s')
	echo $end
	duration=$(( $end - $start ))
	displaytime $duration

	echo "NOTE: If the command failed to extract the file, rerun the same command on the .tgz file directly, as the customer renamed the zip file"
	echo "COMPLETE!!! $(date)"
}


function ,vue-upgrade-update-progress-summaries () {
  # TEST: 
  #for ticket in TOC-38009; do curl -X POST -u hshabbir@evertz.com:PfX7lCvTutz8guDvuKp44F27 -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/$ticket/comment" -d "{ \"body\": \"$1\" }"; done
  
  # removed WBD-2086 from the list, as the ticket was closed
  for ticket in WBD-1563 WBD-1632 WBD-1726 WBD-1899; do echo "UPDATING $ticket"; done

  echo "Waiting 10s to confirm comment and tickets are correct (ctrl-c to exit)...."
  sleep 10s

  for ticket in WBD-1563 WBD-1632 WBD-1726 WBD-1899; do echo "-----------------------"; echo "Updating ${ticket} with comment $1"; curl -X POST -u hshabbir@evertz.com:PfX7lCvTutz8guDvuKp44F27 -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/$ticket/comment" -d "{ \"body\": \"$1\" }"; echo ""; echo "Updated $ticket"; done

  for ticket in WBD-1563 WBD-1632 WBD-1726 WBD-1899; do echo "FINISHED updating $ticket"; done
}




### SAVE ###
#source ~/.bashrc #save#
#for file in $(ls *.gz | gawk -F '.' '{print $1}' | uniq); do combine $file; done #save#
#cat device-status.json | sed "s/'/\"/g" | sed "s/True/true/g" | sed "s/False/false/g" | jq '.[] | select(.ready == false)' #save#
#/opt/magnum-support-tools/bin/jsonrpc_cli -p 12013 "device.status()" | tail -n +2 | sed "s/'/\"/g" | sed "s/True/true/g" | sed "s/False/false/g" | jq '.[] | select(.ready == true)' #save#
#tail -f ---disable-inotify vue.log #save#

#ls | where name =~ 'db' | get name | each {|r| open $r | get documents | where name == 'reflex' | last | get content | from yaml } | to text | grep '^\s*Main VLAN' #save# # FOR NUSHELL ONLY!!!!
#j -m | where progress_sumary_1 == null or progress_summary_2 == null | select ticket severity assignee progress_summary_1 progress_summary_2 status summary | to csv | save missing-progress-summaries.csvm #save# # FOR NUSHELL ONLY!!!!
#cat debug*.log.* debug*.log > debug; cat error*.log.* error*.log > error; cat info*.log.* info*.log > info; cat warning*.log.* warning*.log > warning #save#
#gawk '/14:39:../ || /14:40:../' debug error info warning > small #save#
#tail -n0 -F /var/log/*log #save#
#cat syslog.{20..1} syslog > syslog-full #save#

##for ticket in WBD-1563 WBD-1632 WBD-1726 WBD-1899 WBD-2086; do echo curl -X POST -u hshabbir@evertz.com:PfX7lCvTutz8guDvuKp44F27 -H "Content-Type: application/json" "https://evertz.atlassian.net/rest/api/2/issue/$ticket/comment" -d '{ "body": "TEST" }'; done #save#
#tail -f ---disable-inotify /mnt/c/Users/hshabbir/AppData/Local/data/vue/Evertz/VUE/logs/vue.log  #save#


alias ,vue-short-logs-sw-replication='tail -f ---disable-inotify /mnt/c/Users/hshabbir/AppData/Local/data/vue/Evertz/VUE/logs/vue.log | grep -v '"'"'com\.evertz\.magnum\.devnetdisco\.v1\.0\.discoveries\.advertise"\|com\.evertz\.magnum\.reflex\.v1\..*\.ping"\|wamp\.registration\.lookup\|QVariant conversion time:\|Received ping\.\|contexts\.magclientsrv\.magselfmonsrv\|parse time:\|received {"jsonrpc":"2\.0","id":1,"result":"pong"}\|send {"id":1,"jsonrpc":"2\.0", "method":"ping","params":{}}\|wamp\.client\.deferred\|watchdog: frame rate\|Implicitly defined onFoo properties in Connections are deprecated\|get\.token\.validity\|"expires":"2025\|This behavior is deprecated\|You have to import QtQml\|the restoreMode of the binding\|In Qt\|restoreMode has not been set\|Cannot read property .* of undefined'"'"
