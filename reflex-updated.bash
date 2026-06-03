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
### 6. WARNING: Remember to not rerun the script, as it will overwrite the existing files!          ###
### 7. Enjoy the analysis!!!                                                                        ###
#######################################################################################################
### Author: Hassan Shabbir                                                                          ###
### Email:  hshabbir@evertz.com                                                                     ###
#######################################################################################################

#######################################################################################################
### Bash Variables Section
# search term regex
search="mdl_return_channel_groups_trigger"
# date-time range regex, with increasing time specificity
large="2024-04-09T0[789]"
medium="2024-04-09T08"
small="2024-04-09T08:3"
#######################################################################################################

# Define a helper function called unique which will:
# display the first occurrence of unique lines, ignoring numbers and matching the provided pattern.
# Syntax:
#     unique [gawk-regex] [input-file] [output-file]
# Example:
#     unique "//"                    reflex reflex-uniq
#     unique "/$search/"             reflex reflex-uniq
#     unique "/$search/ && /$large/" reflex reflex-search-time-uniq
function unique () {
    gawk "BEGIN{IGNORECASE=1; print \"Summary (first occurrence of match ignoring numbers):\"} $1 {a = \$0; gsub(/[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}|[0-9a-f]{2}(:[0-9a-f]{2}){5}|[0-9]+|0x[0-9a-f]+|[0-9]+/,\"\",a); print \$0, \"###\", a}" "$2" | gawk -F '###' 'BEGIN{IGNORECASE=1} !seen[$2]++ {print $1}' > "$3"
}

# Unzip all gzipped reflex files
ls | gawk '/reflex/ && /\.gz/' | xargs gzip -dk
# Unzip all gzipped magselfmonsrv files
cd magselfmonsrv
ls | gawk '/metrics/ && /\.gz/' | xargs gzip -dk
cd ..

# TODO test these. List all unzipped files and concatenate them into the reflex and metrics file
ls | gawk '/reflex\.log.+/ && !/\.gz/' | xargs -I{} cat {} reflex.log > reflex
cd magselfmonsrv
ls | gawk '/metrics\.log.+/ && !/\.gz/' | xargs -I{} cat {} metrics.log > metrics
cd ..

# Filter the search term in the reflex file
gawk "/$search/"              reflex > reflex-search
gawk "/$large/"               reflex > reflex-large
gawk "/$medium/"              reflex > reflex-medium
gawk "/$small/"               reflex > reflex-small
gawk "/$search/ && /$large/"  reflex > reflex-search-large
gawk "/$search/ && /$medium/" reflex > reflex-search-medium
gawk "/$search/ && /$small/"  reflex > reflex-search-small
cd magselfmonsrv
gawk "/$search/"              metrics > metrics-search
gawk "/$large/"               metrics > metrics-large
gawk "/$medium/"              metrics > metrics-medium
gawk "/$small/"               metrics > metrics-small
gawk "/$search/ && /$large/"  metrics > metrics-search-large
gawk "/$search/ && /$medium/" metrics > metrics-search-medium
gawk "/$search/ && /$small/"  metrics > metrics-search-small
cd ..

# Print files that are still using config.autostart
gawk -F':' '/config\.autostart is deprecated/ {print $5}' reflex | sed 's/^ //' | sort | uniq > reflex-autostart-deprecation

# Reflex CPU usage
cd magselfmonsrv
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics                     > metrics-cpu
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-large               > metrics-cpu-large
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-medium              > metrics-cpu-medium
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-small               > metrics-cpu-small
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics        | sort -nrk2 > metrics-cpu-sort
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-large  | sort -nrk2 > metrics-cpu-sort-large
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-medium | sort -nrk2 > metrics-cpu-sort-medium
gawk '/reflex CPU Usage \(%\)/ {print $1, $9}' metrics-small  | sort -nrk2 > metrics-cpu-sort-small
# Reflex CPU over 70%
gawk '($2 > 70.0 && !/[7-9]\./) || ($2 ~ /[0-9]{3}/)' metrics-cpu | sort -nrk2 > metrics-cpu-high
echo "High Reflex CPU usage, times per day (if applicable):"
gawk '($2 > 70.0 && !/[7-9]\./) || ($2 ~ /[0-9]{3}/) {print $1}' metrics-cpu | gawk -F'.' '{print $1}' | gawk -F'T' '{print $1}' | uniq -c | tee metrics-cpu-high-per-day
gawk '($2 > 70.0 && !/[7-9]\./) || ($2 ~ /[0-9]{3}/) {print $1}' metrics-cpu | gawk -F'.' '{print $1}' | gawk -F':' '{print $1}' | uniq -c | sort -nrk1 > metrics-cpu-high-per-hour-sort
cd ..

# Start and end of logging in logs
head -n1 reflex | gawk '{print $1}' > reflex-log-range
tail -n1 reflex | gawk '{print $1}' > reflex-log-range

