. (Join-Path $PSScriptRoot "common.ps1")

# Run test cases
# ==============
$envName = Get-EnvName
$configs = Get-Configs
$source = Get-PackageSource $configs

if ($IsMacOS -eq $false) {
  throw "This script must be run on macOS"
}

Remove-PreviousTestItems

$configs.NuGetClients | % {
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