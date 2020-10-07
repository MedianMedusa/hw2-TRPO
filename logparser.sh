#!/bin/bash -e
##
## Anikeev Georgiy
## M3O-117M-20
##
## Log file analyser
##
##
## EXIT CODES:
##  code 2  - script is already running
##  code 3  - cannot open file for reading
##  code 10 - no parameter (path to log file)
##  code 20 - no file in path
##  
###############################################
##
## brief program explanation:
##
##  script takes a path to the log file as a parameter
##  and returns some metrics since the last script start:
##
##  1. top 15 IP-addresses which established connection to the site;
##  2. top 15 resources users tried to reach;
##  3. top site return codes sent to user;
##  4. count of error codes (4xx and 5xx).



# lockfile check:

lockfile=/tmp/AnikeevLockFile
if (set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null;
then
	trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
else
	echo "script is already running in thread No: $(cat $lockfile)"
	exit 2
fi


#parameter existence check:

filename=$1
if [ -n "$1" ]
then
	echo "got parameter: $1"
else
	echo "file undefined"
	exit 10
fi

#file existence check:
if [ -e "$filename" ]
then
	echo "$filename exists"
else
	echo "$filename doesn't exist"
	exit 20
fi

#file availability check:
if [ -r "$filename" ]
then
	echo "$filename is available for reading"
else
	echo "cannot open $filename for reading"
	exit 3
fi


## file parsing:

#check for previous script runs:
last=.logparser.last
if [ -e "$last" ]
then
	timestart=$( cat $last) 
else
	touch .logparser.last
	timestart=$( head $filename -n 1 | awk '{print $4}' | cut -c2- )
fi

timestop=$( tail $filename -n 1 | awk '{print $4}' | cut -c2- )
echo $timestop > $last
echo processing log from $timestart to $timestop:
timestart=$( echo $timestart | sed 's|/|\\/|g' | sed 's|:|\\:|g')

# top 15 IPs:
echo
echo top 15 IP\'s:
#1st awk '{print $1}' $filename | sort | uniq -c | sort -rn | head -n 15
#2 awk '/'$timestart'/{Q=1;}Q' $filename | awk '{print $1}' | sort | uniq -c | sort -rn | head -n 15
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $1}' | sort | uniq -c | sort -rn| head -n 15

# top 15 resources:
echo
echo top 15 resources:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $7}' | sort | uniq -c | sort -nr | head -n 15


# return codes list:
echo
echo return codes count:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $9}' | grep ^[^45] | sort | uniq -c | sort -n

# error codes list (4xx, 5xx):
echo
echo error return codes count:
tac $filename | awk '/'$timestart'/ {exit} 1' | tac | awk '{print $9}' | grep ^[45]| sort | uniq -c | sort -n








