# ============================================================
# CAARCO - Script de build de production (AAB) + copie au bureau
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

# 3. Compilation du Bundle (AAB)
Write-Host "Compilation AAB (bundleRelease) en cours..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\App\android"
.\gradlew bundleRelease --max-workers=2

if ($LASTEXITCODE -eq 0) {
    $aab = "app\build\outputs\bundle\release\app-release.aab"
    
    if (-not (Test-Path $aab)) {
        Write-Host "Aucun AAB trouve !" -ForegroundColor Red
        exit 1
    }

    Write-Host "Build reussi. AAB: $aab" -ForegroundColor Green

    # 4. Lire la version et le versionCode depuis app.json
    $appJsonPath = "$PSScriptRoot\App\app.json"
    $appJson = Get-Content $appJsonPath | ConvertFrom-Json
    $version = $appJson.expo.version
    $vc = $appJson.expo.android.versionCode

    # 5. Copie sur le bureau
    # Format de nom convenu avec Cedric (2026-07-20) : vc<annee2c>-<mois>.<jour>-c<versionCode>
    # ex. vc26-07.20-c29.aab = annee 2026, 20 juillet, versionCode Android reel 29.
    # Le versionCode reste indispensable dans le nom : Play Store exige qu'il
    # augmente a CHAQUE envoi (jamais "un par an"), et sans lui deux builds le
    # meme jour porteraient le meme nom et s'ecraseraient silencieusement.
    $today      = Get-Date
    $dateLabel  = "{0}-{1}.{2}" -f $today.ToString("yy"), $today.ToString("MM"), $today.ToString("dd")
    $desktop = [Environment]::GetFolderPath("Desktop")
    $destination = Join-Path -Path $desktop -ChildPath "vc$dateLabel-c$vc.aab"
    
    Write-Host "Copie de l'AAB vers le bureau ($destination)..." -ForegroundColor Cyan
    Copy-Item -Path $aab -Destination $destination -Force
    
    if ($?) {
        Write-Host "Succès : L'AAB de production est sur le bureau." -ForegroundColor Green
    } else {
        Write-Host "Échec de la copie vers le bureau." -ForegroundColor Red
    }
} else {
    Write-Host "Echec de la compilation" -ForegroundColor Red
    exit 1
}
