#!/bin/bash
###############################################################################

## Tested on macOS Big Sur & Jamf Pro 10.30.3

echo "What is your Jamf Pro URL? (include https://)"
read -r jssURL

echo
echo "Please enter your Jamf Pro username?"
read -r apiUser

echo
echo "Please enter your Jamf Pro password?"
read -rs apiPass
echo
echo "Script status message: HTTP status code"
echo "-------------"

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
		echo "Error enabling Login hooks: $resultHooksCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error enabling Check for policies at login: $resultCheckLoginCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error creating Jamf Connect category: $resultCatCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error creating Extension Attribute: $resultEACode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
	fi
	sleep 3
done

echo

## Create Demobilize - Helper.sh
if [[ ! -f "$scriptPath/Demobilize - Helper.sh" ]]; then
	echo "Error: Demobilize - Helper.sh not found"
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
		echo "Error creating Demobilize - Helper script: $resultScriptCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
	fi
sleep 3
done
fi

echo

## Create Demobilize - Trigger.sh
if [[ ! -f "$scriptPath/Demobilize - Trigger.sh" ]]; then
	echo "Error: Demobilize - Trigger.sh not found"
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
		echo "Error creating Demobilize - Trigger script: $resultScript2Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
	fi
sleep 3
done
fi

echo

## Create Demobilize - Helper.sh
if [[ ! -f "$scriptPath/Demobilize - Migrate.sh" ]]; then
	echo "Error: Demobilize - Migrate.sh not found"
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
		echo "Error creating Demobilize - Migrate script: $resultScript3Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error creating Smart Group (Demobilize - No Mobile Accounts): $resultSG1Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error creating Smart Group (Demobilize - Mobile Accounts): $resultSG2Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error creating Smart Group (Demobilize - Jamf Connect not installed): $resultSG3Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
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
		echo "Error creating Smart Group (Demobilize - Jamf Connect installed): $resultSG4Code"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
	fi
sleep 3
done

echo

