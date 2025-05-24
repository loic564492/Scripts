<#
.SYNOPSIS
    Sauvegarde le disque OS d'une VM Azure en VHD via snapshot et URL SAS.

.DESCRIPTION
    Ce script PowerShell :
    - Se connecte à Azure avec un Service Principal
    - Arrête une VM
    - Crée un snapshot du disque OS
    - Génère une URL SAS valable 24h
    - Redémarre immédiatement la VM
    - Propose ensuite de télécharger le VHD en local
    - Log toutes les étapes dans un fichier `backup-log.txt`

.INPUTS
    Requiert un Service Principal avec accès au Resource Group cible.

.OUTPUTS
    Une URL SAS et un fichier VHD local si téléchargement accepté.

.LINK
    Documentation officielle :
    - https://learn.microsoft.com/fr-fr/cli/azure/snapshot?view=azure-cli-latest
    - https://learn.microsoft.com/fr-fr/cli/azure/snapshot?view=azure-cli-latest#az-snapshot-create
    - https://learn.microsoft.com/fr-fr/cli/azure/snapshot?view=azure-cli-latest#az-snapshot-grant-access
    - https://learn.microsoft.com/fr-fr/azure/virtual-machines/linux/tutorial-backup-vm-cli

.VERSION
    1.2.0

.AUTHOR
    Loic

.DATE
    2025-05-24

.NOTES
    Optimisations possibles :
    - Rotation automatique des snapshots
    - Intégration pipeline ou Azure Automation
    - Vérification VHD, tagging, logging avancé, notifications
#>

function Write-Info($message) {
    Write-Host $message -ForegroundColor Cyan
    Add-Content -Path $logFile -Value "[INFO]  $message"
}

function Write-WarningMessage($message) {
    Write-Host $message -ForegroundColor Yellow
    Add-Content -Path $logFile -Value "[WARN]  $message"
}

function Write-Success($message) {
    Write-Host $message -ForegroundColor Green
    Add-Content -Path $logFile -Value "[OK]    $message"
}

$logFile = "backup-log.txt"
"" | Set-Content -Path $logFile
Add-Content -Path $logFile -Value "=== Sauvegarde de VM - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

Write-Info "`n=== PARAMÈTRES ==="
$resourceGroupName = Read-Host "Nom du groupe de ressources de la VM"
$vmName = Read-Host "Nom de la VM"
$location = Read-Host "Localisation (ex: francecentral)"

Write-Info "`n=== AUTHENTIFICATION AZURE ==="
$clientId = Read-Host "App ID du Service Principal"
$clientSecret = Read-Host "Secret du SP (sera masqué)" -AsSecureString
$tenantId = Read-Host "Tenant ID"

$secretPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($clientSecret)
)

Write-Info "Connexion à Azure..."
az login --service-principal --username $clientId --password $secretPlainText --tenant $tenantId | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-WarningMessage "Échec de connexion à Azure."
    exit 1
}
Write-Success "Connecté à Azure."

Write-Info "`nArrêt et désallocation de la VM..."
az vm deallocate --name $vmName --resource-group $resourceGroupName --no-wait
az vm wait --name $vmName --resource-group $resourceGroupName --deallocated
Write-Success "VM désallouée."

Write-Info "`nRécupération du disque OS..."
$osDiskId = az vm show --name $vmName --resource-group $resourceGroupName --query "storageProfile.osDisk.managedDisk.id" -o tsv
if (-not $osDiskId) {
    Write-WarningMessage "Disque OS introuvable."
    exit 1
}
$osDiskName = ($osDiskId -split "/")[-1]
Write-Success "Disque OS : $osDiskName"

$snapshotName = "$osDiskName-snap-$(Get-Date -Format 'yyyyMMddHHmmss')"
Write-Info "`nCréation du snapshot : $snapshotName"
az snapshot create `
    --resource-group $resourceGroupName `
    --name $snapshotName `
    --source $osDiskId `
    --location $location `
    --output none
Write-Success "Snapshot créé."

Write-Info "`nGénération de l'URL SAS (valide 24h)..."
$sasUrl = az snapshot grant-access `
    --duration-in-seconds 86400 `
    --name $snapshotName `
    --resource-group $resourceGroupName `
    --query accessSas -o tsv
Write-Success "URL SAS générée."

Write-Info "`n=== URL SAS POUR TÉLÉCHARGEMENT ==="
Write-Host $sasUrl -ForegroundColor White
Add-Content -Path $logFile -Value "[SAS]   $sasUrl"

Write-Info "`nRedémarrage immédiat de la VM..."
az vm start --name $vmName --resource-group $resourceGroupName
Write-Success "VM redémarrée."

$response = Read-Host "`nTélécharger maintenant ? (oui/non)"
if ($response -match "^oui$") {
    $fileName = "$snapshotName.vhd"
    Write-Info "`nTéléchargement vers : $fileName"
    curl.exe -L $sasUrl -o $fileName
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Téléchargement terminé."
        Write-WarningMessage "Veuillez tester le fichier VHD téléchargé pour vous assurer qu'il est lisible et exploitable."
        Write-WarningMessage "Ne supprimez le snapshot qu'après avoir validé le bon fonctionnement du fichier."
    } else {
        Write-WarningMessage "Erreur pendant le téléchargement."
    }
} else {
    Write-Info "`nCommande à utiliser plus tard pour télécharger :"
    $downloadCommand = "curl.exe -L '$sasUrl' -o '$snapshotName.vhd'"
    Write-Host $downloadCommand -ForegroundColor White
    Add-Content -Path $logFile -Value "[INFO]  Commande curl : $downloadCommand"
}

Write-Success "`nScript terminé. Log disponible dans '$logFile'"
