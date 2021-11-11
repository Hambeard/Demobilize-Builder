#!/bin/bash
#
# Script: Jamf Connect demobilize workflow builder.sh
# Version: 1.0
# Author: Andrew Needham
# Date: 11 Nov 2021
#
###################################################################################################
# License information
###################################################################################################
# Copyright 2021
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this
# software and associated documentation files (the "Software"), to deal in the Software
# without restriction, including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
###################################################################################################
## ABOUT ##
#
# A script designed to build a framework in Jamf Pro to demobilize and migrate computers with mobile
# accounts for use with Jamf Connect.
#
## INSTRUCTIONS ##
#
# Run using sh "/PATH/TO/SCRIPT". The script needs to load other scripts present in run directory.
# Please ensure that terminal has TCC access to the location you are running the script from, 
# failure to do so may result in errors.
#
###################################################################################################

echo "Please enter your Jamf Pro URL (include https://)"
read -r jssURL
echo
echo "Please enter your Jamf Pro username"
read -r apiUser
echo
echo "Please enter your Jamf Pro password"
read -rs apiPass
echo
PS3="Select a workflow: "
select opt in "Demobilize only" "Demobilize & migrate"; do
	case $opt in
		"Demobilize only")
			echo
			echo "You have selected Demobilize only"
			selection="1"
			break;;
		"Demobilize & migrate")
			echo
			echo "You have selected Demobilize & migrate"
			selection="2"
			break;;
		*)
			echo
			echo "Invalid selection $REPLY"
		;;
	esac
done
echo
echo "Script status message: HTTP status code"
echo "-------------"
echo

