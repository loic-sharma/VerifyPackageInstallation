function Clean-PackageInstallation {
    param (
        $PackageId
    )
    
    dotnet nuget locals -c http-cache

    rmdir "$($env:UserProfile)\.nuget\packages\$PackageId" -Force -Recurse

    git clean -Xfd

    # .\nuget46.exe restore .\repotest.csproj -Source https://apidev.nugettest.org/v3/index.json
}

function Verify-PackageInstallation {
    param (
        $Source,
        $PackageId,
        $PackageVersion
    )
    


}

$sources = @{
    DEV = @{
        PackageSource = "https://apidev.nugettest.org/v3/index.json";

        Packages = @(
            @{ PackageId = "Newtonsoft.Json"; PackageVersion = "12.0.1"; } # Old repo cert
            @{ PackageId = ""; PackageVersion = ""; } # New repo cert
            @{ PackageId = ""; PackageVersion = ""; } # Author signed + old repo cert
            @{ PackageId = ""; PackageVersion = ""; } # Author signed + new repo cert
            @{ PackageId = ""; PackageVersion = ""; } # Revoked MSFT author signed + old repo cert
            @{ PackageId = ""; PackageVersion = ""; } # Revoked non-MSFT author signed + old repo cert
        );
    };

    INT = @{

    };

    PROD = @{

    }
}

$source = $sources.DEV

$nugetexe = ".\tools\nuget464.exe"

$source.Packages | %{
    rmdir "$($env:UserProfile)\.nuget\packages\$($_.PackageId)" -Force -Recurse
    rmdir .\packages -Force -Recurse

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
    if (-not ($verify.Contains("Successfully verified package(s)."))) { throw "Unexpected verify output: $verify" }

    Set-Content -Path .\output\nuget464-restore.txt -Value $restore -Force 
    Set-Content -Path .\output\nuget464-verify.txt -Value $verify -Force 

    Write-Host $restore
    Write-Host $verify

    throw "Done"
}