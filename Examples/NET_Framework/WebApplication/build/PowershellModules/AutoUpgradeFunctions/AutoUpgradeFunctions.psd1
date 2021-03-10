#
# Module manifest for module 'AutoUpgradeFunctions'
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'AutoUpgradeFunctions.psm1'

# Version number of this module.
ModuleVersion = '0.0.2'

# ID used to uniquely identify this module
GUID = '161d1d14-5c12-402a-96c9-52b12d440f81'

# Author of this module
Author = 'Shannon Deminick'

# Company or vendor of this module
CompanyName = 'SDKits'

# Copyright statement for this module
Copyright = '(c) Shannon Deminick. All rights reserved.'

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
   "Get-CurrentPackageVersion",
   "Get-ConfigPackageVersion",
   "Get-PullRequest",
   "New-PullRequest",
   "Get-NugetExe",
   "Update-NugetPackage",
   "Get-LatestPackageVersion",
   "Get-UpgradeAvailable")

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{ } # End of PSData hashtable

} 
}
