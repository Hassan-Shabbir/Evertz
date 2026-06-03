#!/bin/bash

# TODO fix docs/options
# TODO change the default drive prefix to `/drives/n/Downloads` before sending to others
# TODO allow extracting actually correct IPs from input (i.e. remove `https://`, etc.)
# TODO quiet version of the ping should only output when the ping has been missed

#drive_prefix="/drives/n/Downloads"
drive_prefix=/drives/c/Users/hshabbir/Downloads
dir="ping_`date +"%Y-%m-%d"`"
quiet=false
verbose=false

function help_doc () {
read -r -d '' HELPDOC <<- ENDHELPDOC
Usage: $0 [-h] [-d drive] ips
  -h          show this help message
  -d drive    location to save the ping logs
  ips         ips e.g. 10.193.70.34 10.193.70.38 10.193.70.42
ENDHELPDOC

echo "$HELPDOC"	
}

while getopts "?hd:qv" option; do
	case $option in
		h) help_doc; exit ;;
		d) drive_prefix=$OPTARG; echo "Setting drive prefix to: $drive_prefix" ;;
		q) quiet=true; echo "Setting quiet to: $quiet" ;;
		v) verbose=true; echo "Setting verbose to: $verbose" ;;
		?) echo "ERROR: option -$OPTARG is not implemented"; exit ;;
	esac
done

# normalize quiet/verbose
if [[ $quiet == true && $verbose == true ]] ; then
	echo "OVERRIDING verbose to: false"
	verbose=false
fi

# remove the options from the positional parameters
shift $(( OPTIND - 1 ))

if [[ -z "$@" ]]; then
	echo "IPs required; aborting."
	echo ""
	help_doc
	exit
fi

mkdir -p "$drive_prefix/$dir"
echo "Logging (date, ip, state) to: $drive_prefix/$dir/ping.log"
echo "Hosts: $@"


if [[ $quiet == true ]] ; then
	echo ""
	echo "Tailing hosts overview ('#' is unsuccessful ping):"
	echo ""
	while :; do 
		for host in "$@"; do 
			echo "$(date +'%Y-%m-%dT%H:%M:%S') - $(echo $host) - $(ping -n 1 $host | awk -F', ' '/Reply/ {print "UP"} /Request timed out/ {print "DOWN"}')" | tee -a "$drive_prefix/$dir/ping.log" | stdbuf -o0 awk '/DOWN/ {printf "#"}'
		done
	done
fi



if [[ $quiet == false && $verbose == false ]] ; then
	echo ""
	echo "Tailing hosts overview ('_' is successful ping; '#' is unsuccessful ping):"
	echo ""
	while :; do 
		for host in "$@"; do 
			echo "$(date +'%Y-%m-%dT%H:%M:%S') - $(echo $host) - $(ping -n 1 $host | awk -F', ' '/Reply/ {print "UP"} /Request timed out/ {print "DOWN"}')" | tee -a "$drive_prefix/$dir/ping.log" | stdbuf -o0 awk  '/UP/ {printf "_"} /DOWN/ {printf "#"}'
		done
	done
fi



if [[ $verbose == true ]] ; then
	echo ""
	echo "Tailing hosts:"
	echo ""
	while :; do 
		for host in "$@"; do 
			echo "$(date +'%Y-%m-%dT%H:%M:%S') - $(echo $host) - $(ping -n 1 $host | awk -F', ' '/Reply/ {print "UP"} /Request timed out/ {print "DOWN"}')" | tee -a "$drive_prefix/$dir/ping.log"
		done
	done
fi
