#!/bin/bash

# Parameter 4 - Custom trigger (optional)

trigger="$4"

if [[ "$4" == "" ]]; then
	echo "No custom trigger specified, using default: demobilizeCustomTrigger"
	trigger="demobilizeCustomTrigger"
else
	echo "Using custom trigger parameter: $trigger"
fi	

NETACCLIST=$( dscl . list /Users OriginalNodeName | awk '{print $1}' 2>/dev/null )
if [ "$NETACCLIST" == "" ]; then
	echo "No Mobile Accounts found, calling next policy"
	/usr/local/bin/jamf policy -event "$trigger"
fi
exit 0