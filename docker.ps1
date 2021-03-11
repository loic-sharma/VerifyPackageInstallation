. (Join-Path $PSScriptRoot "common.ps1")

Remove-Item "./output/*.txt"

if (Test-Path "global.json") {
  Remove-Item "global.json"
}

if (Test-Path "nuget.config") {
  Remove-Item "nuget.config"
}

#@("3.1", "5.0") | % {
@("5.0") | % {
    $sdkVersion = $_

    docker run --rm `
        -v D:\Code\VerifyPackageInstallation:/verify `
        -w /verify `
        mcr.microsoft.com/dotnet/sdk:$sdkVersion `
        pwsh docker-impl.ps1 -ClientName "dotnet50"
}
