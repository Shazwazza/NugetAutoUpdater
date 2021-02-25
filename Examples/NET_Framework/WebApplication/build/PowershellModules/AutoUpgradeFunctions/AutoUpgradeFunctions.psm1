function Get-CurrentPackageVersion
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $AccessToken,

        [Parameter(Mandatory)]
        [string] $PackageFile,

        [Parameter(Mandatory)]
        [string] $PackageName
    )

    Add-Type -AssemblyName System.Xml.Linq

    $contentResult = Get-GitHubContent -OwnerName $OwnerName -RepositoryName $RepositoryName -Path $PackageFile -MediaType Raw -AccessToken $AccessToken
    $xmlStream = New-Object System.IO.MemoryStream
    $xmlStream.Write($contentResult, 0, $contentResult.Length)
    $xmlStream.Position = 0
    $reader = New-Object System.Xml.XmlTextReader($xmlStream)
    $xml = [System.Xml.Linq.XDocument]::Load($reader)
    $reader.Dispose()
    $xmlStream.Dispose()

    $xpath = "string(//package[@id='$PackageName']/@version)"
    $packageVersion = [string][System.Xml.XPath.Extensions]::XPathEvaluate($xml, $xpath);    
    
    Write-Verbose "$PackageName version = $packageVersion"

    return $packageVersion.ToString()
}

function Get-PullRequest
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $AccessToken,

        [Parameter(Mandatory)]
        [string] $BranchName
    )

    $pullRequests = Get-GitHubPullRequest -OwnerName $OwnerName -RepositoryName $RepositoryName -AccessToken $AccessToken -Head "$($OwnerName):$($BranchName)"
    return $pullRequests
}

function New-PullRequest
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $AccessToken,

        [Parameter(Mandatory)]
        [string] $SourceVersion,

        [Parameter(Mandatory)]
        [string] $PackageVersion,

        [Parameter(Mandatory)]
        [string] $PackageName,

        [Parameter(Mandatory)]
        [string] $BranchName
    )

    $prParams = @{
        OwnerName = $OwnerName
        RepositoryName = $RepositoryName
        Title = "$PackageName Update from $SourceVersion to $PackageVersion"
        Head = "$($OwnerName):$($BranchName)"
        Base = 'master'
        Body = "$PackageName Update from $SourceVersion to $PackageVersion"
        MaintainerCanModify = $true
        AccessToken = $AccessToken
    }
    $pr = New-GitHubPullRequest @prParams

    return $pr
}

function Get-NugetExe
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $DestinationFolder
    )

    (New-Item -ItemType Directory -Force -Path $DestinationFolder) | Out-Null

    $sourceNugetExe = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
    $nugetExePath = Join-Path $DestinationFolder "nuget.exe"

    if (-not (Test-Path $nugetExePath -PathType Leaf)) 
    {
        Invoke-WebRequest $sourceNugetExe -OutFile $nugetExePath
    }

    return $nugetExePath
}

function Update-NugetPackage
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $PackageName,

        [Parameter(Mandatory)]
        [string] $PackageVersion,

        [Parameter(Mandatory)]
        [string] $ProjectFile,

        [Parameter(Mandatory)]
        [string] $RootGitDirectory,

        [Parameter(Mandatory)]
        [string] $NugetExe,

        [string] $MSBuildPath
    )

    $projFile = Get-Item $ProjectFile
    if ($projFile.Exists -eq $false){
        throw "The project file does not exist $ProjectFile"
    }

    Write-Verbose "Running Nuget restore/update for package $PackageName ..."

    if ($MSBuildPath) {
        $MSBuildPath = "$($MSBuildPath.TrimEnd('\\'))"
    }

    $nugetConfigFile = Find-NugetConfig -CurrentDirectory $($projFile.Directory.FullName) -RootGitDirectory $RootGitDirectory
    $nugetConfigFilePath = $nugetConfigFile.FullName

    # The folder where packages will be downloaded to which by convention is always
    # in the /packages folder relative to the nuget.config file.
    $packagesPath = Join-Path $($nugetConfigFile.Directory.FullName) "packages"

    # First we need to do a nuget restore
    $nugetResult = Restore-Nuget -NugetExe "$NugetExe" -ProjectFile "$projFile" -NugetConfigFile "$nugetConfigFilePath" -PackagesPath "$packagesPath" -MSBuildPath "$MSBuildPath"
    if ($nugetResult -eq $true)
    {
        # Then we can do a nuget update
        Invoke-NugetUpdate -NugetExe "$NugetExe" -PackageName "$PackageName" -PackageVersion $PackageVersion -ProjectFile "$projFile" -NugetConfigFile "$nugetConfigFilePath" -PackagesPath "$packagesPath" -MSBuildPath "$MSBuildPath"
    }
}

