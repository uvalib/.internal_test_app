#
# Runner process to call the rake tasks that control deposit importing from SIS and optional registration
#

# environment settings
ENVIRONMENT=${RAILS_ENV:=development}
SNAPSHOT_NAMESPACE=$ENVIRONMENT

# determine if we are in a dockerized environment
if [ -n "$APP_HOME" ]; then
   export LOGGER=$APP_HOME/log/deposit_import.log
else
   export LOGGER=/dev/stdout
fi

# log file location

# snapshot file for optional ETD
export OPT_SNAPSHOT=$SNAPSHOT_NAMESPACE.deposit-opt.last

# snapshot file for SIS based ETD
export SIS_SNAPSHOT=$SNAPSHOT_NAMESPACE.deposit-sis.last

# our sleep time, currently 5 minutes
export SLEEPTIME=300

# the logging function
function logit {
   local msg=$1
   TS=$(date "+%Y-%m-%d %H:%M:%S")
   echo "$TS: $msg" >> $LOGGER
}

# helpful message...
logit "Starting up; using optional snapshot name $OPT_SNAPSHOT"

# forever...
while true; do

   # sleeping message...
   logit "Sleeping for $SLEEPTIME seconds ..."
   sleep $SLEEPTIME

   # starting message
   logit "Beginning optional deposit import sequence"

   # do the import
   rake libra2:ingest_optional_etd_deposits $OPT_SNAPSHOT >> $LOGGER 2>&1
   res=$?

   # ending message
   logit "Completes with status $res"

done

# never get here...
exit 0

#
# end of file
#