## Ensure that 
strLen=$((${#jssURL}-1))
lastChar="${jssURL:$strLen:1}"
if [ ! "$lastChar" = "/" ];then
	jssURL="${jssURL}/"
fi

scriptPath="$( cd -- "$(dirname "$0")" || exit >/dev/null 2>&1 ; pwd -P )"

## Enable login hooks
count="1"
until [[ "$count" -eq 3 ]]; do
	resultHooks=$( curl -H "Content-Type: application/xml" \
	-sfu "${apiUser}:${apiPass}" \
	-w "##%{http_code}" \
	-X PUT "${jssURL}JSSResource/computercheckin" \
	-d '<?xml version="1.0" encoding="UTF-8"?>
		<computer_check_in>
			<create_login_logout_hooks>true</create_login_logout_hooks>
		</computer_check_in>'
	)
	resultHooksCode=$( echo "$resultHooks" | awk -F"##" '{ print $2 }' )
	if [[ "$resultHooksCode" == "201" ]]; then
		echo "Login hooks enabled"
		break
	else
		echo "$resultHooksCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error enabling Login hooks."
	fi
	sleep 3
done

echo

## Enable Check for policies at login
count="1"
until [[ "$count" -eq 3 ]]; do
	resultCheckLogin=$( curl -H "Content-Type: application/xml" \
	-sfu "${apiUser}:${apiPass}" \
	-w "##%{http_code}" \
	-X PUT "${jssURL}JSSResource/computercheckin" \
	-d '<?xml version="1.0" encoding="UTF-8"?>
		<computer_check_in>
			<check_for_policies_at_login_logout>true</check_for_policies_at_login_logout>
		</computer_check_in>'
	)
	resultCheckLoginCode=$( echo "$resultCheckLogin" | awk -F"##" '{ print $2 }' )
	if [[ "$resultCheckLoginCode" == "201" ]]; then
		echo "Check for policies at login enabled"
		break
	else
		echo "$resultCheckLoginCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error enabling Check for policies at login"
	fi
	sleep 3
done

echo

## Create Jamf Connect category
count="1"
until [[ "$count" -eq 3 ]]; do
	resultCat=$( curl -H "Content-Type: application/xml" \
	-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/categories/id/0" \
	-X POST \
	-w "##%{http_code}" \
	-d '<?xml version="1.0" encoding="UTF-8"?>
		<category>
			<id>0</id>
			<name>Jamf Connect</name>
			<priority>9</priority>
		</category>'
	)
	resultCatCode=$( echo "$resultCat" | awk -F"##" '{ print $2 }' )
	if [[ "$resultCatCode" == "201" ]]; then
		echo "Jamf Connect category created"
		break
	else
		echo "$resultCatCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Jamf Connect category"
	fi
	sleep 3
done

echo

## Create Mobile Accounts Extension Attribute
count="1"
until [[ "$count" -eq 3 ]]; do
resultEA=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/computerextensionattributes/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<computer_extension_attribute>
	<id>0</id>
	<name>Mobile Accounts</name>
	<enabled>true</enabled>
	<description>Monitors mobile accounts on Macs</description>
	<data_type>String</data_type>
	<input_type>
		<platform>Mac</platform>
		<type>Script</type>
		<script>#!/bin/bash

NETACCLIST=$(dscl . list /Users OriginalNodeName | awk &apos;{print $1}&apos; 2&gt;/dev/null)
if [ &quot;$NETACCLIST&quot; == &quot;&quot; ]; then
	echo &quot;&lt;result&gt;No Mobile Accounts&lt;/result&gt;&quot;
else
	echo &quot;&lt;result&gt;$NETACCLIST&lt;/result&gt;&quot;
fi
exit 0</script>
	</input_type>
	<inventory_display>General</inventory_display>
	<recon_display>Extension Attributes</recon_display>
</computer_extension_attribute>'
)
resultEACode=$( echo "$resultEA" | awk -F"##" '{ print $2 }' )
	if [[ "$resultEACode" == "201" ]]; then
		echo "Extension Attribute created"
		break
	else
		echo "$resultEACode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Extension Attribute"
	fi
	sleep 3
done

echo

## Create Demobilize - Helper.sh
if [[ ! -f "$scriptPath/Demobilize - Helper.sh" ]]; then
	echo "Demobilize - Helper.sh not found, exiting"
	exit 1
else
jamfHelperScript=$( /bin/cat "$scriptPath/Demobilize - Helper.sh" )
jamfHelperScript=$( echo "$jamfHelperScript" | base64 )

count="1"
until [[ "$count" -eq 3 ]]; do
resultScript=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/scripts/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<script>
	<id>0</id>
	<name>Demobilize - Helper</name>
	<category>Jamf Connect</category>
	<filename>Demobilize - Helper.sh</filename>
	<info/>
	<notes/>
	<priority>After</priority>
	<parameters>
		<parameter4>Title</parameter4>
		<parameter5>Message line 1</parameter5>
		<parameter6>Message line 2</parameter6>
		<parameter7>Icon path</parameter7>
	</parameters>
	<os_requirements/>
	<script_contents_encoded>'"$jamfHelperScript"'</script_contents_encoded>
</script>' \
)
resultScriptCode=$( echo "$resultScript" | awk -F"##" '{ print $2 }' )
	if [[ "$resultScriptCode" == "201" ]]; then
		echo "Demobilize - Helper script created"
		break
	else
		echo "$resultScriptCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Helper script"
	fi
sleep 3
done
fi

echo

## Create Demobilize - Trigger.sh
if [[ ! -f "$scriptPath/Demobilize - Trigger.sh" ]]; then
	echo "Demobilize - Trigger.sh not found, exiting"
	exit 1
else
jamfHelperScript2=$( /bin/cat "$scriptPath/Demobilize - Trigger.sh" )
jamfHelperScript2=$( echo "$jamfHelperScript2" | base64 )

count="1"
until [[ "$count" -eq 3 ]]; do
resultScript2=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/scripts/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<script>
	<id>0</id>
	<name>Demobilize - Trigger</name>
	<category>Jamf Connect</category>
	<filename>Demobilize - Trigger.sh</filename>
	<info/>
	<notes/>
	<priority>After</priority>
	<parameters>
	<parameter4>Custom trigger (optional)</parameter4>
	</parameters>
	<os_requirements/>
	<script_contents_encoded>'"$jamfHelperScript2"'</script_contents_encoded>>
</script>' \
)
resultScript2Code=$( echo "$resultScript2" | awk -F"##" '{ print $2 }' )
	if [[ "$resultScript2Code" == "201" ]]; then
		echo "Demobilize - Trigger script created"
		break
	else
		echo "$resultScript2Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Trigger script"
	fi
sleep 3
done
fi

echo

## Create Demobilize - Helper.sh
if [[ ! -f "$scriptPath/Demobilize - Migrate.sh" ]]; then
	echo "Demobilize - Migrate.sh not found, exiting"
	exit 1
else
jamfHelperScript3=$( /bin/cat "$scriptPath/Demobilize - Migrate.sh" )
jamfHelperScript3=$( echo "$jamfHelperScript3" | base64 )

count="1"
until [[ "$count" -eq 3 ]]; do
resultScript3=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/scripts/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<script>
	<id>0</id>
	<name>Demobilize - Migrate</name>
	<category>Jamf Connect</category>
	<filename>Demobilize - Migrate.sh</filename>
	<info/>
	<notes/>
	<priority>After</priority>
	<parameters>
	</parameters>
	<os_requirements/>
	<script_contents_encoded>'"$jamfHelperScript3"'</script_contents_encoded>
</script>' \
)
	resultScript3Code=$( echo "$resultScript3" | awk -F"##" '{ print $2 }' )
	if [[ "$resultScript3Code" == "201" ]]; then
		echo "Demobilize - Migrate script created"
		break
	else
		echo "$resultScript3Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Migrate script"
	fi
sleep 3
done
fi

echo

## Create Smart Computer Groups
	
## Demobilize - No Mobile Accounts
count="1"
until [[ "$count" -eq 3 ]]; do
resultSG1=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/computergroups/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<computer_group>
	<id>0</id>
	<name>Demobilize - No Mobile Accounts</name>
	<is_smart>true</is_smart>
	<site>
		<id>-1</id>
		<name>None</name>
	</site>
	<criteria>
		<criterion>
			<name>Mobile Accounts</name>
			<priority>0</priority>
			<and_or>and</and_or>
			<search_type>is</search_type>
			<value>No Mobile Accounts</value>
			<opening_paren>false</opening_paren>
			<closing_paren>false</closing_paren>
		</criterion>
	</criteria>
</computer_group>'
)
resultSG1Code=$( echo "$resultSG1" | awk -F"##" '{ print $2 }' )
	if [[ "$resultSG1Code" == "201" ]]; then
		echo "Smart Group (Demobilize - No Mobile Accounts) created"
		break
	else
		echo "$resultSG1Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Smart Group (Demobilize - No Mobile Accounts)"
	fi
	sleep 3
done

echo

## Demobilize - Mobile Accounts
count="1"
until [[ "$count" -eq 3 ]]; do
resultSG2=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/computergroups/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<computer_group>
	<id>0</id>
	<name>Demobilize - Mobile Accounts</name>
	<is_smart>true</is_smart>
	<site>
		<id>-1</id>
		<name>None</name>
	</site>
	<criteria>
		<criterion>
			<name>Mobile Accounts</name>
			<priority>0</priority>
			<and_or>and</and_or>
			<search_type>is not</search_type>
			<value>No Mobile Accounts</value>
			<opening_paren>false</opening_paren>
			<closing_paren>false</closing_paren>
		</criterion>
		<criterion>
			<name>Mobile Accounts</name>
			<priority>0</priority>
			<and_or>and</and_or>
			<search_type>is not</search_type>
			<value></value>
			<opening_paren>false</opening_paren>
			<closing_paren>false</closing_paren>
		</criterion>
	</criteria>
</computer_group>'
)
resultSG2Code=$( echo "$resultSG2" | awk -F"##" '{ print $2 }' )
	if [[ "$resultSG2Code" == "201" ]]; then
		echo "Smart Group (Demobilize - Mobile Accounts) created"
		break
	else
		echo "$resultSG2Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Smart Group (Demobilize - Mobile Accounts)"
	fi
