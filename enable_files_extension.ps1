# Script pour activer ou désactiver les options d'affichage dans l'Explorateur Windows

function Set-ExplorerOptions {
    param (
        [bool]$Enable
    )

    # Définition des valeurs en fonction du choix
    $hideFileExtValue = if ($Enable) { 0 } else { 1 }   # Extensions de fichiers visibles ou non
    $hiddenFilesValue = if ($Enable) { 1 } else { 2 }   # Afficher/Masquer fichiers et dossiers cachés
    $superHiddenValue = if ($Enable) { 1 } else { 0 }   # Afficher/Masquer fichiers système protégés
    $checkBoxesValue  = if ($Enable) { 1 } else { 0 }   # Activer/Désactiver les cases à cocher

    # Appliquer les modifications dans le registre
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value $hideFileExtValue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -Value $hiddenFilesValue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowSuperHidden -Value $superHiddenValue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name AutoCheckSelect -Value $checkBoxesValue

    # Redémarrer l'Explorateur pour appliquer les changements
    Write-Host "Modification effectuée. Redémarrage de l'explorateur..."
    Stop-Process -Name explorer -Force
}

# Menu interactif
$choice = Read-Host "Voulez-vous activer (A) ou désactiver (D) les options d'affichage ? [A/D]"

if ($choice -eq "A") {
    Set-ExplorerOptions -Enable $true
    Write-Host " Options activées !"
} elseif ($choice -eq "D") {
    Set-ExplorerOptions -Enable $false
    Write-Host " Options désactivées !"
} else {
    Write-Host " Choix invalide. Veuillez exécuter le script à nouveau."
}
