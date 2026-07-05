# ═══════════════════════════════════════════════════
# CAARCO — Capture automatique de tous les écrans
# Usage : .\capture-ecrans.ps1
# Prérequis : ADB installé + téléphone connecté en USB (débogage USB activé)
# ═══════════════════════════════════════════════════

$dossierSortie = "$PSScriptRoot\..\screenshots\$(Get-Date -Format 'yyyy-MM-dd_HH-mm')"
New-Item -ItemType Directory -Force -Path $dossierSortie | Out-Null

# Liste des écrans à capturer (dans l'ordre recommandé)
$ecrans = @(
    # ── ONBOARDING ─────────────────────────────────
    "01_splash_screen",
    "02_onboarding_slide_1",
    "03_onboarding_slide_2",
    "04_onboarding_slide_3",
    "05_choix_role",
    "06_auth_saisie_telephone",
    "07_auth_saisie_otp",

    # ── CLIENT ─────────────────────────────────────
    "08_client_accueil_carte",
    "09_client_saisie_adresses",
    "10_client_details_colis",
    "11_client_photos_colis",
    "12_client_estimation_prix",
    "13_client_paiement_mobile_money",
    "14_client_recherche_transporteur",
    "15_client_suivi_gps",
    "16_client_otp_livraison",
    "17_client_notation_transporteur",
    "18_client_historique_courses",
    "19_client_profil",

    # ── TRANSPORTEUR ───────────────────────────────
    "20_tr_dashboard",
    "21_tr_course_entrante",
    "22_tr_course_acceptee",
    "23_tr_navigation_vers_client",
    "24_tr_course_en_cours",
    "25_tr_saisie_otp",
    "26_tr_livraison_confirmee",
    "27_tr_gains",
    "28_tr_profil",
    "29_tr_recharge_wallet",

    # ── EXTRAS ─────────────────────────────────────
    "30_mode_sombre",
    "31_notification_course"
)

Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  CAARCO — Capture des ecrans" -ForegroundColor Green
Write-Host "  Dossier : $dossierSortie" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""

# Vérifier qu'un appareil ADB est connecté
$appareil = adb devices | Select-String -Pattern "device$"
if (-not $appareil) {
    Write-Host "ERREUR : Aucun appareil Android détecte." -ForegroundColor Red
    Write-Host "Vérifie que :" -ForegroundColor Yellow
    Write-Host "  1. Le cable USB est branché" -ForegroundColor Yellow
    Write-Host "  2. Le debogage USB est activé (Options développeur)" -ForegroundColor Yellow
    Write-Host "  3. Tu as accepté la popup 'Autoriser le débogage USB' sur le téléphone" -ForegroundColor Yellow
    Read-Host "Appuie sur Entrée pour quitter"
    exit 1
}

Write-Host "Appareil détecté : $($appareil.ToString().Trim())" -ForegroundColor Green
Write-Host ""
Write-Host "INSTRUCTIONS :" -ForegroundColor Yellow
Write-Host "  → Navigue vers l'écran demandé sur ton téléphone" -ForegroundColor White
Write-Host "  → Appuie sur ENTRÉE pour capturer" -ForegroundColor White
Write-Host "  → Tape 'r' + ENTRÉE pour recapturer le même écran" -ForegroundColor White
Write-Host "  → Tape 's' + ENTRÉE pour sauter un écran" -ForegroundColor White
Write-Host "  → Tape 'q' + ENTRÉE pour terminer" -ForegroundColor White
Write-Host ""

$compteur = 0
$total = $ecrans.Count

foreach ($nomEcran in $ecrans) {
    $compteur++
    $progression = "[${compteur}/${total}]"

    Write-Host "─────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "$progression Écran suivant :" -ForegroundColor Cyan
    Write-Host "  $nomEcran" -ForegroundColor White
    Write-Host ""

    $continuer = $true
    while ($continuer) {
        $reponse = Read-Host "  ENTRÉE=capturer | r=recapturer | s=sauter | q=quitter"

        if ($reponse -eq 'q') {
            Write-Host ""
            Write-Host "Capture terminée manuellement." -ForegroundColor Yellow
            Write-Host "$($compteur - 1) écrans capturés sur $total." -ForegroundColor Cyan
            Write-Host "Dossier : $dossierSortie" -ForegroundColor Green
            exit 0
        }

        if ($reponse -eq 's') {
            Write-Host "  [IGNORÉ] $nomEcran" -ForegroundColor DarkGray
            $continuer = $false
            continue
        }

        # Capturer via ADB
        $fichierTemp = "/sdcard/caarco_capture_temp.png"
        $fichierLocal = "$dossierSortie\$nomEcran.png"

        Write-Host "  Capture en cours..." -ForegroundColor DarkGray
        adb shell screencap -p $fichierTemp
        adb pull $fichierTemp $fichierLocal 2>$null
        adb shell rm $fichierTemp

        if (Test-Path $fichierLocal) {
            $taille = [math]::Round((Get-Item $fichierLocal).Length / 1KB, 1)
            Write-Host "  ✓ Sauvegardé : $nomEcran.png ($taille KB)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Erreur lors de la capture. Réessaie (r)." -ForegroundColor Red
        }

        if ($reponse -ne 'r') {
            $continuer = $false
        }
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green
Write-Host "  TERMINÉ ! $total écrans traités." -ForegroundColor Green
Write-Host "  Dossier de sortie :" -ForegroundColor Cyan
Write-Host "  $dossierSortie" -ForegroundColor White
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Green

# Ouvrir le dossier automatiquement
Start-Process explorer.exe $dossierSortie