sleep 3
done

echo

## Demobilize - Jamf Connect not installed
count="1"
until [[ "$count" -eq 3 ]]; do
resultSG3=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/computergroups/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<computer_group>
	<id>0</id>
	<name>Demobilize - Jamf Connect not installed</name>
	<is_smart>true</is_smart>
	<site>
		<id>-1</id>
		<name>None</name>
	</site>
	<criteria>
		<criterion>
			<name>Application Title</name>
			<priority>0</priority>
			<and_or>and</and_or>
			<search_type>is not</search_type>
			<value>Jamf Connect.app</value>
			<opening_paren>false</opening_paren>
			<closing_paren>false</closing_paren>
		</criterion>
	</criteria>
</computer_group>'
)
resultSG3Code=$( echo "$resultSG3" | awk -F"##" '{ print $2 }' )
	if [[ "$resultSG3Code" == "201" ]]; then
		echo "Smart Group (Demobilize - Jamf Connect not installed) created"
		break
	else
		echo "$resultSG3Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Smart Group (Demobilize - Jamf Connect not installed)"
	fi
	sleep 3
done

echo

## Demobilize - Jamf Connect installed
count="1"
until [[ "$count" -eq 3 ]]; do
resultSG4=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/computergroups/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<computer_group>
	<id>0</id>
	<name>Demobilize - Jamf Connect installed</name>
	<is_smart>true</is_smart>
	<site>
		<id>-1</id>
		<name>None</name>
	</site>
	<criteria>
		<criterion>
			<name>Application Title</name>
			<priority>0</priority>
			<and_or>and</and_or>
			<search_type>is</search_type>
			<value>Jamf Connect.app</value>
			<opening_paren>false</opening_paren>
			<closing_paren>false</closing_paren>
		</criterion>
	</criteria>
