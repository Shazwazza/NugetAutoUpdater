# Nuget Auto Updater

This GitHub Action is used to auto update your Nuget packages for **.NET Framework projects**. Typically this would be used on a schedule job.

For non .NET Framework project, GitHub's [Dependabot](https://github.blog/2020-06-01-keep-all-your-packages-up-to-date-with-dependabot/) is probably the easiest way. Dependabot does not work well for .NET Framework projects because it doesn't actually run the nuget installer against your project so your csproj doesn't get updated with new references. 

## Status

__Beta (unpublished)__

_Currently only supporting .NET Framework projects (.csproj) with packages.config_

## Usage

```yml
name: AutoUpgradeNugetPackages

on:
  workflow_dispatch:
  schedule:
  - cron: '0 0 * * *'     # Every day at 00:00 UTC

jobs:
  build:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v2

    - name: Add MSBuild to PATH
      uses: microsoft/setup-msbuild@v1 # Required for NugetAutoUpgrade

    - name: Nuget Auto Upgrade
      uses: Shazwazza/NugetAutoUpgrade@v1
      with:
        github-token: ${{ secrets.GITHUB_TOKEN }}
        project-file: "src/Shazwazza.Web/Shazwazza.Web.csproj"
        package-file: "src/Shazwazza.Web/packages.config"
        package-name: UmbracoCms
        git-bot-user: "Friendly Upgrade Bot"
        git-bot-email: "upgrader@example.com"
        disable-upgrade-step: false     # Used for testing
        disable-commit: false           # Used for testing
        disable-push: false             # Used for testing
        disable-pull-request: false     # Used for testing
        verbose: false                  # Used for testing
```

## TODO

* Come up with a better name
* Entire solutions (.sln)
* .NET Framework projects with Package Reference

## Known issues

Nuget packages that rely on legacy Nuget PowerShell scripts (i.e. install.ps1) may not work correctly because the PowerShell scripts do not execute. This functionality is embedded into Visual Studio and not Nuget itself. The plan is to partially support this feature but it may never work perfectly.

## Additional scripts

This repository also contains scripts that can be used manually in your build configurations too and can be used for GitHub actions and Azure Pipelines.

See blog post for full details: https://shazwazza.com/post/auto-upgrade-your-nuget-packages-for-net-projects-with-azure-pipelines/

### Working

* .NET Framework projects (.csproj) with packages.config with Azure Pipelines
* .NET Framework projects (.csproj) with packages.config with GitHub Actions

### Installation and using

* The files and folder structure should be used as-is from this location at the root of your Git repository: https://github.com/Shazwazza/NugetAutoUpgrade/tree/main/Examples/NET_Framework/WebApplication
* Follow guide here: https://shazwazza.com/post/auto-upgrade-your-nuget-packages-for-net-projects-with-azure-pipelines/
