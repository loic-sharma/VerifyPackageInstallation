. (Join-Path $PSScriptRoot "common.ps1")

# Run test cases
# ==============
$envName = Get-EnvName
$configs = Get-Configs
$source = Get-PackageSource $configs

if ($IsWindows -eq $false) {
  throw "This script must be run on Windows"
}

Remove-PreviousTestItems

$configs.NuGetClients | % {
  $clientName = $_
  $nugetexe = "./tools/$clientName.exe"

  @($true, $false) | % {
    $addTrustedSigners = $_

    $source.Packages | % {
      Test-NuGetExe `
        -TestName "windows-$envName-$clientName" `
        -NugetExe $nugetexe `
        -PackageSource $source.PackageSource `
        -AddTrustedSigners $addTrustedSigners `
        -SupportsVerifyCommand $true `
        -Id $_.PackageId `
        -Version $_.PackageVersion
    }
  }
}

$configs.DotnetClients | % {
  $clientName = $_.Name
  $sdkVersion = $_.Version

  @($true, $false) | % {
    $addTrustedSigners = $_

    $source.Packages | % {
      Test-DotnetCli `
        -TestName "windows-$envName-$clientName" `
        -SdkVersion $sdkVersion `
        -PackageSource $source.PackageSource `
        -AddTrustedSigners $addTrustedSigners `
        -SupportsVerifyCommand ($clientName -ne "dotnet31") `
        -Id $_.PackageId `
        -Version $_.PackageVersion
    }
  }
}