# Check for Reflex restarts, and elide the end of the lines
echo "Reflex Restarts (if applicable):"
gawk '/REFLEX version/ {for (i=1;i<=12;i++) printf "%s%s", $i, (i<12 ? " " : " ...\n")}' reflex | tee reflex-restarts

# Check for missing logging times
gawk '{print $1}' reflex | gawk -F'.' '{print $1}' | gawk -F':' '{print $1 ":" $2}' | uniq > reflex-missing-logs

# Summarizes by printing the first occurrence of a match, while ignoring decimal/hex numbers/ips
unique '//'                     reflex        reflex-uniq
unique "/$search/"              reflex-search reflex-search-uniq
unique "/$large/"               reflex-large  reflex-large-uniq
unique "/$medium/"              reflex-medium reflex-medium-uniq
unique "/$small/"               reflex-small  reflex-small-uniq
unique "/$search/ && /$large/"  reflex-search reflex-search-large-uniq
unique "/$search/ && /$medium/" reflex-search reflex-search-medium-uniq
unique "/$search/ && /$small/"  reflex-search reflex-search-small-uniq

# Check for route failures
gawk '/magnum.route failure/' reflex >> reflex-route-fail

# TODO!!! Check trigger execution times and number of executions
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex        | gawk -F'(' '{print $1}' | gawk -F':' '{print $1}' | sort | uniq > reflex-trigger-uniq
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex-large  | gawk -F'(' '{print $1}' | gawk -F':' '{print $1}' | sort | uniq > reflex-trigger-large-uniq
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex-medium | gawk -F'(' '{print $1}' | gawk -F':' '{print $1}' | sort | uniq > reflex-trigger-medium-uniq
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex-small  | gawk -F'(' '{print $1}' | gawk -F':' '{print $1}' | sort | uniq > reflex-trigger-small-uniq
#
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex        | gawk -F'(' '{print $1}' | sort | uniq -c | sort -nrk1 > reflex-trigger-count
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex-large  | gawk -F'(' '{print $1}' | sort | uniq -c | sort -nrk1 > reflex-trigger-large-count
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex-medium | gawk -F'(' '{print $1}' | sort | uniq -c | sort -nrk1 > reflex-trigger-medium-count
gawk '/Trigger/ {print gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex-small  | gawk -F'(' '{print $1}' | sort | uniq -c | sort -nrk1 > reflex-trigger-small-count
#
gawk '/Trigger/ {print $1, "Trigger:", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex > reflex-trigger
gawk '/Trigger/ && !/in alotted [0-9]*ms/ {print $1, "Trigger:", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | sort -k3 > reflex-trigger-sort

# Print large reflex.context.set which may cause issues
gawk '/Run action "reflex\.context\.set"/ && length($0) > 500 {print length($0), $1, "Trigger", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex > reflex-length-context-set
gawk '/Run action "reflex\.context\.set"/ && length($0) > 500 {print length($0), $1, "Trigger", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | sort -nrk1 > reflex-length-context-set-sort
# Number of times the context.set went over the 500 char amount
gawk '/Run action "reflex\.context\.set"/ && length($0) > 500 {print length($0), $1, "Trigger", gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'(' '{print $1}' | gawk '{print $4 $5 $6 $7 $8 $9 $10}' | sort | uniq -c | sort -nrk 1 > reflex-length-context-set-count
# Print when context is updated to undefined
gawk '/undefined/ && /Context Updated/' reflex        > reflex-context-set-undefined
gawk '/undefined/ && /Context Updated/' reflex-large  > reflex-context-set-undefined-large
gawk '/undefined/ && /Context Updated/' reflex-medium > reflex-context-set-undefined-medium
gawk '/undefined/ && /Context Updated/' reflex-small  > reflex-context-set-undefined-small
gawk '/undefined/ && /Context Updated/' reflex | gawk -F'"' '{print $2}' | sort | uniq -c | sort -nrk1 > reflex-context-set-undefined-count

# Print activated sensors
gawk '/Sensor "/'             reflex        > reflex-sensor
gawk "/$search/"              reflex-sensor > reflex-sensor-search
gawk "/$large/"               reflex-sensor > reflex-sensor-large
gawk "/$medium/"              reflex-sensor > reflex-sensor-medium
gawk "/$small/"               reflex-sensor > reflex-sensor-small
gawk "/$search/ && /$large/"  reflex-sensor > reflex-sensor-search-large
gawk "/$search/ && /$medium/" reflex-sensor > reflex-sensor-search-medium
gawk "/$search/ && /$small/"  reflex-sensor > reflex-sensor-search-small

# Print possible reflex wamp/CH interface bug and the times of (un)registration
gawk '/wamp/ && /registered/ {print $1, $5, gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | gawk -F'.' '{print $10}' | sort | uniq -c > reflex-wamp-bug-times
gawk '/wamp/ && /registered/ {print $5, gensub(/.*"([^"]*)".*/, "\\1", 1)}' reflex | sort | uniq -c | sort -nrk1 > reflex-wamp-bug-count
