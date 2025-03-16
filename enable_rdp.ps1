# Script pour activer ou désactiver Remote Desktop (RDP) avec des mesures de sécurité renforcées

function Set-RDP {
    param (
        [bool]$Enable
    )

    if ($Enable) {
        Write-Host "Activation de Remote Desktop..."

        # Activer RDP dans le registre
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 0

        # Activer le pare-feu pour RDP
        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

        # Renforcer la sécurité en activant NLA (Network Level Authentication)
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name UserAuthentication -Value 1

        # Forcer l'utilisation du chiffrement TLS pour les connexions RDP
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name SecurityLayer -Value 2

        # Redémarrer le service RDP pour appliquer les modifications
        Restart-Service -Name TermService -Force

        Write-Host "Remote Desktop activé avec sécurité renforcée."
    } else {
        Write-Host "Désactivation de Remote Desktop..."

        # Désactiver RDP dans le registre
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -Value 1

        # Désactiver les règles du pare-feu pour RDP
        Disable-NetFirewallRule -DisplayGroup "Remote Desktop"

        # Redémarrer le service RDP pour appliquer les modifications
        Restart-Service -Name TermService -Force

        Write-Host "Remote Desktop désactivé."
    }
}

# Vérifier si l'utilisateur a les droits administrateur
$adminCheck = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$adminRole = [System.Security.Principal.WindowsPrincipal]::new($adminCheck).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $adminRole) {
    Write-Host "Ce script doit être exécuté en tant qu'administrateur." -ForegroundColor Red
    exit
}

# Menu interactif
$choice = Read-Host "Voulez-vous activer (A) ou désactiver (D) Remote Desktop ? [A/D]"

if ($choice -eq "A") {
    Set-RDP -Enable $true
} elseif ($choice -eq "D") {
    Set-RDP -Enable $false
} else {
    Write-Host "Choix invalide. Veuillez exécuter le script à nouveau."
}
