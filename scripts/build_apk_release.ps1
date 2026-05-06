param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
    flutter pub get
    flutter build apk --release --dart-define="API_BASE_URL=$ApiBaseUrl"
    Write-Host "APK siap di: $(Join-Path (Get-Location) 'build\app\outputs\flutter-apk\app-release.apk')"
}
finally {
    Pop-Location
}
