@echo off
title CAARCO - Telephone en Direct
echo ========================================================
echo    CAARCO - Affichage du telephone en direct sur PC
echo ========================================================
echo.
echo Connexion au telephone via USB...
"C:\Users\Cedric Timene\AppData\Local\Microsoft\WinGet\Packages\Genymobile.scrcpy_Microsoft.Winget.Source_8wekyb3d8bbwe\scrcpy-win64-v4.1\scrcpy.exe" --always-on-top --window-title "CAARCO - Telephone en Direct"
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERREUR] Impossible d'afficher le telephone.
    echo Verifiez que le telephone est bien branche en USB et que le 'Debogage USB' est active.
    echo.
    pause
)
