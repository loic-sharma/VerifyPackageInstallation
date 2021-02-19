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