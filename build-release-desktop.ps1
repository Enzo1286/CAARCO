# ============================================================
# CAARCO - Script de build release local + copie au bureau
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
}

# 2. Recreer local.properties
Write-Host "Creation de local.properties..." -ForegroundColor Cyan
$sdkPath = "$env:LOCALAPPDATA\Android\Sdk" -replace "\\", "\\\\"
"sdk.dir=$sdkPath" | Out-File -FilePath "android\local.properties" -Encoding ascii

# 3. Compilation
Write-Host "Compilation en release en cours..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\App\android"
.\gradlew assembleRelease --max-workers=2

if ($LASTEXITCODE -eq 0) {
    $apkSigned = "app\build\outputs\apk\release\app-release.apk"
    $apkUnsigned = "app\build\outputs\apk\release\app-release-unsigned.apk"
    
    $apk = ""
    if (Test-Path $apkSigned) {
        $apk = $apkSigned
    } elseif (Test-Path $apkUnsigned) {
        $apk = $apkUnsigned
    } else {
        Write-Host "Aucun APK trouve !" -ForegroundColor Red
        exit 1
    }

    Write-Host "Build reussi. APK: $apk" -ForegroundColor Green

    # 4. Copie sur le bureau
    $desktop = [Environment]::GetFolderPath("Desktop")
    $destination = Join-Path -Path $desktop -ChildPath "app-release.apk"
    
    Write-Host "Copie de l'APK vers le bureau ($destination)..." -ForegroundColor Cyan
    Copy-Item -Path $apk -Destination $destination -Force
    
    if ($?) {
        Write-Host "Succès : L'APK est sur le bureau." -ForegroundColor Green
    } else {
        Write-Host "Échec de la copie vers le bureau." -ForegroundColor Red
    }
} else {
    Write-Host "Echec de la compilation" -ForegroundColor Red
    exit 1
}
