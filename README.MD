<h1>Jamf Connect demobilization and/or migration workflow builder</h1>


* Prepare your Jamf Connect Login and Jamf Connect Menu Bar settings configuration profiles
* Upload JamfConnect.pkg and JamfConnectLaunchAgent.pkg to your distribution point
* Download the entire repo to your Mac (Code > Download ZIP)
* Run from the command line e.g. `sh /PATH/TO/SCRIPT`<br />
	* Make sure the entire repo is intact, the build script needs the other scripts present to work correctly<br />
	* Make sure that terminal has TCC access to the location you are running the build script from
* After the workflow is built in Jamf Pro
	* Customize the script parameter values in the policy Demobilize - Install Jamf Connect if desired
	* Add JamfConnect.pkg to the policy Demobilize - Install Jamf Connect
	* Add JamfConnectLaunchAgent.pkg to the policy Demobilize - Reset login window or 
	Demobilize - Activate Jamf Connect Login depending on your chosen workflow
	* Scope the configuration profile "Demobilize - Jamf System Events PPPC" to target the Smart Group "Demobilize - Jamf Connect installed"
* Test!

There are two workflows detailed here, Demobilize only and Demobilize & migrate. If you would prefer the standard macOS login screen use Demobilize only. Otherwise if you wish to use the Jamf Connect Login window, use the Demobilize & migrate workflow.

You will also need to have configured your IdP settings for Jamf Connect and made them available for distribution as a configuration profile in Jamf Pro. For each workflow, you will need to include the following keys in your Jamf Connect Login settings.

<h2>Demobilize only</h2>

```xml
<key>DemobilizeUsers</key>
	<true/>
```

<h2>Demobilize & migrate</h2>

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


<h1>Appendix</h1>

**Objects & settings created/modified in Jamf Pro**<br />

Settings
* Login hooks enabled<br />
* Check for policies at login enabled

Categories
* Jamf Connect Category

Extension Attributes
* Mobile Accounts Computer Extension Attribute

Scripts
* Demobilize - Helper script
* Demobilize - Trigger script
* Demobilize - Migrate script

Smart Groups
* Demobilize - No Mobile Accounts Smart Group
* Demobilize - Mobile Accounts Smart Group
* Demobilize - Jamf Connect not installed Smart Group
* Demobilize - Jamf Connect installed Smart Group

Configuration profiles
* Demobilize - Jamf System Events PPPC Configuration Profile

Policies
* Demobilize - Install Jamf Connect
* Demobilize - Inventory update
* Demobilize - Reset login window
* Demobilize - Activate Jamf Connect Login

