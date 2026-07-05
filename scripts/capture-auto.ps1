# ═══════════════════════════════════════════════════
# CAARCO — Capture automatique (UN SEUL SCRIPT)
# Usage : clic droit → Exécuter avec PowerShell
# ═══════════════════════════════════════════════════

$scriptDir = $PSScriptRoot
$maestroFlow = "$scriptDir\maestro\caarco_tous_ecrans.yaml"
$dossierScreenshots = "$scriptDir\maestro\screenshots"

Write-Host ""
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host "  CAARCO — Capture auto des écrans" -ForegroundColor Green
Write-Host "══════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# ── Vérifier ADB ───────────────────────────────────
$adbTest = adb devices 2>&1
if ($adbTest -notmatch "device") {
    Write-Host "ERREUR : Aucun téléphone Android détecté." -ForegroundColor Red
    Write-Host ""
    Write-Host "Vérifier :" -ForegroundColor Yellow
    Write-Host "  1. Cable USB branché" -ForegroundColor White
    Write-Host "  2. Débogage USB activé (Options développeur)" -ForegroundColor White
    Write-Host "  3. Accepter la popup sur le téléphone" -ForegroundColor White
    Read-Host "Appuie sur Entrée pour quitter"
    exit 1
}

Write-Host "Téléphone détecté." -ForegroundColor Green

# ── Vérifier Maestro ───────────────────────────────
$maestroOk = Get-Command maestro -ErrorAction SilentlyContinue
if (-not $maestroOk) {
    Write-Host ""
    Write-Host "Maestro n'est pas installé. Installation en cours..." -ForegroundColor Yellow

    # Méthode alternative via jar (si Java disponible)
    $javaOk = Get-Command java -ErrorAction SilentlyContinue
    if ($javaOk) {
        Write-Host "Java trouvé, installation Maestro via script officiel..." -ForegroundColor Cyan
        $installScript = Invoke-WebRequest -Uri "https://get.maestro.mobile.dev" -UseBasicParsing
        $tempScript = "$env:TEMP\install-maestro.ps1"
        $installScript.Content | Out-File $tempScript
        & powershell -ExecutionPolicy Bypass -File $tempScript
    } else {
        Write-Host ""
        Write-Host "Java non trouvé. Maestro nécessite Java 11+." -ForegroundColor Red
        Write-Host ""
        Write-Host "ALTERNATIVE SANS MAESTRO — Mode manuel ADB :" -ForegroundColor Yellow
        Write-Host "  Lancer capture-ecrans.ps1 à la place" -ForegroundColor White
        Write-Host ""

        $choix = Read-Host "Lancer la capture manuelle ADB ? (o/n)"
        if ($choix -eq 'o') {
            & "$scriptDir\capture-ecrans.ps1"
        }
        exit
    }
}

# ── Créer le dossier de sortie ─────────────────────
New-Item -ItemType Directory -Force -Path $dossierScreenshots | Out-Null

Write-Host ""
Write-Host "Lancement de la capture automatique..." -ForegroundColor Cyan
Write-Host "L'app va s'ouvrir et naviguer toute seule." -ForegroundColor White
Write-Host "Ne touche pas au téléphone pendant la capture !" -ForegroundColor Yellow
Write-Host ""

# ── Lancer Maestro ─────────────────────────────────
Set-Location "$scriptDir\maestro"
maestro test caarco_tous_ecrans.yaml --output screenshots

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Capture terminée !" -ForegroundColor Green
    $nbScreenshots = (Get-ChildItem "$dossierScreenshots\*.png" -ErrorAction SilentlyContinue).Count
    Write-Host "$nbScreenshots screenshots capturés." -ForegroundColor Cyan
    Write-Host "Dossier : $dossierScreenshots" -ForegroundColor White
    Start-Process explorer.exe $dossierScreenshots
} else {
    Write-Host ""
    Write-Host "Erreur pendant la capture Maestro." -ForegroundColor Red
    Write-Host "Conseil : Lance capture-ecrans.ps1 (mode semi-auto) à la place." -ForegroundColor Yellow
}
