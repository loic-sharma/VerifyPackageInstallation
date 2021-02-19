$sources = @{
  DEV  = @{
    PackageSource = "https://apidev.nugettest.org/v3/index.json";

    Packages      = @(
      @{ PackageId = "Newtonsoft.Json"; PackageVersion = "12.0.1"; } # Old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # New repo cert
      @{ PackageId = "Azure.Storage.Blobs"; PackageVersion = "12.2.0"; } # Author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Author signed + new repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Revoked MSFT author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Revoked non-MSFT author signed + old repo cert
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
      # @{ PackageId = ""; PackageVersion = ""; } # Revoked MSFT author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Revoked non-MSFT author signed + old repo cert
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
      # @{ PackageId = ""; PackageVersion = ""; } # Revoked MSFT author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Revoked non-MSFT author signed + old repo cert
      # @{ PackageId = ""; PackageVersion = ""; } # Expired non-MSFT author signed + old repo cert
    )
  }
}

$envName = "DEV"
$source = $sources.DEV

$nugetClients = @("nuget464", "nuget473", "nuget494", "nuget502", "nuget581")

$nugetClients | % {
  $clientName = $_
  $nugetexe = ".\tools\$clientName.exe"

  $source.Packages | % {
    rmdir "$($env:UserProfile)\.nuget\packages\$($_.PackageId)" -Force -Recurse -ErrorAction SilentlyContinue
    rmdir .\packages -Force -Recurse -ErrorAction SilentlyContinue

    & $nugetexe locals http-cache -clear -Verbosity quiet

    $packagesConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="$($_.PackageId)" version="$($_.PackageVersion)" targetFramework="net472" />
</packages>
"@

    Set-Content -Path .\Legacy\packages.config -Value $packagesConfig

    $identity = "$($_.PackageId).$($_.PackageVersion)"
    $restore = (& $nugetexe restore .\Legacy\Legacy.csproj -Source $source.PackageSource -PackagesDirectory packages -Verbosity detailed | Out-String).Trim()
    $verify = (& $nugetexe verify -All -Verbosity detailed ".\packages\$identity\$identity.nupkg" | Out-String).Trim()

    if (-not ($restore.Contains("Installed:") -and $restore.Contains("1 package(s) to packages.config projects"))) { throw "Unexpected restore output: $restore "}
    if (-not ($verify.Contains("Successfully verified package"))) { throw "Unexpected verify output: $verify" }

    Set-Content -Path ".\output\$envName-$clientName-restore-$($_.PackageId).txt" -Value $restore -Force 
    Set-Content -Path ".\output\$envName-$clientName-verify-$($_.PackageId).txt" -Value $verify -Force 
  }
}

