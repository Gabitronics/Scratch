#!/bin/bash
###############################################################
#
#
#SCRIPT:  ap_scheduler.sh
#
# 2.15.0410a: -Modified comparison of Patch Tueday date with 
#              current date to calculate Auto Patch Run Date. 
# 2.15.0415a: -Added Sunday to element 0 of weekdaytxt array.
#
# 2.15.0602a: -Fixed month_length function to properly handle
#              months with "6" weeks. Modified sed command.
###############################################################
VERSION="Auto Patch Scheduling Script v2.15.0602a"
###############################################################
set -e     # exit the script if any statement returns a non-true return value
set -u     # exit the script if you try to use an uninitialized variable
#
###############################################################
###############################################################
#    VARIABLES
###############################################################
#
declare -a suffix=(" " "st" "nd" "rd" "th" "th" "th" "th" "th" "th" "th") # Append suffix to appropiate number: 1st, 2nd, 3rd, etc.
declare -a weekdaytxt=("Sunday" "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday") # Append suffix to appropiate number: 1st, 
#
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/usr/local/sbin
#
#--------------------------------------------------------------
PATCHMGR_HOME=/opt/patchmgr
#--------------------------------------------------------------
###############################################################
#  Exit script if you can't load the environment variable file
if [[ ! -f $PATCHMGR_HOME/auto_patch.env ]] ; then
   echo "Could not find environment variable file: $PATCHMGR_HOME/auto_patch.env"
   echo "Bye."
   exit 2
fi
. $PATCHMGR_HOME/auto_patch.env

###############################################################
#  Validate certain variables

if [ $AP_RUN_WEEK_OFFSET -lt 1 ] || [ $AP_RUN_WEEK_OFFSET -gt 4 ]; then 
   echo "AP_RUN_WEEK_OFFSET variable must be between 1-3 weeks. Check your environment variable file. Bye."
   exit 44
fi 
###############################################################

echo
echo "=========================================================="
echo "           $VERSION"
echo "=========================================================="
echo "                        Variables"
echo "----------------------------------------------------------"
echo 
echo "              AP_RUN_WEEKDAY=$AP_RUN_WEEKDAY"
echo "          AP_RUN_WEEK_OFFSET=$AP_RUN_WEEK_OFFSET"
echo "    AP_PATCH_TUESDAY_WEEKDAY=$AP_PATCH_TUESDAY_WEEKDAY"
echo "    AP_PATCH_TUESDAY_WEEKNUM=$AP_PATCH_TUESDAY_WEEKNUM"
echo
echo "               PATCHMGR_HOME=$PATCHMGR_HOME"
echo "              AUTO_PATCH_ENV=$PATCHMGR_HOME/auto_patch.env"
echo
echo "----------------------------------------------------------"

###############################################################
#  Set variables for last month, current month and next month

todaysdate=`date`

todaydom=`date "+%d"`
todaydom=$(expr $todaydom + 0) # Make result a true number (remove leading zeroes, etc.)

monthnum=`date "+%m"`
monthnum=$(expr $monthnum + 0) # Make result a true number (remove leading zeroes, etc.)

yearnum=`date "+%Y"`
yearnum=$(expr $yearnum + 0) # Make result a true number (remove leading zeroes, etc.)

(( lastmonthnum = monthnum - 1 ))
(( nextmonthnum = monthnum + 1 ))

if [[ $nextmonthnum -eq 13 ]] ; then 
      nextmonthnum=1
      (( nextyearnum = yearnum + 1 ))
else
      nextyearnum=$yearnum
fi

if [[ $lastmonthnum -eq 0 ]] ; then
    lastmonthnum=12
    (( lastyearnum = yearnum - 1 ))
else
    lastyearnum=$yearnum
fi
###############################################################
##  Gather relevant month names
monthname=`cal |awk '{ print $1;exit }'`
lastmonthname=`cal $lastmonthnum $lastyearnum|awk '{print $1;exit }'`
nextmonthname=`cal $nextmonthnum $nextyearnum|awk '{print $1;exit }'`

###############################################################
#  FUNCTION: calc_X_day_of_month
###############################################################
function calc_X_day_of_month {
cutoff_num=$1
cutoff_dayofweek=$2
month=$3
year=$4

        weekday=`cal $month $year| awk 'NR>2{ print $NF;exit}'|tr -cd '[[:digit:]]'`

(( first_day_of_week = 7 - weekday ))

if [[ $AP_PATCH_TUESDAY_WEEKDAY -ge $first_day_of_week ]]
then
        (( first_cutoff_dom = 1 + $AP_PATCH_TUESDAY_WEEKDAY - $first_day_of_week ))

else
        (( first_cutoff_dom = 1 + $weekday + $AP_PATCH_TUESDAY_WEEKDAY ))
fi

(( X_Day = $first_cutoff_dom + (7 * ($AP_PATCH_TUESDAY_WEEKNUM - 1) ) ))

echo $X_Day
}

