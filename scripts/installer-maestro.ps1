# CAARCO — Installer Maestro (outil de capture automatique)
# Usage : .\installer-maestro.ps1

Write-Host "Installation de Maestro..." -ForegroundColor Green

# Télécharger et installer Maestro
$env:MAESTRO_VERSION = "1.38.1"
Invoke-WebRequest -Uri "https://github.com/mobile-dev-inc/maestro/releases/download/cli-$env:MAESTRO_VERSION/maestro-win.zip" -OutFile "$env:TEMP\maestro.zip"
Expand-Archive -Path "$env:TEMP\maestro.zip" -DestinationPath "$env:USERPROFILE\.maestro" -Force
$env:PATH += ";$env:USERPROFILE\.maestro\bin"

# Ajouter au PATH permanent
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*maestro*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$env:USERPROFILE\.maestro\bin", "User")
}

Write-Host "Maestro installe ! Redemarrer PowerShell puis lancer capture-auto.ps1" -ForegroundColor Green