</computer_group>'
)
resultSG4Code=$( echo "$resultSG4" | awk -F"##" '{ print $2 }' )
	if [[ "$resultSG4Code" == "201" ]]; then
		echo "Smart Group (Demobilize - Jamf Connect installed) created"
		break
	else
		echo "$resultSG4Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Smart Group (Demobilize - Jamf Connect installed)"
	fi
sleep 3
done

echo

## Create Demobilize - Jamf System Events PPPC configuration profile (required to allow us to request users log out)
count="1"
until [[ "$count" -eq 3 ]]; do
resultPPPC=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/osxconfigurationprofiles/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<os_x_configuration_profile>
<general>
	<id>0</id>
	<name>Demobilize - Jamf System Events PPPC</name>
	<description/>
	<site>
		<id>-1</id>
		<name>None</name>
	</site>
	<category>
		<name>Jamf Connect</name>
	</category>
	<distribution_method>Install Automatically</distribution_method>
	<user_removable>false</user_removable>
	<level>System</level>
	<uuid>75F225AE-83D5-4B93-A18D-7E4126B9C14E</uuid>
	<redeploy_on_update>Newly Assigned</redeploy_on_update>
	<payloads>&lt;?xml version="1.0" encoding="UTF-8"?&gt;&lt;!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"&gt;&lt;plist version="1"&gt;&lt;dict&gt;&lt;key&gt;PayloadUUID&lt;/key&gt;&lt;string&gt;75F225AE-83D5-4B93-A18D-7E4126B9C14E&lt;/string&gt;&lt;key&gt;PayloadType&lt;/key&gt;&lt;string&gt;Configuration&lt;/string&gt;&lt;key&gt;PayloadOrganization&lt;/key&gt;&lt;string&gt;Jamf&lt;/string&gt;&lt;key&gt;PayloadIdentifier&lt;/key&gt;&lt;string&gt;75F225AE-83D5-4B93-A18D-7E4126B9C14E&lt;/string&gt;&lt;key&gt;PayloadDisplayName&lt;/key&gt;&lt;string&gt;Demobilize - Jamf System Events PPPC&lt;/string&gt;&lt;key&gt;PayloadDescription&lt;/key&gt;&lt;string/&gt;&lt;key&gt;PayloadVersion&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;PayloadEnabled&lt;/key&gt;&lt;true/&gt;&lt;key&gt;PayloadRemovalDisallowed&lt;/key&gt;&lt;true/&gt;&lt;key&gt;PayloadScope&lt;/key&gt;&lt;string&gt;System&lt;/string&gt;&lt;key&gt;PayloadContent&lt;/key&gt;&lt;array&gt;&lt;dict&gt;&lt;key&gt;PayloadUUID&lt;/key&gt;&lt;string&gt;00C525C4-99A2-436D-897C-C02BE6374C60&lt;/string&gt;&lt;key&gt;PayloadType&lt;/key&gt;&lt;string&gt;com.apple.TCC.configuration-profile-policy&lt;/string&gt;&lt;key&gt;PayloadOrganization&lt;/key&gt;&lt;string&gt;Jamf&lt;/string&gt;&lt;key&gt;PayloadIdentifier&lt;/key&gt;&lt;string&gt;00C525C4-99A2-436D-897C-C02BE6374C60&lt;/string&gt;&lt;key&gt;PayloadDisplayName&lt;/key&gt;&lt;string&gt;Privacy Preferences Policy Control&lt;/string&gt;&lt;key&gt;PayloadDescription&lt;/key&gt;&lt;string/&gt;&lt;key&gt;PayloadVersion&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;PayloadEnabled&lt;/key&gt;&lt;true/&gt;&lt;key&gt;Services&lt;/key&gt;&lt;dict&gt;&lt;key&gt;AppleEvents&lt;/key&gt;&lt;array&gt;&lt;dict&gt;&lt;key&gt;Identifier&lt;/key&gt;&lt;string&gt;com.jamf.management.service&lt;/string&gt;&lt;key&gt;AEReceiverIdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;CodeRequirement&lt;/key&gt;&lt;string&gt;anchor apple generic and identifier "com.jamf.management.Jamf" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "483DWKW443")&lt;/string&gt;&lt;key&gt;IdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;StaticCode&lt;/key&gt;&lt;integer&gt;0&lt;/integer&gt;&lt;key&gt;AEReceiverIdentifier&lt;/key&gt;&lt;string&gt;com.apple.systemevents&lt;/string&gt;&lt;key&gt;Allowed&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;AEReceiverCodeRequirement&lt;/key&gt;&lt;string&gt;identifier "com.apple.systemevents" and anchor apple&lt;/string&gt;&lt;/dict&gt;&lt;dict&gt;&lt;key&gt;Identifier&lt;/key&gt;&lt;string&gt;com.jamf.management.service&lt;/string&gt;&lt;key&gt;AEReceiverIdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;CodeRequirement&lt;/key&gt;&lt;string&gt;anchor apple generic and identifier "com.jamf.management.Jamf" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "483DWKW443")&lt;/string&gt;&lt;key&gt;IdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;StaticCode&lt;/key&gt;&lt;integer&gt;0&lt;/integer&gt;&lt;key&gt;AEReceiverIdentifier&lt;/key&gt;&lt;string&gt;com.apple.systemuiserver&lt;/string&gt;&lt;key&gt;Allowed&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;AEReceiverCodeRequirement&lt;/key&gt;&lt;string&gt;identifier "com.apple.systemuiserver" and anchor apple&lt;/string&gt;&lt;/dict&gt;&lt;/array&gt;&lt;/dict&gt;&lt;/dict&gt;&lt;/array&gt;&lt;/dict&gt;&lt;/plist&gt;</payloads>
