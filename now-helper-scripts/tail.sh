#!/usr/bin/env bash

# NOTE: requires at least 2 servers to not stop tailing the logs if one is rebooted
# NOTE: color will change for device after reboot
# TODO add variables for everything
# TODO change the drive_prefix value
# TODO show what files have matched
# TODO need to add in the ability to run command based on magnum cluster name
# TODO add the loggrab feature from my WBD Scripts!!! section (i.e. download all of the relevant logs)
# TODO ignore the .gz files when tailing so that *foo*.log is not needed


# ssh targets and log search pattern
user="etservice" # remote ssh user
password="magnumhdtv" # remote ssh password
search_pattern=""
#drive_prefix="/drives/n/Downloads"
drive_prefix=/drives/c/Users/hshabbir/Downloads
logfiles_prefix=/var/log
dir="tail_`date +"%Y-%m-%d"`"

# TODO
function help_doc () {
read -r -d '' HELPDOC <<- ENDHELPDOC
Usage: $0 [-h] [-u username] [-p password] 
  -h                   show this help message
  -u username          username to use to ssh 
                           DEFAULT: etservice
  -p password          password to use to ssh
                           DEFAULT: magnumhdtv
  -i ips               ips of hosts to tail
                           WARNING: in non-spaced csv format
                           e.g. 10.193.70.34,10.193.70.38,10.193.70.42
  -l logfiles          logfiles to tail
                           WARNING: in non-spaced csv format
		           e.g. reflex,magclientsrv
                           NOTE: pre and post globbed, i.e. *mdl*.log
  -L logfile_dir       logfile directory
                           DEFAULT: /var/log
  -s search_pattern    search pattern in case-insensitive extended grep Regex format
                           DEFAULT: ""
ENDHELPDOC

echo "$HELPDOC"	
}

while getopts "?hu:p:i:l:L:s:" option; do
	case $option in
		h) help_doc; exit ;;
		u) user="$OPTARG"; echo "Setting username to: $user" ;;
		p) password="$OPTARG"; echo "Setting password to: $password" ;;
		i) hosts_str="$OPTARG"; echo "Setting ips to: $hosts_str" ;;
		l) logfiles_str="$OPTARG"; echo "Setting logfiles to: $logfiles_str" ;;
		L) logfiles_prefix="$OPTARG"; echo "Setting logfiles prefix to: $logfiles_prefix" ;;
		s) search_pattern="$OPTARG"; echo "Setting search pattern to: $search_pattern" ;;
		?) echo "error: option -$OPTARG is not implemented"; exit ;;
	esac
done


IFS=',' read -a hosts    <<< "$hosts_str"
IFS=',' read -a logfiles <<< "$logfiles_str"

echo ""
printf "Parsed IPs: ( "; printf '%s ' "${hosts[@]}"; echo ")"
printf "Parsed Logfiles: ( "; printf '%s ' "${logfiles[@]}"; echo ")"
echo ""


# trap ctrl-c for named pipe cleanup and ssh process killing
trap 'echo -e "\n\nCleaning up:"; for pid in $children; do echo "  PID: $pid"; kill -9 $pid 2>/dev/null; done; rm "$drive_prefix/$dir/tail.pipe"; exit 0' INT

# create named pipe to read remote tail output from
if [[ -p "$drive_prefix/$dir/tail.pipe" ]]; then
	rm "$drive_prefix/$dir/tail.pipe"
fi
mkdir -p "$drive_prefix/$dir"
mkfifo "$drive_prefix/$dir/tail.pipe"
children=""
for host in "${hosts[@]}"; do
	echo "Connecting to $host:"

	for logfile in "${logfiles[@]}"; do
		echo "  Tailing $logfiles_prefix/*$logfile*" # TODO add .log at the end again
		# establish ssh connection to the hosts and launch the remote command
		# use unique colored hostname-logfile prefix for every logline
		remote_command='echo "TAILING: $(ls -1 '"$logfiles_prefix/*$logfile"'*.log | tr "\n" " ")"; tail -Fn0 '"$logfiles_prefix/*$logfile"'*.log | while read logline; do printf "\e[38;5;'"$((1+$RANDOM%228))"'m%s\e[0m $logline" "[#]" | grep -Ei "'"$search_pattern"'"; done'
		# launch the ssh command in the background
		sshpass -p $password ssh -o "ConnectTimeout 3" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" $user@$host "$remote_command" 1>"$drive_prefix/$dir/tail.pipe" 2>/dev/null &
		# save the ssh child PID in order to clean it up at ctrl-c time
		[[ -n "$children" ]] && children+=" $!" || children+="$!"
	done
done

echo ""
echo "Please wait 30 seconds for logging to begin..."
echo "Self termination of command means an error exists"
echo ""

# read remote log lines from the named pipe
cat < "$drive_prefix/$dir/tail.pipe" | tee >(sed $'s/\033[[][^A-Za-z]*m//g' | sed "s/\[#\] //" > "$drive_prefix/$dir/tail.log")

