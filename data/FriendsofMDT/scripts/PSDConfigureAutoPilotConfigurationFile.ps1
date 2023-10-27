<#
.SYNOPSIS
    Update Autopilot\AutoPilotConfigurationFile.json with MDT/PSD Computername Value.
.DESCRIPTION
    Update gathered information in the task sequence environment.
.LINK
    https://www.bing.com
.NOTES
          FileName: PSDUpdateAutopilotConfigurationFile.ps1
          Solution: PowerShell Deployment for MDT
          Author: Christian Kielhorn
          Contact: @
          Primary: @ 
          Created: 
          Modified: 2020-10-28

          Version - 0.0.0 - () - Finalized functional version 1.
          TODO:

.Example
#>

param (

)

# Load core modules
Import-Module Microsoft.BDD.TaskSequenceModule -Scope Global
Import-Module PSDUtility
Import-Module PSDDeploymentShare

# Check for debug in PowerShell and TSEnv
if($TSEnv:PSDDebug -eq "YES") {
    $Global:PSDDebug = $true
}
if($PSDDebug -eq $true) {
    $verbosePreference = "Continue"
}

Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Load core modules"

# Building source and destionation paths based on model DriverGroup001
$BaseAutoPilotprofilePath = "PSDResources\AutoPilot"

# Building TenantID Variable
$OSDAutoPilotTenant = $TSenv:OSDAutoPilotTenant

# Building the psdAutopilotDir Variable
$psdAutopilotDir = "$($tsenv:OSVolume):\Windows\Provisioning\AutoPilot"

# Building the psdWinDirScriptsDir Variable
$psdWinDirScriptsDir = "$($tsenv:OSVolume):\Windows\Setup\Scripts"

Write-PSDEvent -MessageID 41000 -severity 1 -Message "Starting: $($MyInvocation.MyCommand.Name)"

Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): TS Environment OSDCOMPUTERNAME VARIABLE : $($tsenv:OSDCOMPUTERNAME)"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Check OSDAutoPilotTenant"
Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): TS Environment OSDAutoPilotTenant VARIABLE : $($TSenv:OSDAutoPilotTenant)"

if(Test-PSDContent -content $BaseAutoPilotprofilePath -NE $null){

    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): $BaseAutoPilotprofilePath found"

    #Copy AutoPilot Configuration File to cache
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy $BaseAutoPilotprofilePath to cache "
    Show-PSDActionProgress -Message "Trying to download AutoPilot Config Files : $($BaseAutoPilotprofilePath | Split-Path -Leaf)" -Step "1" -MaxStep "1"
    Get-PSDContent -content $BaseAutoPilotprofilePath

	#Get all JSON files from the cache
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Get all .JSON Files..."
    $AutopilotConfigFiles = Get-ChildItem -Path "$($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot" -Filter *.json -Recurse
	$SetupCompleteFile = Get-children -Path "$($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot" -Filter *.cmd -Recurse
    #Did we find any?
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Found $($AutopilotConfigFiles.count) packages"
    Show-PSDActionProgress -Message "Found $($AutopilotConfigFiles.count) packages" -Step "1" -MaxStep "1"

    Start-Sleep -Seconds 1

	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Check AutoPilot directory: $($tsenv:OSVolume):\Windows\Provisioning\AutoPilot..."
	if ((Test-Path $psdAutopilotDir) -ne $true) {
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): no directory found: $($psdAutopilotDir), creating."
		Start PowerShell -ArgumentList "New-Item -Path $($psdAutopilotDir) -ItemType Directory"
	}

    Foreach($AutopilotConfigFile in $AutopilotConfigFiles){
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Compare to Pre-defined Tenant $($AutopilotConfigFile)" #technology-factory.json
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Checked Directory      :  $($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot\$($AutopilotConfigFile)"
	
		$test_TestpathVariable = "$($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot\$($TSenv:OSDAutoPilotTenant).json"
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name):  Checked Directory 2nd :  $($test_TestpathVariable)"
		
		#either the TenantID matched the existing autopilot Profile path or we do have to join to a default JSON (or do not copy something)
		if ((Test-Path $test_TestpathVariable -PathType Leaf) -eq $true){
			Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Test-Path for          :  $($AutopilotConfigFile)"
			Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): OSDAutoPilotTenant     :  $($TSenv:OSDAutoPilotTenant).json"
			Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy From              :  $test_TestpathVariable"
			Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy To                :  $($tsenv:OSVolume):\Windows\Provisioning\AutoPilot\AutoPilotConfigurationFile.json"
			
			Copy-Item -Path $test_TestpathVariable -Destination "$($tsenv:OSVolume):\Windows\Provisioning\AutoPilot\AutoPilotConfigurationFile.json"
			Start-Sleep -Seconds 1
		} else{
#            Copy-Item -Path "$($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot\AutoPilotConfigurationFile.json" -DestinationPath "$($tsenv:OSVolume):\Windows\Provisioning\AutoPilot\AutoPilotConfigurationFile.json" -Force
			#there is neither an Configfile based on Tenant domain nor an Configfile based on a default AutoPilotConfigurationFile
			Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): - no File needed / found"
		}
    }
 }
 
