# ============================================================
# CAARCO - Script de build release local + install (tous USB)
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

# 2. Recreer local.properties et configurer la mémoire
Write-Host "Configuration de la mémoire (Node & Gradle)..." -ForegroundColor Cyan
$env:NODE_OPTIONS = "--max-old-space-size=4096"
$env:GRADLE_OPTS = "-Dorg.gradle.jvmargs=`"-Xmx2048m -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8`""

$sdkPath = "$env:LOCALAPPDATA\Android\Sdk" -replace "\\", "\\\\"
"sdk.dir=$sdkPath" | Out-File -FilePath "android\local.properties" -Encoding ascii

# 3. Compilation
Write-Host "Arret des anciens daemons Gradle..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\App\android"
.\gradlew --stop

Write-Host "Compilation en release en cours..." -ForegroundColor Cyan
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

    $size = [math]::Round((Get-Item "$PSScriptRoot\App\android\$apk").Length / 1MB, 1)
    Write-Host "Build reussi ($size Mo). APK: $apk" -ForegroundColor Green

    # Copie sur le bureau
    $desktopPath = "$env:USERPROFILE\Desktop\caarco-release.apk"
    Copy-Item "$PSScriptRoot\App\android\$apk" $desktopPath -Force
    Write-Host "APK depose sur le bureau : $desktopPath" -ForegroundColor Green

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
                Write-Host "Lancement de l'application..." -ForegroundColor Cyan
                & $adb -s $device shell monkey -p com.caarco.app -c android.intent.category.LAUNCHER 1
            } else {
                Write-Host "Echec sur $device" -ForegroundColor Red
            }
        }
    }
} else {
    Write-Host "Echec de la compilation" -ForegroundColor Red
    exit 1
}
