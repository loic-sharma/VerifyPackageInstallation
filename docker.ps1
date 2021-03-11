. (Join-Path $PSScriptRoot "common.ps1")

Remove-Item "./output/*.txt"

if (Test-Path "global.json") {
  Remove-Item "global.json"
}

if (Test-Path "nuget.config") {
  Remove-Item "nuget.config"
}

$configs = Get-Configs

$configs.DotnetClients | % {
  $dockerTag = $_.DockerTag
  $clientName = $_.Name

  docker run --rm `
    -v D:\Code\VerifyPackageInstallation:/verify `
    -w /verify `
    mcr.microsoft.com/dotnet/sdk:$dockerTag `
    pwsh docker-impl.ps1 -ClientName $clientName
}