</general>
	<scope>
		<all_computers>false</all_computers>
	</scope>
</os_x_configuration_profile>'
)
resultPPPCCode=$( echo "$resultPPPC" | awk -F"##" '{ print $2 }' )
	if [[ "$resultPPPCCode" == "201" ]]; then
		echo "Demobilize - Jamf System Events PPPC configuration profile created"
		break
	else
		echo "$resultPPPCCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Jamf System Events PPPC configuration profile"
	fi
sleep 3
done

echo

## Create Policy 1
count="1"
until [[ "$count" -eq 3 ]]; do
resultPolicy1=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/policies/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<policy>
	<general>
		<name>Demobilize - Install Jamf Connect</name>
		<enabled>true</enabled>
		<trigger>USER_INITIATED</trigger>
		<frequency>Once per computer</frequency>
		<category>
			<name>Jamf Connect</name>
		</category>
	</general>
	<scope>
		<all_computers>false</all_computers>
		<computer_groups>
			<computer_group>
				<name>Demobilize - Jamf Connect not installed</name>
			</computer_group>
		</computer_groups>
		<exclusions>
			<computer_groups>
				<computer_group>
					<name>Demobilize - No Mobile Accounts</name>
				</computer_group>
			</computer_groups>
		</exclusions>
	</scope>
	<scripts>
		<size>1</size>
		<script>
			<name>Demobilize - Helper</name>
			<priority>After</priority>
		</script>
	</scripts>
	<files_processes>
		<kill_process>false</kill_process>
		<run_command>/usr/local/bin/authchanger -reset -preAuth JamfConnectLogin:DeMobilize,privileged</run_command>
	</files_processes>
	<maintenance>
		<recon>true</recon>
	</maintenance>
	<self_service>
		<use_for_self_service>true</use_for_self_service>
		<self_service_display_name>Jamf Connect</self_service_display_name>
		<install_button_text>Install</install_button_text>
		<self_service_description>*Jamf Connect* is a tool which helps keep your Mac password in sync with your other company passwords. The installation requires you to log out and back in again, please make sure that you have saved your work before proceeding.</self_service_description>
		<force_users_to_view_description>true</force_users_to_view_description>
		<feature_on_main_page>false</feature_on_main_page>
		<self_service_categories>
			<category>
				<name>Jamf Connect</name>
				<display_in>true</display_in>
				<feature_in>false</feature_in>
			</category>
		</self_service_categories>
	</self_service>