function Restore-Nuget
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $NugetExe,

        [Parameter(Mandatory)]
        [string] $ProjectFile,

        [Parameter(Mandatory)]
        [string] $NugetConfigFile,

        [Parameter(Mandatory)]
        [string] $PackagesPath,

        [string] $MSBuildPath
    )

    if ((Get-Item $NugetExe).Exists -eq $false) {
        throw "The Nuget exe file does not exist $NugetExe"
    }  

    Write-Verbose "Running Nuget restore on $ProjectFile with nuget.config $NugetConfigFile and packages path $PackagesPath"

    if ($MSBuildPath) {
        & $NugetExe restore "$ProjectFile" -ConfigFile "$NugetConfigFile" -PackagesDirectory "$PackagesPath" -Project2ProjectTimeOut 20 -NonInteractive -MSBuildPath "$MSBuildPath"
    }
    else {
        & $NugetExe restore "$ProjectFile" -ConfigFile "$NugetConfigFile" -PackagesDirectory "$PackagesPath" -Project2ProjectTimeOut 20 -NonInteractive
    }

    if($LASTEXITCODE -eq 0) {
        return $true
    }
    else {
        throw "An error occurred, quitting"
    }
}

function Invoke-NugetUpdate
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $NugetExe,

        [Parameter(Mandatory)]
        [string] $PackageName,

        [Parameter(Mandatory)]
        [string] $PackageVersion,

        [Parameter(Mandatory)]
        [string] $ProjectFile,

        [Parameter(Mandatory)]
        [string] $NugetConfigFile,

        [Parameter(Mandatory)]
        [string] $PackagesPath,

        [string] $MSBuildPath
    )

    if ((Get-Item $NugetExe).Exists -eq $false) {
        throw "The Nuget exe file does not exist $NugetExe"
    }

    Write-Verbose "Running Nuget update $ProjectFile -ConfigFile $NugetConfigFile -RepositoryPath $PackagesPath -Id $PackageName -FileConflictAction overwrite -NonInteractive -MSBuildPath $MSBuildPath -DependencyVersion Ignore"

    # NOTE: 'overwrite' is not right, but IgnoreAll and Ignore ends up deleting files!@
    # NOTE: -DependencyVersion Ignore is required for some reason, without that we cannot upgrade in many cases, still haven't figured out why

    if ($MSBuildPath) {
        & $NugetExe update "$ProjectFile" -ConfigFile "$NugetConfigFile" -RepositoryPath "$PackagesPath" -Id "$PackageName" -FileConflictAction overwrite -NonInteractive -MSBuildPath "$MSBuildPath" -DependencyVersion "Ignore" -Version $PackageVersion
    }
    else {
        & $NugetExe update "$ProjectFile" -ConfigFile "$NugetConfigFile" -RepositoryPath "$PackagesPath" -Id "$PackageName" -FileConflictAction overwrite -NonInteractive -DependencyVersion "Ignore" -Version $PackageVersion
    }
    
    if($LASTEXITCODE -eq 0) {
        return $true
    }
    else {
        throw "An error occurred, quitting"
    }
}

function Find-NugetConfig
{
   [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $CurrentDirectory,

        [Parameter(Mandatory)]
        [string] $RootGitDirectory
    )

    $folder = Get-Item $CurrentDirectory

    Write-Verbose "Finding Nuget.config, current folder: $CurrentDirectory"

    $nugetConfigFiles = Get-ChildItem -Path $CurrentDirectory -Filter "NuGet.config"

    if ($nugetConfigFiles.Count -eq 0)
    {
        if ($CurrentDirectory.ToLower() -eq $RootGitDirectory.ToLower()) {
            throw "No Nuget.config file found in repository"
        }   

        # move up
        $parent = $folder.Parent;
        if ($parent -eq $null -or $parent.Exists -eq $false){
            throw "No Nuget.config file found on file system"
        }   

        # recurse
        return Find-NugetConfig -CurrentDirectory $parent.FullName -RootGitDirectory $RootGitDirectory
    }

    Write-Verbose "Found nuget config $($nugetConfigFiles[0].FullName)"
    return $nugetConfigFiles[0];
}

function Get-LatestPackageVersion
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $PackageName,

        [Parameter(Mandatory)]
        [string] $NugetExe
    )

    $nugetOutput = & $NugetExe list "PackageId:$PackageName" -NonInteractive | Out-String

    $nugetVersions = $nugetOutput.Split([System.Environment]::NewLine, [StringSplitOptions]::RemoveEmptyEntries)

    $latestVersion = $nugetVersions |
        Where-Object { $_.StartsWith($PackageName) } |
            Sort-Object { ([semver] $_.Split(' ')[1]) } |
                Select-Object -Last 1

    $latestSemver = $latestVersion.Split(' ')[1]

    return $latestSemver
}

function Get-UpgradeAvailable
{
    [CmdletBinding(DefaultParameterSetName = 'None')]
    param(
        [Parameter(Mandatory)]
        [string] $SourceVersion,

        [Parameter(Mandatory)]
        [string] $DestVersion
    )

    $sourceSemver = [semver] $SourceVersion
    $destSemver = [semver] $DestVersion

    return $sourceSemver.CompareTo($destSemver).Equals(-1)
}