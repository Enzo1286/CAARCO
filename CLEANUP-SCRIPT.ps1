#!/usr/bin/env pwsh
# ════════════════════════════════════════════════════════════════════════════════
# 🧹 CAARCO PROJECT CLEANUP SCRIPT
# ════════════════════════════════════════════════════════════════════════════════
# Purpose: Remove unused files and organize the project
# Date: 2026-06-17
# ════════════════════════════════════════════════════════════════════════════════

$ErrorActionPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"
$projectRoot = $PSScriptRoot

# ════════════════════════════════════════════════════════════════
# PHASE 1: Supprimer les artifacts corrompus
# ════════════════════════════════════════════════════════════════

Write-Host "`n" -NoNewline
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔴 PHASE 1 — Suppression des artifacts corrompus" -ForegroundColor Red
Write-Host "═════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$corruptedFiles = @("{}", "r(new", "rej(new", "0")
$deletedCount = 0

foreach ($file in $corruptedFiles) {
    $path = Join-Path $projectRoot $file
    if (Test-Path $path) {
        try {
            Remove-Item -Force -LiteralPath $path -ErrorAction Stop
            Write-Host "  ✓ Supprimé: $file" -ForegroundColor Green
            $deletedCount++
        } catch {
            Write-Host "  ✗ Erreur lors de la suppression: $file" -ForegroundColor Red
        }
    } else {
        Write-Host "  • N'existe pas: $file" -ForegroundColor Gray
    }
}

Write-Host "`n✅ Phase 1 complétée ($deletedCount fichier(s) supprimé(s))" -ForegroundColor Green

# ════════════════════════════════════════════════════════════════
# PHASE 2: Créer la structure d'archivage et déplacer fichiers
# ════════════════════════════════════════════════════════════════

Write-Host "`n" -NoNewline
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📦 PHASE 2 — Création structure Archive et déplacement fichiers" -ForegroundColor Yellow
Write-Host "═════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# Créer les dossiers Archive
$archiveRoot = Join-Path $projectRoot "Archive"
$archiveDesign = Join-Path $archiveRoot "design-exports"
$archiveMedia = Join-Path $archiveRoot "old-media"
$archiveDocs = Join-Path $archiveRoot "docs-deprecated"

foreach ($dir in @($archiveRoot, $archiveDesign, $archiveMedia, $archiveDocs)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  ✓ Dossier créé: $([System.IO.Path]::GetFileName($dir))" -ForegroundColor Green
    } else {
        Write-Host "  • Dossier existe déjà: $([System.IO.Path]::GetFileName($dir))" -ForegroundColor Gray
    }
}

# Fichiers à archiver
Write-Host "`n  📄 Déplacement des fichiers HTML (Design System exports)..." -ForegroundColor Cyan
$htmlFiles = @(
    "Atelier CAARCO - Design System.html",
    "Atelier CAARCO - Design System-print.html",
    "CAARCO Hi-Fi.html",
    "CAARCO Wireframes.html",
    "CAARCO Brand Identity.html"
)

$movedCount = 0
foreach ($file in $htmlFiles) {
    $source = Join-Path $projectRoot $file
    if (Test-Path $source) {
        $dest = Join-Path $archiveDesign $file
        Move-Item -LiteralPath $source -Destination $dest -Force -ErrorAction SilentlyContinue
        Write-Host "    ✓ Archivé: $file" -ForegroundColor Green
        $movedCount++
    }
}

# Déplacer le dossier Design complet
Write-Host "`n  📁 Déplacement du dossier Design/..." -ForegroundColor Cyan
$designFolder = Join-Path $projectRoot "Design"
if (Test-Path $designFolder) {
    $destDesign = Join-Path $archiveDesign "Design-mockups"
    Move-Item -Path $designFolder -Destination $destDesign -Force -ErrorAction SilentlyContinue
    Write-Host "    ✓ Dossier Design/ archivé" -ForegroundColor Green
    $movedCount++
}

# Déplacer les fichiers media volumineux si détectés
Write-Host "`n  📹 Vérification des fichiers média volumineux..." -ForegroundColor Cyan
$mediaFiles = @("*.apk", "*.mp4", "files.zip")
$mediaFound = $false

foreach ($pattern in $mediaFiles) {
    $files = Get-ChildItem -Path $projectRoot -Filter $pattern -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $source = $file.FullName
        $dest = Join-Path $archiveMedia $file.Name
        Move-Item -LiteralPath $source -Destination $dest -Force -ErrorAction SilentlyContinue
        Write-Host "    ✓ Archivé: $($file.Name) ($([math]::Round($file.Length/1MB, 2)) MB)" -ForegroundColor Green
        $movedCount++
        $mediaFound = $true
    }
}

