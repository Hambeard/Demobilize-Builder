#!/bin/bash

# Parameter labels
# Parameter 4 - Title
# Parameter 5 - Message line 1
# Parameter 6 - Message line 2
# Parameter 7 - Icon path

## VARIABLES

jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

title="$4"
message="$5"
messageLine2="$6"
icon="$7"

## DEFAULT MESSAGING
if [[ "$title" == "" ]]; then
    /bin/echo "No title specified, using default title"
    title="Important Message from IT"
fi

if [[ "$message" == "" ]]; then
    /bin/echo "No message line 1 specified, using default message line 1"
    message="We need your help to enable a new tool called Jamf Connect. It will help keep your Mac password in sync with the password you use to access other company services and apps."
fi

if [[ "$messageLine2" == "" ]]; then
    /bin/echo "No message line 2 specified, using default message line 2"
    messageLine2="Please save anything you're working on and click Continue when ready. You will be required to log out on the next page."
fi

if [[ "$icon" == "" ]]; then
    /bin/echo "No icon specified, using default icon"
    icon="/Applications/Jamf Connect.app/Contents/Resources/AppIcon.icns"
fi

/usr/local/bin/jamf recon

## Jamf Helper window
"$jamfHelper" \
-windowType "utility" \
-title "$title" \
-description "$message

$messageLine2" \
-button1 "Continue" \
-icon "$icon" \
-iconSize "250" \
-timeout "600" \
-countdown \
-alignCountdown "center" > /dev/null 2>&1

### Log out
loggedInUser=$( /usr/bin/stat -f %Su /dev/console )
loggedInUserID=$( /usr/bin/id -u "$loggedInUser" )

echo "Asking $loggedInUser to log out"
launchctl asuser "$loggedInUserID" osascript -e 'tell app "System Events" to log out'

exit 0