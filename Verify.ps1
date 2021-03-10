# Configs
# =======
$sources = @{
  DEV  = @{
    PackageSource = "https://apidev.nugettest.org/v3/index.json";

    Packages      = @(
      @{ PackageId = "Newtonsoft.Json"; PackageVersion = "12.0.1"; } # Old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + new repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # New repo cert
      @{ PackageId = "Microsoft.Bcl.AsyncInterfaces"; PackageVersion = "6.0.0-preview.1.21102.12"; } # Author signed + old repo cert
      @{ PackageId = "E2E.SignedPackage"; PackageVersion = "2020.9.7-v0835112820328"; } # Expired MSFT author signed + old repo cert
      @{ PackageId = "System.Rido"; PackageVersion = "1.0.1"; } # Expired non-MSFT author signed + old repo cert
    );
  };

  INT  = @{
    PackageSource = "https://apiint.nugettest.org/v3/index.json";

    Packages      = @(
      # @{ PackageId = ""; PackageVersion = ""; } # Old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # New repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + new repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Expired MSFT author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Expired non-MSFT author signed + old repo cert
    )
  };

  PROD = @{
    PackageSource = "https://api.nuget.org/v3/index.json";

    Packages      = @(
      # @{ PackageId = ""; PackageVersion = ""; } # Old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # New repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + new repo cert
      @{ PackageId = "Microsoft.Extensions.DependencyInjection.Abstractions"; PackageVersion = "5.0.0"; } # Expired MSFT author signed + old repo cert
      @{ PackageId = "postsharp.patterns.common.redist"; PackageVersion = "6.3.6-preview"; } # Expired non-MSFT author signed + old repo cert
    )
  }
}

$nugetClients = @("nuget464", "nuget473", "nuget494", "nuget502", "nuget581")
$dotnetClients = @(
  # @{ Name = "dotnet31"; Version = "3.1.302"; },
  @{ Name = "dotnet50"; Version = "5.0.103"; }
)

# Test runners
# ============
function Test-NuGetExe {
  param (
    $TestName,
    $NugetExe,
    $AddTrustedSigners,
    $Id,
    $Version
  )

  Remove-Item "$($env:UserProfile)/.nuget/packages/$Id" -Force -Recurse -ErrorAction SilentlyContinue
  Remove-Item "./packages" -Force -Recurse -ErrorAction SilentlyContinue

  Invoke-Expression "$NugetExe locals http-cache -clear -Verbosity quiet"

  if ($AddTrustedSigners) {
    $trustedSigners = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <trustedSigners>
    <author name="microsoft">
      <certificate fingerprint="3F9001EA83C560D712C24CF213C3D312CB3BFF51EE89435D3430BD06B5D0EECE" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <certificate fingerprint="AA12DA22A49BCE7D5C1AE64CC1F3D892F150DA76140F210ABD2CBFFCA2C18A27" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
    </author>
    <repository name="DEV" serviceIndex="https://apidev.nugettest.org/v3/index.json">
      <certificate fingerprint="CF6CE6768EF858A3A667BE1AF8AA524D386C7F59A34542713F5DFB0D79ACF3DD" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <certificate fingerprint="BA5A630994B2B8F562B307A2A3245998232EF0A94EE80BECE5CEA0B5CECA61F9" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <owners>microsoft;aspnet;nuget;loshar;jamesnk;jver</owners>
    </repository>
    <repository name="INT" serviceIndex="https://apiint.nugettest.org/v3/index.json">
      <certificate fingerprint="CF6CE6768EF858A3A667BE1AF8AA524D386C7F59A34542713F5DFB0D79ACF3DD" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <certificate fingerprint="BA5A630994B2B8F562B307A2A3245998232EF0A94EE80BECE5CEA0B5CECA61F9" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <owners>microsoft;aspnet;nuget;loshar;jamesnk</owners>
    </repository>
    <repository name="nuget.org" serviceIndex="https://api.nuget.org/v3/index.json">
      <certificate fingerprint="0E5F38F57DC1BCC806D8494F4F90FBCEDD988B46760709CBEEC6F4219AA6157D" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <certificate fingerprint="5A2901D6ADA3D18260B9C6DFE2133C95D74B9EEF6AE0E5DC334C8454D1477DF4" hashAlgorithm="SHA256" allowUntrustedRoot="false" />
      <owners>microsoft;aspnet;nuget;loshar;jamesnk</owners>
    </repository>
  </trustedSigners>
</configuration>
"@

    Set-Content -Path "nuget.config" -Value $trustedSigners
  } elseif (Test-Path "nuget.config") {
    Remove-Item -Path "nuget.config"
  }

  $packagesConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="$Id" version="$Version" targetFramework="net472" />
</packages>
"@

  Set-Content -Path "./Legacy/packages.config" -Value $packagesConfig

  $identity = "$Id.$Version"
  $restore = (Invoke-Expression "$NugetExe restore ./Legacy/Legacy.csproj -Source $($source.PackageSource) -PackagesDirectory packages -Verbosity detailed" | Out-String).Trim()
  $verify = (Invoke-Expression "$NugetExe verify -All -Verbosity detailed ""./packages/$identity/$identity.nupkg""" | Out-String).Trim()

  if (-not ($restore.Contains("Installed:") -and $restore.Contains("1 package(s) to packages.config projects"))) { throw "Unexpected restore output: $restore "}
  if (-not ($verify.Contains("Successfully verified package"))) { throw "Unexpected verify output: $verify" }

  Set-Content -Path "./output/$TestName-restore-$Id-$Version.txt" -Value $restore -Force
  Set-Content -Path "./output/$TestName-verify-$Id-$Version.txt" -Value $verify -Force
}