if (-not $mediaFound) {
    Write-Host "    • Aucun fichier média volumineux trouvé" -ForegroundColor Gray
}

Write-Host "`n✅ Phase 2 complétée ($movedCount éléments archivés)" -ForegroundColor Green

# ════════════════════════════════════════════════════════════════
# PHASE 3: Renommer les migrations doublons
# ════════════════════════════════════════════════════════════════

Write-Host "`n" -NoNewline
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🔄 PHASE 3 — Renommage des migrations avec numéros doublons" -ForegroundColor Magenta
Write-Host "═════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

$migrationsPath = Join-Path $projectRoot "supabase\migrations"
$renamedCount = 0

# Mapping des migrations à renommer
# Format: @("ancien_pattern", "nouveau_nom")
$migrations = @(
    @("042_feature_maintenance_mode.sql", "042a_feature_maintenance_mode.sql"),
    @("042_fix_phone_email_normalization.sql", "042b_fix_phone_email_normalization.sql"),
    @("056_motivation_system.sql", "056b_motivation_system.sql"),
    @("056_tables_motivation.sql", "056c_tables_motivation.sql"),
    @("057_fonctions_motivation.sql", "057b_fonctions_motivation.sql"),
    @("058_leaderboard_bonus_mensuel.sql", "058b_leaderboard_bonus_mensuel.sql"),
    @("060_fix_calculer_classement_mensuel.sql", "060b_fix_calculer_classement_mensuel.sql"),
    @("062_terminer_livraison_sans_otp.sql", "062b_terminer_livraison_sans_otp.sql")
)

if (Test-Path $migrationsPath) {
    Write-Host "  📂 Migrations trouvées dans: $migrationsPath`n" -ForegroundColor Cyan
    
    foreach ($migration in $migrations) {
        $oldName = $migration[0]
        $newName = $migration[1]
        $oldPath = Join-Path $migrationsPath $oldName
        $newPath = Join-Path $migrationsPath $newName
        
        if (Test-Path $oldPath) {
            try {
                Rename-Item -LiteralPath $oldPath -NewName $newName -Force -ErrorAction Stop
                Write-Host "  ✓ Renommée: $oldName → $newName" -ForegroundColor Green
                $renamedCount++
            } catch {
                Write-Host "  ✗ Erreur renommage: $oldName" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`n✅ Phase 3 complétée ($renamedCount migration(s) renommée(s))" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Dossier migrations non trouvé: $migrationsPath" -ForegroundColor Yellow
}

# ════════════════════════════════════════════════════════════════
# RÉSUMÉ FINAL
# ════════════════════════════════════════════════════════════════

Write-Host "`n" -NoNewline
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✨ NETTOYAGE TERMINÉ" -ForegroundColor Green
Write-Host "═════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

Write-Host "`n📊 Résumé des actions:`n" -ForegroundColor Green
Write-Host "  Phase 1: $deletedCount artifact(s) supprimé(s)" -ForegroundColor White
Write-Host "  Phase 2: $movedCount fichier(s)/dossier(s) archivé(s)" -ForegroundColor White
Write-Host "  Phase 3: $renamedCount migration(s) renommée(s)" -ForegroundColor White

Write-Host "`n📁 Structure Archive créée à: $projectRoot\Archive\n" -ForegroundColor Cyan

# Calculer l'espace dans Archive
$archiveSize = (Get-ChildItem -Path $archiveRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
if ($archiveSize) {
    $archiveSizeMB = [math]::Round($archiveSize / 1MB, 2)
    Write-Host "💾 Espace utilisé dans Archive: $archiveSizeMB MB" -ForegroundColor Yellow
}

Write-Host "`n✅ ✅ ✅ Nettoyage réussi ! ✅ ✅ ✅`n" -ForegroundColor Green
Write-Host "Prochaines étapes recommandées:" -ForegroundColor Cyan
Write-Host "  1. Vérifier que tout fonctionne normalement" -ForegroundColor Gray
Write-Host "  2. Faire un commit Git: git add . && git commit -m 'Cleanup: Remove unused files and organize archives'" -ForegroundColor Gray
Write-Host "  3. Optionnel: créer ARCHIVE_MANIFEST.md pour documenter" -ForegroundColor Gray
Write-Host "`n"

Read-Host "Appuie sur Entrée pour fermer"
