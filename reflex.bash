#! /bin/bash
#######################################################################################################
###      ____       ______             __                   ___                __           _       ###
###     / __ \___  / __/ /__  _  __   / /   ____  ____ _   /   |  ____  ____ _/ /_  _______(_)____  ###
###    / /_/ / _ \/ /_/ / _ \| |/_/  / /   / __ \/ __ `/  / /| | / __ \/ __ `/ / / / / ___/ / ___/  ###
###   / _, _/  __/ __/ /  __/>  <   / /___/ /_/ / /_/ /  / ___ |/ / / / /_/ / / /_/ (__  ) (__  )   ###
###  /_/ |_|\___/_/ /_/\___/_/|_|  /_____/\____/\__, /  /_/  |_/_/ /_/\__,_/_/\__, /____/_/____/    ###
###                                            /____/                        /____/                 ###
#######################################################################################################
### How To Use:                                                                                     ###
### 1. WinSCP the file to the computer and directory you wish to run this script in                 ###
### 2. Change the below Bash Variables section on each run (if required)                            ###
###    NOTE: Regex is used, see https://quickref.me/regex.html and https://regex101.com/            ###
### 3. Verify that the file has execute permissions using `ls`                                      ###
###    If not, use `chmod +x reflex.bash` to make it executable                                     ###
### 4. Run this script using `./reflex.bash`                                                        ###
### 5. View the files generated (all generated files will have the `reflex-` prefix                 ###
###    Don't forget about the `magselfmonsrv/metrics-` files!                                       ###
### 6. Enjoy!!!                                                                                     ###
#######################################################################################################
### Author: Hassan Shabbir                                                                          ###
### Email:  hshabbir@evertz.com                                                                     ###
#######################################################################################################

#######################################################################################################
### Bash Variables Section

# toggle filtering metavariables
search_filter=0
time_filter=0

# search term regex
search="mdl_return_pss_status_trigger"

# date-time range regex, with increasing time specificity
large="2024-03-01T0[567]"
medium="2024-03-01T06"
small="2024-03-01T06:3"

### End Variables Section
#######################################################################################################

# Define a helper function called unique which will:
# display the first occurrence of unique lines, 
# ignoring certain numbers and matching the provided pattern.
# Syntax:
#     unique [gawk-regex] [input-file] [output-file]
# Example:
#     unique "//"                    reflex reflex-uniq
#     unique "/$search/"             reflex reflex-uniq
#     unique "/$search/ && /$large/" reflex reflex-search-time-uniq
function unique () {
	gawk "BEGIN{IGNORECASE=1; print \"Summary (first occurrence of match ignoring numbers):\"} $1 {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,\"\",a); print \$0, \"###\", a}" "$2" | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > "$3"
}

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

# Unzip and combine all files for a Magnum service into one file (chronological)
# Syntax:
#     combine [magnum-service]
# Example:
#     combine reflex
function combine () {
	ls | gawk "/$1\./ && /\.gz/" | xargs gzip -dk
	ls | gawk '/'"$1"'\.log.+/ && !/\.gz/' | xargs -I{} cat {} "$1".log > "$1"
}

function combine-all () {
	for file in $(ls *.gz | gawk -F '.' '{print $1}' | uniq); do echo "combining file: $file"; combine $file; done
	cd magselfmonsrv
	for file in $(ls *.gz | gawk -F '.' '{print $1}' | uniq); do echo "combining magselfmonsrv file: $file"; combine $file; done
	cd ..
}

echo "# Unzip and concatenate all gzipped reflex files"
combine reflex
cd magselfmonsrv
combine metrics
cd ..

echo "# Search the search and time terms in the reflex file"
if [[ search_filter -eq 1 ]]; then
	echo "search_filter == 1"
	gawk "/$search/"              reflex  >> reflex-search

	cd magselfmonsrv
	gawk "/$search/"              metrics >> metrics-search
	cd ..
fi

if [[ time_filter -eq 1 ]]; then
	echo "time_filter == 1"
	gawk "/$large/"               reflex  >> reflex-large
	gawk "/$medium/"              reflex  >> reflex-medium
	gawk "/$small/"               reflex  >> reflex-small

	cd magselfmonsrv
	gawk "/$large/"               metrics >> metrics-large
	gawk "/$medium/"              metrics >> metrics-medium
	gawk "/$small/"               metrics >> metrics-small
	cd ..
fi

if [[ search_filter -eq 1 && time_filter -eq 1 ]]; then
	echo "search_filter == 1 && time_filter == 1"
	gawk "/$search/ && /$large/"  reflex  >> reflex-search-large
	gawk "/$search/ && /$medium/" reflex  >> reflex-search-medium
	gawk "/$search/ && /$small/"  reflex  >> reflex-search-small

	cd magselfmonsrv
	gawk "/$search/ && /$large/"  metrics >> metrics-search-large
	gawk "/$search/ && /$medium/" metrics >> metrics-search-medium
	gawk "/$search/ && /$small/"  metrics >> metrics-search-small
	cd ..
