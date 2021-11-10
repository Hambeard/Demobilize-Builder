<h1>Jamf Connect demobilization and/or migration workflow builder</h1>

The following guide is designed to accompany the Jamf Connect demobilize workflow builder script. Please run this script prior to following the steps in this guide. There are two workflows detailed here, Demobilize only and Demobilize & migrate. If you would prefer the standard macOS login screen use Demobilize only. Otherwise if you wish to use the Jamf Connect Login window, use the Demobilize & migrate workflow.

The workflows were designed with single-user deployments in mind. They should work for shared deployments, however testing has been limited.

You will need upload the JamfConnect.pkg & JamfConnectLaunchAgent.pkg packages to your Jamf Pro server prior to this workflow. You will also need to have configured your IdP settings for Jamf Connect and made them available for distribution as a configuration profile in Jamf Pro. For each workflow, you will need to include the following keys.

<h3>Demobilize only</h3>
---------------
```xml
<key>DemobilizeUsers</key>
	<true/>
```

<h3>Demobilize & migrate</h3>
--------------------
```xml
<key>DemobilizeUsers</key>
	<true/>
<key>Migrate</key>
	<true/>
<key>MigrateUsersHide</key>
	<array>
		<string>NAMEOFLOCALADMIN1</string>
		<string>NAMEOFLOCALADMIN2</string>
	</array>
<key>DenyLocal</key>
	<true/>
<key>DenyLocalExcluded</key>
	<array>
		<string>NAMEOFLOCALADMIN1</string>
		<string>NAMEOFLOCALADMIN2</string>
	</array>
<key>LocalFallback</key>
	<true/>
```

If you wish to use Jamf Connect Login on a continuing basis please use Policy 3 (demobilize & migrate) instead of Policy 3 (demobilize). If you are only looking to demobilize and do not wish to use Jamf Connect Login please use Policy 3 (demobilize).

Policy 1
--------

Payloads

General
Name: Demobilize - Install Jamf Connect
Category: Jamf Connect
Trigger: None
Frequency: Once per computer

Packages
Package: JamfConnect.pkg
Action: Install

Scripts
Script: Demobilize - Helper
Priority: After

Files & Processes
Execute Command: /usr/local/bin/authchanger -reset -preAuth JamfConnectLogin:DeMobilize,privileged

Scope
-----
Targets: Demobilize - Jamf Connect not installed
Exclusions: Demobilize - No Mobile Accounts

Self Service
------------
Self Service Display Name: Jamf Connect
Button Name: Install
Description: *Jamf Connect* is a tool which helps keep your Mac password in sync with your other company passwords. The installation requires you to log out and back in again, please make sure that you have saved your work before proceeding.
Ensure that users view the description: Checked
Icon: It is highly recommended that you add an icon for the policy, the Jamf Connect icon is included for convenience.

########
Policy 2

Payloads
--------
General
Name: Demobilize - Inventory update
Category: Jamf Connect
Trigger: Login
Frequency: Ongoing

Scripts
Script: Demobilize - Trigger
Priority: After

Maintenance
Update Inventory: Checked

Scope
-----
Targets: Demobilize - Jamf Connect installed
Exclusions: Demobilize - No Mobile Accounts

##########################
Policy 3 (Demobilize only)

Payloads
--------
General
Name: Demobilize - Reset login window
Category: Jamf Connect
Trigger: Custom
Custom Event: demobilizeCustomTrigger (or custom value if set in Demobilize - Trigger parameter 4)
Frequency: Once per computer

Packages
Package: JamfConnectLaunchAgent.pkg
Action: Install

Files & Processes
Execute Command: /usr/local/bin/authchanger -reset

Scope
-----
Targets: All Computers

###############################
Policy 3 (Demobilize & migrate)

Payloads
--------
General
Name: Demobilize - Activate Jamf Connect Login
Category: Jamf Connect
Trigger: Recurring Check-in
Custom Event: demobilizeCustomTrigger
Frequency: Once per computer

Packages
Package: JamfConnectLaunchAgent.pkg
Action: Install

Scripts
Script: Demobilize - Migrate
Priority: After

Scope
-----
Targets: All Computers


########
Appendix

Settings changed in Jamf Pro
----------------------------
Login hooks enabled
Check for policies at login enabled

Objects created in Jamf Pro
---------------------------
Jamf Connect Category
Mobile Accounts Computer Extension Attribute
Demobilize - Helper script
Demobilize - Trigger script
Demobilize - Migrate script
Demobilize - No Mobile Accounts Smart Group
Demobilize - Mobile Accounts Smart Group
Demobilize - Jamf Connect not installed Smart Group
Demobilize - Jamf Connect installed Smart Group
Demobilize - Jamf System Events PPPC Configuration Profile