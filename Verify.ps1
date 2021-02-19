$sources = @{
  DEV  = @{
    PackageSource = "https://apidev.nugettest.org/v3/index.json";

    Packages      = @(
      @{ PackageId = "Newtonsoft.Json"; PackageVersion = "12.0.1"; } # Old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + new repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # New repo cert
      @{ PackageId = "Azure.Storage.Blobs"; PackageVersion = "12.9.0-beta.1"; } # Author signed + old repo cert
      @{ PackageId = "Azure.Storage.Blobs"; PackageVersion = "12.2.0"; } # Expired MSFT author signed + old repo cert
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

$envName = "DEV"
$source = $sources.DEV

$nugetClients = @("nuget464", "nuget473", "nuget494", "nuget502", "nuget581")
$dotnetClients = @(
  @{ Name = "dotnet31"; Version = "3.1.302"; },
  @{ Name = "dotnet50"; Version = "5.0.103"; }
)

$nugetClients | % {
  $clientName = $_
  $nugetexe = ".\tools\$clientName.exe"

  $source.Packages | % {
    $id = $_.PackageId
    $version = $_.PackageVersion

    rmdir "$($env:UserProfile)\.nuget\packages\$id" -Force -Recurse -ErrorAction SilentlyContinue
    rmdir .\packages -Force -Recurse -ErrorAction SilentlyContinue

    & $nugetexe locals http-cache -clear -Verbosity quiet

    $packagesConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="$id" version="$version" targetFramework="net472" />
</packages>
"@

    Set-Content -Path .\Legacy\packages.config -Value $packagesConfig

    $identity = "$id.$version"
    $restore = (& $nugetexe restore .\Legacy\Legacy.csproj -Source $source.PackageSource -PackagesDirectory packages -Verbosity detailed | Out-String).Trim()
    $verify = (& $nugetexe verify -All -Verbosity detailed ".\packages\$identity\$identity.nupkg" | Out-String).Trim()

    if (-not ($restore.Contains("Installed:") -and $restore.Contains("1 package(s) to packages.config projects"))) { throw "Unexpected restore output: $restore "}
    if (-not ($verify.Contains("Successfully verified package"))) { throw "Unexpected verify output: $verify" }

    Set-Content -Path ".\output\$envName-$clientName-restore-$id-$version.txt" -Value $restore -Force 
    Set-Content -Path ".\output\$envName-$clientName-verify-$id-$version.txt" -Value $verify -Force 
  }
}

$dotnetClients | % {
  $clientName = $_.Name

  dotnet new globaljson --sdk-version $($_.Version) --force | Out-Null

  $source.Packages | % {
    $id = $_.PackageId
    $version = $_.PackageVersion

    rmdir "$($env:UserProfile)\.nuget\packages\$id" -Force -Recurse -ErrorAction SilentlyContinue
    rmdir .\Sdk\bin -Force -Recurse -ErrorAction SilentlyContinue
    rmdir .\Sdk\obj -Force -Recurse -ErrorAction SilentlyContinue

    dotnet nuget locals http-cache --clear | Out-Null

    $project = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net5.0</TargetFramework>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="$id" Version="$version" />
  </ItemGroup>
</Project>
"@

    Set-Content -Path .\Sdk\Sdk.csproj -Value $project

    $restore = (dotnet restore .\Sdk\Sdk.csproj --source $source.PackageSource --verbosity normal | Out-String).Trim()

    if (-not ($restore.Contains("Build succeeded."))) { throw "Unexpected restore output: $restore "}

    Set-Content -Path ".\output\$envName-$clientName-restore-$id-$version.txt" -Value $restore -Force

    if ($clientName -ne "dotnet31") {
      $verify = (dotnet nuget verify --verbosity normal "$($env:UserProfile)\.nuget\packages\$id\$version\$id.$version.nupkg" | Out-String).Trim()

      if (-not ($verify.Contains("Successfully verified package"))) { throw "Unexpected verify output: $verify "}

      Set-Content -Path ".\output\$envName-$clientName-verify-$id-$version.txt" -Value $verify -Force
    }
  }
}