</policy>'
)
resultPolicy1Code=$( echo "$resultPolicy1" | awk -F"##" '{ print $2 }' )
	if [[ "$resultPolicy1Code" == "201" ]]; then
		echo "Demobilize - Install Jamf Connect policy created"
		break
	else
		echo "$resultPolicy1Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Install Jamf Connect policy"
	fi
sleep 3
done

echo

## Create Policy 2
count="1"
until [[ "$count" -eq 3 ]]; do
resultPolicy2=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/policies/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<policy>
	<general>
		<name>Demobilize - Inventory update</name>
		<enabled>true</enabled>
		<trigger>EVENT</trigger>
		<trigger_login>true</trigger_login>
		<frequency>Ongoing</frequency>
		<category>
			<name>Jamf Connect</name>
		</category>
	</general>
	<scope>
		<all_computers>false</all_computers>
		<computer_groups>
			<computer_group>
				<name>Demobilize - Jamf Connect installed</name>
			</computer_group>
		</computer_groups>
		<exclusions>
			<computer_groups>
				<computer_group>
					<name>Demobilize - No Mobile Accounts</name>
				</computer_group>
			</computer_groups>
		</exclusions>
	</scope>
	<scripts>
		<size>1</size>
		<script>
			<name>Demobilize - Trigger</name>
			<priority>After</priority>
		</script>
	</scripts>
	<maintenance>
		<recon>true</recon>
	</maintenance>
