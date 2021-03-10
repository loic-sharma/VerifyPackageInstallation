. (Join-Path $PSScriptRoot "common.ps1")

# Run test cases
# ==============
$envName = "DEV"
$configs = Get-Configs
$source = $configs.Sources.DEV

if ($IsWindows -eq $false) {
  throw "This script must be run on Windows"
}

Remove-Item "./output/*.txt"

# TODO: Remove mono from Windows script
# @($false) | % {
#   $mono = $_

#   @($true, $false) | % {
#     $addTrustedSigners = $_

#     $configs.NuGetClients | % {
#       $clientName = $_
#       $nugetexe = "./tools/$clientName.exe"

#       if ($mono) {
#         $clientName = "mono-$clientName"
#         $nugetexe = "mono $nugetexe"
#       }

#       if ($addTrustedSigners) {
#         $clientName = "$clientName-trustedSigners"
#       }

#       $source.Packages | % {
#         Test-NuGetExe `
#           -TestName "$envName-$clientName" `
#           -NugetExe $nugetexe `
#           -PackageSource $source.PackageSource `
#           -AddTrustedSigners $addTrustedSigners `
#           -Id $_.PackageId `
#           -Version $_.PackageVersion
#       }
#     }
#   }
# }

$configs.DotnetClients | % {
  $clientName = $_.Name
  $sdkVersion = $_.Version

  @($true, $false) | % {
    $addTrustedSigners = $_

    $source.Packages | % {
      Test-DotnetCli `
        -TestName "$envName-$clientName" `
        -SdkVersion $sdkVersion `
        -PackageSource $source.PackageSource `
        -AddTrustedSigners $addTrustedSigners `
        -SupportsVerifyCommand ($clientName -ne "dotnet31") `
        -Id $_.PackageId `
        -Version $_.PackageVersion
    }
  }
}