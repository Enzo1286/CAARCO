# ============================================================
# CAARCO — Script de build debug local
# Usage : .\build-debug.ps1
# ============================================================

Set-Location "C:\CAARCO\App"

# ── 1. Lire et injecter les variables d'environnement depuis .env ─────────
Write-Host "Injection des variables d'environnement..." -ForegroundColor Cyan
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$") {
            $key   = $Matches[1]
            $value = $Matches[2]
            [System.Environment]::SetEnvironmentVariable($key, $value, "Process")
            Write-Host "  SET $key" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  .env introuvable, utilisation des valeurs eas.json" -ForegroundColor Yellow
    $env:EXPO_PUBLIC_SUPABASE_URL      = "https://dxwkikaniawpfljvteog.supabase.co"
    $env:EXPO_PUBLIC_SUPABASE_ANON_KEY = "sb_publishable_ByqbWG3b2BY7IckPEEe6YA_NtUOj6_6"
    $env:EXPO_PUBLIC_APP_ENV           = "development"
}

# ── 2. Recréer local.properties (effacé par prebuild --clean) ─────────────
Write-Host "Création de local.properties..." -ForegroundColor Cyan
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk" -replace "\\", "\\\\"
"sdk.dir=$sdkPath" | Out-File -FilePath "android\local.properties" -Encoding ascii
Write-Host "  sdk.dir=$($env:LOCALAPPDATA)\Android\Sdk" -ForegroundColor Gray

# ── 3. Compilation ─────────────────────────────────────────────────────────
Write-Host "Compilation en cours..." -ForegroundColor Cyan
Set-Location "C:\CAARCO\App\android"
.\gradlew assembleDebug --max-workers=2

if ($LASTEXITCODE -eq 0) {
    $apk = "app\build\outputs\apk\debug\app-debug.apk"
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host ""
    Write-Host "BUILD OK — $size Mo" -ForegroundColor Green
    Write-Host "APK : C:\CAARCO\App\android\$apk" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pour installer sur le telephone (USB) :" -ForegroundColor Yellow
    Write-Host "  adb uninstall com.caarco.app" -ForegroundColor White
    Write-Host "  adb install `"C:\CAARCO\App\android\$apk`"" -ForegroundColor White
} else {
    Write-Host "BUILD FAILED" -ForegroundColor Red
}
