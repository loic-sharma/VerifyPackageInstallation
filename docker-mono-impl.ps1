param (
  $ClientName
)
. (Join-Path $PSScriptRoot "common.ps1")


# Run test cases
# ==============
$envName = Get-EnvName
$configs = Get-Configs
$source = Get-PackageSource $configs

if ($env:DOTNET_RUNNING_IN_CONTAINER -ne "true") {
  throw "This script must run in Docker. Run docker-mono.ps1 instead."
}

$nugetexe = "mono ./tools/$ClientName.exe"

@($true, $false) | % {
  $addTrustedSigners = $_

  $source.Packages | % {
    # The nuget.exe verify command is broken on Mono.
    # See: https://github.com/NuGet/Home/issues/10585
    Test-NuGetExe `
      -TestName "docker-$envName-mono-$clientName" `
      -NugetExe $nugetexe `
      -PackageSource $source.PackageSource `
      -AddTrustedSigners $addTrustedSigners `
      -SupportsVerifyCommand $false `
      -Id $_.PackageId `
      -Version $_.PackageVersion
  }
}