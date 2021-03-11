. (Join-Path $PSScriptRoot "common.ps1")

Remove-PreviousTestItems

$configs = Get-Configs

$configs.NuGetClients | % {
  $clientName = $_

  docker run --rm `
    -v D:\Code\VerifyPackageInstallation:/verify `
    -w /verify `
    julkwiec/dotnet-mono-powershell-build `
    pwsh docker-mono-impl.ps1 -ClientName $clientName
}