fi

echo "# Print files that are still using config.autostart (prints)"
gawk -F':' '/config\.autostart is deprecated/ {print $5}' reflex | sed 's/^ //' | uniq | tee -a reflex-autostart-deprecation

echo "# Reflex CPU usage (prints top 30)"
cd magselfmonsrv
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics                     >> metrics-cpu
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics        | sort -nrk2 >> metrics-cpu-sort
head -n 30 metrics-cpu-sort
if [[ $(wc -l metrics-cpu-sort) -gt 30 ]]; then
	echo ".........."
fi
if [[ time_filter -eq 1 ]]; then
	gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-large               >> metrics-cpu-large
	gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-medium              >> metrics-cpu-medium
	gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-small               >> metrics-cpu-small
	gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-large  | sort -nrk2 >> metrics-cpu-sort-large
	gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-medium | sort -nrk2 >> metrics-cpu-sort-medium
	gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-small  | sort -nrk2 >> metrics-cpu-sort-small
fi
cd ..

echo "# Duration of logs (prints)"
log_start=$(head -n1 reflex | gawk '{print $1}'); echo $log_start >> reflex-log-range
log_end=$(  tail -n1 reflex | gawk '{print $1}'); echo $log_end   >> reflex-log-range
log_range=$(( $(date -d $log_end '+%s') - $(date -d $log_start '+%s') ))
displaytime $log_range | tee -a reflex-log-range

echo "# Check for Reflex restarts (prints)"
gawk '/REFLEX version/' reflex | tee -a reflex-restarts

echo "# Check for missing logging times"
gawk '{print $1}' reflex | gawk -F'.' '{print $1}' | gawk -F':' '{print $1 ":" $2}' | uniq >> reflex-missing-logs
#for line in $(head -n 1500 reflex | gawk '{print $1}'); do echo "$(date -d $line '+%s')"; done | sed 's/.$//' | uniq

echo "# Summarizes by printing the first occurrence of a match, while ignoring decimal/hex numbers/ips"
unique '//'                     reflex        reflex-uniq

if [[ search_filter -eq 1 ]]; then
	unique "/$search/"              reflex-search reflex-search-uniq
fi

if [[ time_filter -eq 1 ]]; then
	unique "/$large/"               reflex-large  reflex-large-uniq
	unique "/$medium/"              reflex-medium reflex-medium-uniq
	unique "/$small/"               reflex-small  reflex-small-uniq
fi

if [[ search_filter -eq 1 && time_filter -eq 1 ]]; then
	unique "/$search/ && /$large/"  reflex-search reflex-search-large-uniq
	unique "/$search/ && /$medium/" reflex-search reflex-search-medium-uniq
	unique "/$search/ && /$small/"  reflex-search reflex-search-small-uniq
fi


echo "# Check for route failures (prints)"
gawk '/magnum.route failure/' reflex | tee -a reflex-route-fail

echo "# Check trigger execution times and number of executions"
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'(' '{print $1}' | gawk -F':' '{print $1}' | sort | uniq >> reflex-trigger-uniq
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'(' '{print $1}' | sort | uniq -c | sort -nrk1 >> reflex-trigger-count

if [[ time_filter -eq 1 ]]; then
	gawk '/Trigger/ && /'"$time"'/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'(' '{print $1}' | gawk -F':' '{print $1}' | sort | uniq >> reflex-trigger-time-uniq
	gawk '/Trigger/ && /'"$time"'/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'(' '{print $1}' | sort | uniq -c | sort -nrk1 >> reflex-trigger-time-count
fi

echo "# Reflex Triggers (prints top 30)"
gawk '/Trigger/ {print $1, "Trigger:", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex >> reflex-trigger
head -n 30 reflex-trigger
if [[ $(wc -l reflex-trigger) -gt 30 ]]; then
	echo ".........."
fi
# TODO: This outputs incorrect values!!!
gawk '/Trigger/ && !/in alotted [0-9]*ms/ {print $1, "Trigger:", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | sort -k3 >> reflex-trigger-sort

echo "# Print large reflex.context.set which may cause issues"
gawk '/Run action "reflex\.context\.set"/ && length($0) > 500 {print length($0), $1, "Trigger", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex >> reflex-big-context-set
gawk '/Run action "reflex\.context\.set"/ && length($0) > 500 {print length($0), $1, "Trigger", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | sort -nrk1 >> reflex-big-context-set-sort

echo "# Print when context is updated to undefined"
gawk '/undefined/ && /Context Updated/' reflex >> reflex-context-set-undefined

echo "# Print activated sensors"
gawk '/Sensor "/' reflex >> reflex-sensor

echo "# Print possible reflex wamp/CH interface bug and the times of (un)registration"
gawk '/wamp/ && /registered/ {print $1, $5, gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'.' '{print $10}' | sort | uniq -c >> reflex-wamp-bug-times
gawk '/wamp/ && /registered/ {print $5, gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | sort | uniq -c | sort -nrk1 >> reflex-wamp-bug-count
