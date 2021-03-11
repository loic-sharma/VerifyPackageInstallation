. (Join-Path $PSScriptRoot "common.ps1")

if ($IsWindows -eq $false) {
  throw "This script must be run on Windows"
}


Remove-PreviousTestItems

$envName = "DEV"
$configs = Get-Configs
$source = $configs.Sources.DEV

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