if ($tsenv:OSDCOMPUTERNAME -ne ""){

    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): TS Environment OSDCOMPUTERNAME VARIABLE - not null - hopefully"
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Make sure we are able to access to the AutoPilotConfig File Directory"

	# $($tsenv:OSVolume):\Windows\Provisioning\AutoPilot\AutoPilotConfigurationFile.json
	# Read the current config
	# Load the Autopilot\AutoPilotConfigurationFile.json
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Load the AutoPilotConfigurationFile.json"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Try to read Content from pre-defined AutoPilotConfigurationFile"
	$config = Get-Content "$($tsenv:OSVolume):\Windows\Provisioning\AutoPilot\AutopilotConfigurationFile.json" | ConvertFrom-Json

	# Get the computer name
	$computerName = $tsenv:OSDCOMPUTERNAME

	# Get the Tenant Information from the Autopilot Config File
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): CloudAssignedTenantDomain : $($config.CloudAssignedTenantDomain)"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): CloudAssignedTenantId     : $($config.CloudAssignedTenantId)"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): CloudAssignedDeviceName   : $($config.CloudAssignedDeviceName)"

	if ($config.CloudAssignedDeviceName){
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Assuming that CloudAssignedDeviceName is not empty, we have to overwrite, because we defined a computername manually"
		# Update the computer name
		# Add-Member : Cannot add a member with the name "CloudAssignedDeviceName" because a member with that name already exists. To overwrite the member anyway, add the Force parameter to your command.
		$config | Add-Member "CloudAssignedDeviceName" $computerName -Force
	} else {
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Assuming that CloudAssignedDeviceName is empty, we have to write, because we defined a computername manually"
		# Add the computer name
		$config | Add-Member "CloudAssignedDeviceName" $computerName
	}
	
	# Write the updated file
	# Destination: %OSDisk%\Windows\provisioning\AutoPilot\

	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Let's re-build the Destination Path for Autopilot Config:"
	$Destinationpath = "$($tsenv:OSVolume):\Windows\provisioning\AutoPilot\"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Directory : $($Destinationpath)"

	$config | ConvertTo-JSON | Set-Content -Path "$($tsenv:OSVolume):\Windows\Provisioning\AutoPilot\AutopilotConfigurationFile.json" -Force
	
	#unattend.xml is not needed anymore - we will delete it
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): unattend.xml : will be deleted"
	
    Start PowerShell -ArgumentList "remove-item -Path ""$($tsenv:OSVolume):\Windows\Panther\unattend.xml"" -force -erroraction silentlycontinue"
	
    Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): unattend.xml : Deletion successful"

	# Replace the existing Setupcomplete to one, that will match a lot
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): SetupComplete.cmd      :  will be replaced"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Test-Path for          :  $($psdWinDirScriptsDir)"

	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Check Scripts directory: $($psdWinDirScriptsDir)..."
	if ((Test-Path $psdWinDirScriptsDir) -ne $true) {
		Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): no directory found: $($psdWinDirScriptsDir), creating."
		Start PowerShell -ArgumentList "New-Item -Path $($psdWinDirScriptsDir) -ItemType Directory"
	}
	
	$test_psdWinDirScripts_variable = "$($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot\SetupComplete.cmd"
	
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): SetupComplete.cmd      :  will be replaced"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Test-Path for          :  $($psdWinDirScriptsDir)"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy From              :  $($tsenv:OSVolume):\MININT\Cache\PSDResources\Autopilot\"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy To                :  $($tsenv:OSVolume):\Windows\Setup\Scripts\"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Copy PATH              :  $test_psdWinDirScripts_variable"
	
	Start PowerShell -ArgumentList "copy-item -Path $test_psdWinDirScripts_variable -Destination $($tsenv:OSVolume):\Windows\Setup\Scripts\ -force"
	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): SetupComplete.cmd : Replacement successful"
	
} else {

	Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): No computername defined : lets use the default Configuration from the JSON / Autopilot Profile"

}

# Save all the current variables for later use
#Write-PSDLog -Message "$($MyInvocation.MyCommand.Name): Save all the current variables for later use"
#Save-PSDVariables