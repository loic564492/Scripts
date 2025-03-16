function Get-LicenseInfo {
    Clear-Host
    Write-Host "Verification des informations de licence..." -ForegroundColor Cyan
    Start-Process -FilePath "cscript" -ArgumentList "//Nologo C:\Windows\System32\slmgr.vbs /dlv" -NoNewWindow -Wait
}

function Get-ProductKey {
    Clear-Host
    Write-Host "Recuperation de la cle de produit..." -ForegroundColor Cyan
    $KeyPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
    try {
        $ProductKey = (Get-ItemProperty -Path $KeyPath -ErrorAction Stop).BackupProductKeyDefault
        if ($ProductKey) {
            Write-Host "Cle de produit trouvee : $ProductKey" -ForegroundColor Green
        } else {
            Write-Host "Aucune cle de produit trouvee." -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors de l'acces a la cle de produit." -ForegroundColor Red
    }
}   

function Activate-License {
    Clear-Host
    Write-Host "Activation de la licence Windows..." -ForegroundColor Cyan
    Start-Process -FilePath "cscript" -ArgumentList "//Nologo C:\Windows\System32\slmgr.vbs /ato" -NoNewWindow -Wait
    Write-Host "Licence activee avec succes (si cle valide)." -ForegroundColor Green
}

function Deactivate-License {
    Clear-Host
    Write-Host "Suppression de la cle de produit..." -ForegroundColor Cyan
    $confirm = Read-Host "Etes-vous sur de vouloir desactiver la licence ? (O/N)"
    if ($confirm -match "^[Oo]$") {
        Start-Process -FilePath "cscript" -ArgumentList "//Nologo C:\Windows\System32\slmgr.vbs /upk" -NoNewWindow -Wait
        Write-Host "Licence desinstallee. Un redemarrage peut etre necessaire." -ForegroundColor Yellow
    } else {
        Write-Host "Annulation de l'operation." -ForegroundColor Gray
    }
}

function Install-License {
    Clear-Host
    $NewKey = Read-Host "Entrez la nouvelle cle de produit (format : XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)"
    if ($NewKey -match "^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$") {
        Write-Host "Installation de la nouvelle cle de licence..." -ForegroundColor Cyan
        Start-Process -FilePath "cscript" -ArgumentList "//Nologo C:\Windows\System32\slmgr.vbs /ipk $NewKey" -NoNewWindow -Wait
        Write-Host "Cle installee avec succes." -ForegroundColor Green
    } else {
        Write-Host "Format de cle invalide. Verifiez et reessayez." -ForegroundColor Red
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "===================================" -ForegroundColor Yellow
    Write-Host "   Gestion des Licences Windows   " -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Yellow
    Write-Host "1 - Verifier les informations de licence"
    Write-Host "2 - Afficher la cle de produit"
    Write-Host "3 - Activer la licence"
    Write-Host "4 - Desinstaller la cle de licence"
    Write-Host "5 - Installer une nouvelle cle de produit"
    Write-Host "0 - Quitter"
}

do {
    Show-Menu
    $Choice = Read-Host "\nChoisissez une option"
    switch ($Choice) {
        "1" { Get-LicenseInfo }
        "2" { Get-ProductKey }
        "3" { Activate-License }
        "4" { Deactivate-License }
        "5" { Install-License }
        "0" { Write-Host "Au revoir !" -ForegroundColor Magenta; break }
        default { Write-Host "Option invalide. Essayez encore." -ForegroundColor Red }
    }
    Start-Sleep -Seconds 3
} while ($Choice -ne "0")
