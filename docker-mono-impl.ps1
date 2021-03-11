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
  throw "This script must run in Docker. Run docker-mono.ps1 instead."
}

$nugetexe = "mono ./tools/$ClientName.exe"

@($true, $false) | % {
  $addTrustedSigners = $_

  $source.Packages | % {
    Test-NuGetExe `
      -TestName "docker-$envName-mono-$clientName" `
      -NugetExe $nugetexe `
      -PackageSource $source.PackageSource `
      -AddTrustedSigners $addTrustedSigners `
      -Id $_.PackageId `
      -Version $_.PackageVersion
  }
}