</policy>'
)
resultPolicy2Code=$( echo "$resultPolicy2" | awk -F"##" '{ print $2 }' )
	if [[ "$resultPolicy2Code" == "201" ]]; then
		echo "Demobilize - Inventory update policy created"
		break
	else
		echo "$resultPolicy2Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Inventory update policy"
	fi
	sleep 3
done

echo

## Policy 3 for demobilize only workflow
demobilizePolicy(){
count="1"
until [[ "$count" -eq 3 ]]; do
resultPolicy3=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/policies/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<policy>
	<general>
		<name>Demobilize - Reset login window</name>
		<enabled>true</enabled>
		<trigger>EVENT</trigger>
		<trigger_other>demobilizeCustomTrigger</trigger_other>
		<frequency>Ongoing</frequency>
		<category>
			<name>Jamf Connect</name>
		</category>
	</general>
	<scope>
		<all_computers>true</all_computers>
	</scope>
	<files_processes>
		<kill_process>false</kill_process>
		<run_command>/usr/local/bin/authchanger -reset</run_command>
	</files_processes>
</policy>'
)
resultPolicy3Code=$( echo "$resultPolicy3" | awk -F"##" '{ print $2 }' )
	if [[ "$resultPolicy3Code" == "201" ]]; then
		echo "Demobilize - Reset login window policy created"
		break
	else
		echo "$resultPolicy3Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Reset login window policy"
	fi
	sleep 3
done
}

## Policy 3 for demobilize and migrate workflow
demobilizeMigratePolicy(){
count="1"
until [[ "$count" -eq 3 ]]; do
resultPolicy3=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/policies/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?>
<policy>
	<general>
		<name>Demobilize - Activate Jamf Connect Login</name>
		<enabled>true</enabled>
		<trigger>EVENT</trigger>
		<trigger_other>demobilizeCustomTrigger</trigger_other>
		<frequency>Ongoing</frequency>
		<category>
			<name>Jamf Connect</name>
		</category>
	</general>
	<scope>
		<all_computers>true</all_computers>
	</scope>
	<scripts>
		<size>1</size>
		<script>
			<name>Demobilize - Migrate</name>
			<priority>After</priority>
		</script>
	</scripts>
</policy>'
)
resultPolicy3Code=$( echo "$resultPolicy3" | awk -F"##" '{ print $2 }' )
	if [[ "$resultPolicy3Code" == "201" ]]; then
		echo "Demobilize - Reset login window policy created"
		break
	else
		echo "$resultPolicy3Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		echo "Error creating Demobilize - Reset login window policy"
	fi
	sleep 3
done
}

## Build the correct policy for the workflow based on earlier user choice
if [[ "$selection" == "1" ]]; then
	demobilizePolicy
	echo
	echo "-------------"
	echo "**NOTE**"
	echo
	echo "Additional setup steps are required"
	echo
	echo 'Scope the configuration profile "Demobilize - Jamf System Events PPPC" to target the Smart Group "Demobilize - Jamf Connect installed"'
	echo "Add JamfConnect.pkg to the policy Demobilize - Install Jamf Connect"
	echo "Add JamfConnectLaunchAgent.pkg to the policy Demobilize - Reset login window"
else
	demobilizeMigratePolicy
	echo
	echo "-------------"
	echo "**NOTE**"
	echo
	echo "Additional setup steps are required"
	echo
	echo 'Scope the configuration profile "Demobilize - Jamf System Events PPPC" to target the Smart Group "Demobilize - Jamf Connect installed"'
	echo "Add JamfConnect.pkg to the policy Demobilize - Install Jamf Connect"
	echo "Add JamfConnectLaunchAgent.pkg to the policy Demobilize - Activate Jamf Connect Login"
fi

echo
echo "-------------"
echo "Done!"
echo "Please review any errors and their associated HTTP status codes"
echo
echo "-------------"
echo "Common HTTP status codes"
echo "400 - Bad request"
echo "401 - Unauthorized (check your API credentials/privileges)"
echo "409 - Conflict (check that the item does not already exist)"
