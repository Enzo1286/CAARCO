# ============================================================
# CAARCO - Script de build debug local + install (tous USB)
# Usage : .\build-debug-usb.ps1
# ============================================================

Set-Location "$PSScriptRoot\App"

# 1. Lire et injecter les variables d'environnement
Write-Host "Injection des variables d'environnement..." -ForegroundColor Cyan
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$") {
            $key   = $Matches[1]
            $value = $Matches[2]
            [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
} else {
    Write-Host "  .env introuvable, utilisation des valeurs eas.json" -ForegroundColor Yellow
    $env:EXPO_PUBLIC_SUPABASE_URL      = "https://dxwkikaniawpfljvteog.supabase.co"
    $env:EXPO_PUBLIC_SUPABASE_ANON_KEY = "sb_publishable_ByqbWG3b2BY7IckPEEe6YA_NtUOj6_6"
    $env:EXPO_PUBLIC_APP_ENV           = "development"
}

# 2. Recreer local.properties
Write-Host "Creation de local.properties..." -ForegroundColor Cyan
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk" -replace "\\", "\\\\"
"sdk.dir=$sdkPath" | Out-File -FilePath "android\local.properties" -Encoding ascii

# 3. Compilation
Write-Host "Compilation en debug en cours..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\App\android"
.\gradlew assembleDebug --max-workers=2

if ($LASTEXITCODE -eq 0) {
    $apk = "app\build\outputs\apk\debug\app-debug.apk"
    if (-not (Test-Path $apk)) {
        Write-Host "Aucun APK trouve !" -ForegroundColor Red
        exit 1
    }
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host "Build reussi ($size Mo). APK: $apk" -ForegroundColor Green

    # 4. Installation
    $adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
    $devicesOutput = & $adb devices
    $devices = $devicesOutput | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices attached" } | ForEach-Object { ($_ -split "`t")[0] }

    if ($devices.Count -eq 0) {
        Write-Host "Aucun telephone detecte via USB." -ForegroundColor Yellow
    } else {
        foreach ($device in $devices) {
            Write-Host "Installation sur $device..." -ForegroundColor Cyan
            & $adb -s $device uninstall com.caarco.app
            & $adb -s $device install "$PSScriptRoot\App\android\$apk"
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Succes sur $device" -ForegroundColor Green
            } else {
                Write-Host "Echec sur $device" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "Echec de la compilation" -ForegroundColor Red
    exit 1
}
