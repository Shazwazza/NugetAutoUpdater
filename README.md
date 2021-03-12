# Nuget Auto Upgrade

This GitHub Action is used to auto upgrade your Nuget packages for .NET projects. Typically this would be used on a schedule job.

_Currently only supporting .NET Framework projects (.csproj) with packagse.config_

See blog post for full details: https://shazwazza.com/post/auto-upgrade-your-nuget-packages-for-net-projects-with-azure-pipelines/

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
```

## TODO

* Come up with a better name
* Entire solutions (.sln)
* .NET Core/5 projects
* .NET Framework projects with Package Reference

## Additional scripts

This repository also contains scripts that can be used manually in your build configurations too and can be used for GitHub actions and Azure Pipelines.

### Working

* .NET Framework projects (.csproj) with packages.config with Azure Pipelines
* .NET Framework projects (.csproj) with packages.config with GitHub Actions

### Installation and using

* The files and folder structure should be used as-is from this location at the root of your Git repository: https://github.com/Shazwazza/NugetAutoUpgrade/tree/main/Examples/NET_Framework/WebApplication
* Follow guide here: https://shazwazza.com/post/auto-upgrade-your-nuget-packages-for-net-projects-with-azure-pipelines/
