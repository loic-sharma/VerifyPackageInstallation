Run:

Ignore changes to `Sdk.csproj` as it will be overwritten:

```ps1
git update-index --assume-unchanged Sdk\Sdk.csproj
```

Mono trust root certificates from: https://mono.github.io/mail-archives/mono-list/2017-April/052433.html

```
cert-sync --user "C:\Users\sharm\Downloads\cacert.pem"
```

Now run:

```ps1
.\Verify.ps1
```

For Docker, run:

```ps1
docker run --rm -v D:\Code\VerifyPackageInstallation:/verify -w /verify mcr.microsoft.com/dotnet/sdk:5.0 pwsh Verify.ps1
```

For more information on PowerShell in Docker, see [this](https://github.com/dotnet/dotnet-docker/issues/1069).