###############################################################
# FUNCTION: month_length: How many days are in this month.
###############################################################
function month_length {
last_dom=`cal $1 $2|sed '/^\s*$/d'|tail -1|awk '{ print $NF }'|tr -cd '[[:digit:]]'`
echo $last_dom

}

#####################################################################

CURRENT_MONTH_PATCH_TUESDAY_DOM="$(calc_X_day_of_month  $AP_PATCH_TUESDAY_WEEKNUM $AP_PATCH_TUESDAY_WEEKDAY $monthnum $yearnum)"

PATCH_TUESDAY_DOM=$CURRENT_MONTH_PATCH_TUESDAY_DOM  # define the Patch Tuesday day of the month we will base our calculations on

CURRENT_MONTH_CUTOFF_MONTHNAME=$monthname # The name of the current month for Patch Tuesday purposes.

CUTOFF_MONTHNAME=$CURRENT_MONTH_CUTOFF_MONTHNAME

LAST_DOM=$(month_length $monthnum $yearnum) # Calculate teh last day of the current month

declare -i CURRENT_LAST_DOM=$LAST_DOM # define the current "last day of the month" as the current month's last day

PREVIOUS_LAST_DOM=$(month_length $lastmonthnum $lastyearnum)

AP_RUN_MONTH=$monthname  # Assume initially that the current month is the AP_RUN_MONTH

PREV_MONTH_PATCH_TUESDAY_DOM="$(calc_X_day_of_month  $AP_PATCH_TUESDAY_WEEKNUM $AP_PATCH_TUESDAY_WEEKDAY  $lastmonthnum $lastyearnum)"

if [[ $todaydom -lt $PATCH_TUESDAY_DOM ]]; then 

    PATCH_TUESDAY_DOM=$PREV_MONTH_PATCH_TUESDAY_DOM
    CUTOFF_MONTHNAME=$lastmonthname
    LAST_DOM="$(month_length $lastmonthnum $lastyearnum)"
    AP_RUN_MONTH=$lastmonthname
    (( RUN_DOM = $PATCH_TUESDAY_DOM + ( 7 - $AP_PATCH_TUESDAY_WEEKDAY) + $AP_RUN_WEEKDAY + ( ( $AP_RUN_WEEK_OFFSET - 1 ) * 7 ) ))

     if [[ $RUN_DOM -gt $LAST_DOM ]] ; then
          (( RUN_DOM = $RUN_DOM - $LAST_DOM ))
          AP_RUN_MONTH=$monthname
     fi

else 
     (( RUN_DOM = $PATCH_TUESDAY_DOM + ( 7 - $AP_PATCH_TUESDAY_WEEKDAY) + $AP_RUN_WEEKDAY + ( ( $AP_RUN_WEEK_OFFSET - 1 ) * 7 ) ))

     if [[ $RUN_DOM -gt $LAST_DOM ]] ; then
          (( RUN_DOM = $RUN_DOM - $LAST_DOM ))
                AP_RUN_MONTH=$nextmonthname
     else   
                AP_RUN_MONTH=$monthname
     fi


fi
if [[ -z "$RUN_DOM" ]] 
then
   echo "RUN_DOM variable not defined.  Cannot determine which Day of the Month I must run.  Bye."
   exit 11
fi

echo

    echo "                 TODAYS DATE: $todaysdate"
    echo
    echo "    LAST MONTH PATCH TUESDAY: $lastmonthname $PREV_MONTH_PATCH_TUESDAY_DOM"
    echo " CURRENT MONTH PATCH TUESDAY: $monthname $CURRENT_MONTH_PATCH_TUESDAY_DOM"
    echo "   PATCH TUESDAY WEEK OFFSET: $AP_RUN_WEEK_OFFSET"
    echo
    echo "         AUTO PATCH RUN DATE: ${weekdaytxt[$AP_RUN_WEEKDAY]}, $AP_RUN_MONTH $RUN_DOM"
echo
echo "=========================================================="

   if [[ $RUN_DOM -ne "$todaydom" ]]   ; then
       echo "I'm not scheduled to run today. Bye."
       echo "=========================================================="
       exit 66
   fi

echo "Auto Patch will run today! "
echo "=========================================================="
exit 0

