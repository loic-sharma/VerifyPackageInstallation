. (Join-Path $PSScriptRoot "common.ps1")

# Run test cases
# ==============
$envName = "DEV"
$configs = Get-Configs
$source = $configs.Sources.DEV

if ($IsMacOS -eq $false) {
  throw "This script must be run on macOS"
}

Remove-Item "./output/*.txt"

# Mono restore was broken on macOS until nuget.exe v5.2 and newer.
# See: https://github.com/nuget/nuget.client/pull/2826
#$configs.NuGetClients | % {
@("nuget581") | % {
  $clientName = $_
  $nugetexe = "mono ./tools/$clientName.exe"

  @($true, $false) | % {
    $addTrustedSigners = $_

    $source.Packages | % {
    # The nuget.exe verify command is broken on Mono.
    # See: https://github.com/NuGet/Home/issues/10585
      Test-NuGetExe `
        -TestName "macos-$envName-mono-$clientName" `
        -NugetExe $nugetexe `
        -PackageSource $source.PackageSource `
        -AddTrustedSigners $addTrustedSigners `
        -SupportsVerifyCommand $false `
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
        -TestName "macos-$envName-$clientName" `
        -SdkVersion $sdkVersion `
        -PackageSource $source.PackageSource `
        -AddTrustedSigners $addTrustedSigners `
        -SupportsVerifyCommand ($clientName -ne "dotnet31") `
        -Id $_.PackageId `
        -Version $_.PackageVersion
    }
  }
}