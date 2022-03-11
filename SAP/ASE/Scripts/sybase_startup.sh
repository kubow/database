#!/bin/sh
# sybase       Startup script for Sybase ASE
# 
# chkconfig: - 85 15
# description: Sybase Adaptive Server Enterprise
# processname: dataserver 

# Source function library
. /etc/rc.d/init.d/functions

# Source environment variables
[ -z "$SYBASE_HOME" ] && SYBASE_HOME=`echo ~sybase`
. $SYBASE_HOME/SYBASE.sh

# Determine server name
[ -z "$SYBASE_SERVER" ] && SYBASE_SERVER="SYBASE"

# Find the name of the script
BASENAME=`basename $0`

# For SELinux we need to use 'runuser' not 'su'
if [ -x /sbin/runuser ]
then
	SU=runuser
else
	SU=su
fi

script_result=0

start() {
	SYBASE_START=$"Starting ${BASENAME} service: "
	echo -n "$SYBASE_START"
	$SU -l sybase -c "startserver -f $SYBASE/$SYBASE_ASE/install/RUN_$SYBASE_SERVER" > /dev/null
	ret=$? 
	if [ $ret -eq 0 ]
	then
		success "$SYBASE_START"
	else
		failure "$SYBASE_START"
		script_result=1
	fi
	echo
}

stop() {
	echo -n $"Stopping ${BASENAME} service: "
	$SU -l sybase -c "isql -S $SYBASE_SERVER -U sa < ~/stop.in" > /dev/null
	ret=$?
	if [ $ret -eq 0 ]
	then
		echo_success
	else
		echo_failure
		script_result=1
	fi
	echo
}

case "$1" in

	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status dataserver
		script_result=$?
		;;
	restart)
		stop
		start
		;;
	*)
		echo $"Usage: $0 {start|stop|status|restart}"
		script_result=1

esac

exit $script_result
