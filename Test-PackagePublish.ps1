<#
.SYNOPSIS
Check that a package is not already published to a nuget feed.

.DESCRIPTION
Given a package name and version, query the nuget feed to see if that package 
and that version already exist. If the given package already exists on the nuget 
feed, issue a warning or an error. Create log messages for Console use or for 
VSTS build/release use.

.EXAMPLE
Test-PackagePublish -Feed "https://www.myget.org/F/applicationinsights/api/v3/index.json" -PackageName "Microsoft.ApplicationInsights.Web" -PackageVersion "1.0.1-beta3" -WarningStyle VSTS
Check for the existance of package Microsoft.ApplicationInsights.Web.1.0.1-beta3 
and if it does, warn using the VSTS warning format.

.EXAMPLE
Test-PackagePublish -PackageName "Microsoft.ApplicationInsights" -PackageVersion "2.5.0" -WarningStyle Console -WarningsAsErrors
Check if the Microsoft.ApplicationInsights v2.5.0 package is published on the default
nuget feed, and if it is issue an error message to the console.
#>
Param
(
	[Parameter(Mandatory=$true)]
	[string]
	$PackageName,
	[Parameter(Mandatory=$true)]
	[string]
	$PackageVersion,
	[Parameter(Mandatory=$false)]
	[string]
	$Feed="https://www.myget.org/F/applicationinsights/api/v3/index.json",
	[Parameter(Mandatory=$false)]
	[string]
	$NugetPath,
	[Parameter(Mandatory=$false)]
	[ValidateSet("VSTS", "Console")]
	[string]
	$WarningStyle="Console",
	[Parameter(Mandatory=$false)]
	[switch]
	$WarningsAsErrors
)

Write-Verbose "Parameters:"
Write-Verbose "   PackageName : '$PackageName'"
Write-Verbose "   PackageVersion : '$PackageVersion'"
Write-Verbose "   Feed : '$Feed'"
Write-Verbose "   NugetPath: '$NugetPath'"
Write-Verbose "   WarningStyle: $WarningStyle"
Write-Verbose "   Warnings As Errors: $WarningsAsErrors"

if ($NugetPath)
{
	if (Test-Path -Path $NugetPath)
	{
		$nugetExe = $NugetPath
	}	
}

if (-not $nugetExe)
{
	$nugetExe = Get-Command -Name "nuget"
}

$packages = &$nugetExe list $PackageName -Source $Feed -Prerelease -AllVersions

$vstsWarningPrefix = "##vso[task.logissue type=warning;]"
if ($WarningsAsErrors)
{
	$vstsWarningPrefix = "##vso[task.logissue type=error;]"
}


$foundMessage = "Found package $PackageName version $PackageVersion already published on feed $Feed."

$wasFound = $false
$packages | ForEach-Object { 
	$package = $PSItem -split ' '
	if ($package)
	{
		$wasFound = $wasFound -or ($package[0] -match $PackageName -and $package[1] -match $PackageVersion)
	}
}

if ($wasFound)
{
	if ($WarningStyle -ieq "Console")
	{
		if ($WarningsAsErrors)
		{
			Write-Error $foundMessage
		}
		else
		{
			Write-Warning $foundMessage
		}
	}
	else
	{
		Write-Host "$vstsWarningPrefix $foundMessage"
	}
}
else
{
	Write-Host "Package $PackageName version $PackageVersion is not published on feed $Feed."
}
