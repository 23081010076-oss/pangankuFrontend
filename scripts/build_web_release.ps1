param(
    [Parameter(Mandatory = $true)]
    [string]$ApiBaseUrl
)

$ErrorActionPreference = "Stop"

Push-Location (Join-Path $PSScriptRoot "..")
try {
    flutter pub get
    flutter build web --release --dart-define="API_BASE_URL=$ApiBaseUrl"
    Write-Host "Flutter Web siap di: $(Join-Path (Get-Location) 'build\web')"
}
finally {
    Pop-Location
}
