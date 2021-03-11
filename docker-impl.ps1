param (
  $ClientName
)
. (Join-Path $PSScriptRoot "common.ps1")


# Run test cases
# ==============
$envName = "DEV"
$configs = Get-Configs
$source = $configs.Sources.DEV

if ($env:DOTNET_RUNNING_IN_CONTAINER -ne "true") {
  throw "This script must run in Docker. Run docker.ps1 instead."
}

@($true, $false) | % {
  $addTrustedSigners = $_

  $source.Packages | % {
    Test-DotnetCli `
      -TestName "docker-$envName-$ClientName" `
      -SdkVersion $null `
      -PackageSource $source.PackageSource `
      -AddTrustedSigners $addTrustedSigners `
      -SupportsVerifyCommand ($ClientName -ne "dotnet31") `
      -Id $_.PackageId `
      -Version $_.PackageVersion
  }
}