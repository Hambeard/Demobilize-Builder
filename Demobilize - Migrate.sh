#!/bin/bash

echo "Activating Jamf Connect Login"
/usr/local/bin/authchanger -reset -JamfConnect
echo "Restarting loginwindow process"
kill -9 "$(ps axc | awk '/loginwindow/{print $1}')"

exit 0