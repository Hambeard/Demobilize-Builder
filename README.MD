<h1>Jamf Connect demobilization and/or migration workflow builder</h1>

The following guide is designed to accompany the Jamf Connect demobilize workflow builder script. Please run this script prior to following the steps in this guide. There are two workflows detailed here, Demobilize only and Demobilize & migrate. If you would prefer the standard macOS login screen use Demobilize only. Otherwise if you wish to use the Jamf Connect Login window, use the Demobilize & migrate workflow.

The workflows were designed with single-user deployments in mind. They should work for shared deployments, however testing has been limited.

You will need upload the JamfConnect.pkg & JamfConnectLaunchAgent.pkg packages to your Jamf Pro server prior to this workflow. You will also need to have configured your IdP settings for Jamf Connect and made them available for distribution as a configuration profile in Jamf Pro. For each workflow, you will need to include the following keys.

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


<h1>Policy 1</h1>

<h3>Payloads</h3>

---

**General**<br />
**Name:** Demobilize - Install Jamf Connect<br />
**Category:** Jamf Connect<br />
**Trigger:** None<br />
**Frequency:** Once per computer

**Packages**
**Package:** JamfConnect.pkg<br />
**Action:** Install

**Scripts**<br />
**Script:** Demobilize - Helper<br />
**Priority:** After

**Files & Processes**<br />
**Execute Command:** /usr/local/bin/authchanger -reset -preAuth JamfConnectLogin:DeMobilize,privileged

<h3>Scope</h3>

---

**Targets:** Demobilize - Jamf Connect not installed<br />
**Exclusions:** Demobilize - No Mobile Accounts

<h3>Self Service</h3>

---

**Self Service Display Name:** Jamf Connect<br />
**Button Name:** Install<br />
**Description:** *Jamf Connect* is a tool which helps keep your Mac password in sync with your other company passwords. The installation requires you to log out and back in again, please make sure that you have saved your work before proceeding.<br />
**Ensure that users view the description:** Checked<br />
**Icon:** It is highly recommended that you add an icon for the policy, the Jamf Connect icon is included for convenience.

<h1>Policy 2</h1>

<h3>Payloads</h3>

---

**General**<br />
**Name:** Demobilize - Inventory update<br />
**Category:** Jamf Connect<br />
**Trigger:** Login<br />
**Frequency:** Ongoing

**Scripts**<br />
**Script:** Demobilize - Trigger<br />
**Priority:** After<br />

**Maintenance**<br />
**Update Inventory:** Checked

<h3>Scope</h3>

---

**Targets:** Demobilize - Jamf Connect installed<br />
**Exclusions:** Demobilize - No Mobile Accounts


<h1>Policy 3 (Demobilize only)</h1>

**Payloads**

**General**<br />
**Name:** Demobilize - Reset login window<br />
**Category:** Jamf Connect<br />
**Trigger:** Custom<br />
**Custom Event:** demobilizeCustomTrigger (or custom value if set in Demobilize - Trigger parameter 4)<br />
**Frequency:** Once per computer

**Packages**<br />
**Package:** JamfConnectLaunchAgent.pkg<br />
**Action:** Install

**Files & Processes**<br />
**Execute Command:** /usr/local/bin/authchanger -reset

<h3>Scope</h3>

---

**Targets:** All Computers

<h2>Policy 3 (Demobilize & migrate)</h2>

**Payloads**

---

**General**
**Name:** Demobilize - Activate Jamf Connect Login
**Category:** Jamf Connect
**Trigger:** Recurring Check-in
**Custom Event:** demobilizeCustomTrigger
**Frequency:** Once per computer

**Packages**
**Package:** JamfConnectLaunchAgent.pkg
**Action:** Install

**Scripts**
**Script:** Demobilize - Migrate
**Priority:** After

**Scope**

---

Targets: All Computers


<h2>Appendix</h2>

**Settings changed in Jamf Pro**

Login hooks enabled<br />
Check for policies at login enabled

**Objects created in Jamf Pro**

Jamf Connect Category<br />
Mobile Accounts Computer Extension Attribute

Demobilize - Helper script<br />
Demobilize - Trigger script<br />
Demobilize - Migrate script<br />
Demobilize - No Mobile Accounts Smart Group<br />
Demobilize - Mobile Accounts Smart Group<br />
Demobilize - Jamf Connect not installed Smart Group<br />
Demobilize - Jamf Connect installed Smart Group<br />
Demobilize - Jamf System Events PPPC Configuration Profile<br />