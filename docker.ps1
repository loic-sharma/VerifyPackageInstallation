. (Join-Path $PSScriptRoot "common.ps1")

Remove-PreviousTestItems

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