## Check for Jamf Connect category ID
categoryID=$( curl -H "Accept: application/xml" -w "##%{http_code}\n" -sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/categories/name/Jamf Connect" )
categoryIDXML=$( echo "$categoryID" | awk -F"##" '{ print $1 }' | xmllint --format - 2>/dev/null | awk -F'>|<' '/<id>/{print $3}' )
categoryIDHTTP=$( echo "$categoryID" | awk -F"##" '{ print $2 }' )
if [[ "$categoryIDHTTP" != "200" ]]; then
	echo "Error: Error checking for Jamf Connect category ID: $categoryIDHTTP"
fi

## Create Demobilize - Jamf System Events PPPC configuration profile (required to allow us to request users log out)
count="1"
until [[ "$count" -eq 3 ]]; do
resultPPPC=$( curl -H "Content-Type: application/xml" \
-sfu "${apiUser}:${apiPass}" "${jssURL}JSSResource/osxconfigurationprofiles/id/0" \
-X POST \
-w "##%{http_code}" \
-d '<?xml version="1.0" encoding="UTF-8"?><os_x_configuration_profile><general><id>0</id><name>Demobilize - Jamf System Events PPPC</name><description/><site><id>-1</id><name>None</name></site><category><id>'"$categoryIDXML"'</id><name>Jamf Connect</name></category><distribution_method>Install Automatically</distribution_method><user_removable>false</user_removable><level>System</level><uuid>75F225AE-83D5-4B93-A18D-7E4126B9C14E</uuid><redeploy_on_update>Newly Assigned</redeploy_on_update><payloads>&lt;?xml version="1.0" encoding="UTF-8"?&gt;&lt;!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"&gt;
&lt;plist version="1"&gt;&lt;dict&gt;&lt;key&gt;PayloadUUID&lt;/key&gt;&lt;string&gt;75F225AE-83D5-4B93-A18D-7E4126B9C14E&lt;/string&gt;&lt;key&gt;PayloadType&lt;/key&gt;&lt;string&gt;Configuration&lt;/string&gt;&lt;key&gt;PayloadOrganization&lt;/key&gt;&lt;string&gt;Jamf&lt;/string&gt;&lt;key&gt;PayloadIdentifier&lt;/key&gt;&lt;string&gt;75F225AE-83D5-4B93-A18D-7E4126B9C14E&lt;/string&gt;&lt;key&gt;PayloadDisplayName&lt;/key&gt;&lt;string&gt;Demobilize - Jamf System Events PPPC&lt;/string&gt;&lt;key&gt;PayloadDescription&lt;/key&gt;&lt;string/&gt;&lt;key&gt;PayloadVersion&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;PayloadEnabled&lt;/key&gt;&lt;true/&gt;&lt;key&gt;PayloadRemovalDisallowed&lt;/key&gt;&lt;true/&gt;&lt;key&gt;PayloadScope&lt;/key&gt;&lt;string&gt;System&lt;/string&gt;&lt;key&gt;PayloadContent&lt;/key&gt;&lt;array&gt;&lt;dict&gt;&lt;key&gt;PayloadUUID&lt;/key&gt;&lt;string&gt;00C525C4-99A2-436D-897C-C02BE6374C60&lt;/string&gt;&lt;key&gt;PayloadType&lt;/key&gt;&lt;string&gt;com.apple.TCC.configuration-profile-policy&lt;/string&gt;&lt;key&gt;PayloadOrganization&lt;/key&gt;&lt;string&gt;Jamf&lt;/string&gt;&lt;key&gt;PayloadIdentifier&lt;/key&gt;&lt;string&gt;00C525C4-99A2-436D-897C-C02BE6374C60&lt;/string&gt;&lt;key&gt;PayloadDisplayName&lt;/key&gt;&lt;string&gt;Privacy Preferences Policy Control&lt;/string&gt;&lt;key&gt;PayloadDescription&lt;/key&gt;&lt;string/&gt;&lt;key&gt;PayloadVersion&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;PayloadEnabled&lt;/key&gt;&lt;true/&gt;&lt;key&gt;Services&lt;/key&gt;&lt;dict&gt;&lt;key&gt;AppleEvents&lt;/key&gt;&lt;array&gt;&lt;dict&gt;&lt;key&gt;Identifier&lt;/key&gt;&lt;string&gt;com.jamf.management.service&lt;/string&gt;&lt;key&gt;AEReceiverIdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;CodeRequirement&lt;/key&gt;&lt;string&gt;anchor apple generic and identifier "com.jamf.management.Jamf" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "483DWKW443")&lt;/string&gt;&lt;key&gt;IdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;StaticCode&lt;/key&gt;&lt;integer&gt;0&lt;/integer&gt;&lt;key&gt;AEReceiverIdentifier&lt;/key&gt;&lt;string&gt;com.apple.systemevents&lt;/string&gt;&lt;key&gt;Allowed&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;AEReceiverCodeRequirement&lt;/key&gt;&lt;string&gt;identifier "com.apple.systemevents" and anchor apple&lt;/string&gt;&lt;/dict&gt;&lt;dict&gt;&lt;key&gt;Identifier&lt;/key&gt;&lt;string&gt;com.jamf.management.service&lt;/string&gt;&lt;key&gt;AEReceiverIdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;CodeRequirement&lt;/key&gt;&lt;string&gt;anchor apple generic and identifier "com.jamf.management.Jamf" and (certificate leaf[field.1.2.840.113635.100.6.1.9] /* exists */ or certificate 1[field.1.2.840.113635.100.6.2.6] /* exists */ and certificate leaf[field.1.2.840.113635.100.6.1.13] /* exists */ and certificate leaf[subject.OU] = "483DWKW443")&lt;/string&gt;&lt;key&gt;IdentifierType&lt;/key&gt;&lt;string&gt;bundleID&lt;/string&gt;&lt;key&gt;StaticCode&lt;/key&gt;&lt;integer&gt;0&lt;/integer&gt;&lt;key&gt;AEReceiverIdentifier&lt;/key&gt;&lt;string&gt;com.apple.systemuiserver&lt;/string&gt;&lt;key&gt;Allowed&lt;/key&gt;&lt;integer&gt;1&lt;/integer&gt;&lt;key&gt;AEReceiverCodeRequirement&lt;/key&gt;&lt;string&gt;identifier "com.apple.systemuiserver" and anchor apple&lt;/string&gt;&lt;/dict&gt;&lt;/array&gt;&lt;/dict&gt;&lt;/dict&gt;&lt;/array&gt;&lt;/dict&gt;&lt;/plist&gt;</payloads></general><scope><all_computers>true</all_computers><all_jss_users>false</all_jss_users><computers/><buildings/><departments/><computer_groups/><jss_users/><jss_user_groups/><limitations><users/><user_groups/><network_segments/><ibeacons/></limitations><exclusions><computers/><buildings/><departments/><computer_groups/><users/><user_groups/><network_segments/><ibeacons/><jss_users/><jss_user_groups/></exclusions></scope><self_service><self_service_display_name>Jamf System Events PPPC</self_service_display_name><install_button_text>Install</install_button_text><self_service_description/><force_users_to_view_description>false</force_users_to_view_description><security><removal_disallowed>Never</removal_disallowed></security><self_service_icon/><feature_on_main_page>false</feature_on_main_page><self_service_categories><category><id>14</id><name>Jamf Connect</name><display_in>true</display_in><feature_in>false</feature_in></category></self_service_categories><notification>false</notification><notification>Self Service</notification><notification_subject/><notification_message/></self_service></os_x_configuration_profile>'
)
resultPPPCCode=$( echo "$resultPPPC" | awk -F"##" '{ print $2 }' )
	if [[ "$resultPPPCCode" == "201" ]]; then
		echo "Demobilize - Jamf System Events PPPC configuration profile created"
		break
	else
		echo "Error creating Demobilize - Jamf System Events PPPC configuration profile: $resultPPPCCode"
		(( count++ ))
	fi
	if [[ "$count" -eq 3 ]]; then
		countSub=$(( count -1 ))
		echo "Error: Giving up after $countSub attempts"
	fi
sleep 3
done

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