function Test-DotnetCli {
  param (
    $TestName,
    $SdkVersion,
    $AddTrustedSigners,
    $SupportsVerifyCommand,
    $Id,
    $Version
  )

  # Clean up any state.
  Remove-Item "$($env:UserProfile)/.nuget/packages/$Id" -Force -Recurse -ErrorAction SilentlyContinue
  Remove-Item "./Sdk/bin" -Force -Recurse -ErrorAction SilentlyContinue
  Remove-Item "./Sdk/obj" -Force -Recurse -ErrorAction SilentlyContinue

  dotnet nuget locals http-cache --clear | Out-Null

  # Lock down the SDK version
  dotnet new globaljson --sdk-version $SdkVersion --force | Out-Null

  # Create a project to restore and verify.
  $project = @"
<Project Sdk="Microsoft.NET.Sdk">
<PropertyGroup>
  <TargetFramework>netstandard2.0</TargetFramework>
</PropertyGroup>
<ItemGroup>
  <PackageReference Include="$Id" Version="$Version" />
</ItemGroup>
</Project>
"@

  Set-Content -Path "./Sdk/Sdk.csproj" -Value $project

  # Run restore.
  $restore = (dotnet restore "./Sdk/Sdk.csproj" --source $source.PackageSource --verbosity normal | Out-String).Trim()

  if (-not ($restore.Contains("Build succeeded."))) { throw "Unexpected restore output: $restore "}

  Set-Content -Path "./output/$TestName-restore-$Id-$Version.txt" -Value $restore -Force

  if ($SupportsVerifyCommand) {
    $verify = (dotnet nuget verify --verbosity normal "$($env:UserProfile)/.nuget/packages/$Id/$Version/$Id.$Version.nupkg" | Out-String).Trim()

    if (-not ($verify.Contains("Successfully verified package"))) { throw "Unexpected verify output: $verify "}

    Set-Content -Path "./output/$TestName-verify-$Id-$Version.txt" -Value $verify -Force
  }
}

# Run test cases
# ==============
$envName = "DEV"
$source = $sources.DEV

Remove-Item "./output/*.txt"

@($true, $false) | % {
  $mono = $_

  # Skip mono tests on Windows due to bugs.
  if ($mono -and ($IsWindows -eq $null -or $IsWindows -eq $true)) {
    return # We're in a script block so return is effectively "continue"
  }

  # Only run mono tests on macOS or Linux.
  if (-not $mono -and $IsWindows -eq $false) {
    return
  }

  @($true, $false) | % {
    $addTrustedSigners = $_

    $nugetClients | % {
      $clientName = $_
      $nugetexe = "./tools/$clientName.exe"

      if ($mono) {
        $clientName = "mono-$clientName"
        $nugetexe = "mono $nugetexe"
      }

      if ($addTrustedSigners) {
        $clientName = "$clientName-trustedSigners"
      }

      $source.Packages | % {
        Test-NuGetExe `
          -TestName "$envName-$clientName" `
          -NugetExe $nugetexe `
          -Id $_.PackageId `
          -Version $_.PackageVersion
      }
    }
  }
}

$dotnetClients | % {
  $clientName = $_.Name
  $sdkVersion = $_.Version

  $source.Packages | % {
    Test-DotnetCli `
      -TestName "$envName-$clientName" `
      -SdkVersion $sdkVersion `
      -SupportsVerifyCommand ($clientName -ne "dotnet31") `
      -Id $_.PackageId `
      -Version $_.PackageVersion
  }
}