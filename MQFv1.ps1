# Charger l'assembly nécessaire pour HttpClient
Add-Type -AssemblyName System.Net.Http

# Créer une instance de HttpClient
$httpClient = [System.Net.Http.HttpClient]::new()

# URL de soumission
$url = "https://quickforget.com/secret/submit/"

# Données du formulaire
$formData = @{
    secret              = "Votre message secret"
    expire_after_views  = "2"
    expire_after        = "72"
}

# Convertir les données du formulaire en contenu de formulaire URL-encodé
$keyValuePairs = [System.Collections.Generic.List[System.Collections.Generic.KeyValuePair[string,string]]]::new()
foreach ($key in $formData.Keys) {
    $keyValuePairs.Add([System.Collections.Generic.KeyValuePair[string,string]]::new($key, $formData[$key]))
}

$content = [System.Net.Http.FormUrlEncodedContent]::new($keyValuePairs)

# Envoyer la requête POST
$response = $httpClient.PostAsync($url, $content).Result

# Vérifier si la requête a réussi
if ($response.IsSuccessStatusCode) {
    # Lire le contenu de la réponse
    $htmlContent = $response.Content.ReadAsStringAsync().Result

    # Créer un document HTML
    $htmlDocument = New-Object -ComObject "HTMLFile"
    $htmlDocument.IHTMLDocument2_write($htmlContent)

    # Extraire le lien secret
    $secretUrlNode = $htmlDocument.getElementsByTagName('code')
    if ($secretUrlNode -ne $null -and $secretUrlNode.length -gt 0) {
        $secretUrl = $secretUrlNode.item(0).innerText
    } else {
        $secretUrl = "Lien du secret non trouvé."
    }

    # Extraire le message secret
    $secretMessageNode = $htmlDocument.getElementById('secret')
    if ($secretMessageNode -ne $null) {
        $secretMessage = $secretMessageNode.innerText
    } else {
        $secretMessage = "Message secret non trouvé."
    }

    # Extraire les détails d'expiration
    $expirationDetailsNode = $htmlDocument.getElementById('secret_meta')
    if ($expirationDetailsNode -ne $null) {
        $expirationDetails = $expirationDetailsNode.innerText
    } else {
        $expirationDetails = "Détails d'expiration non trouvés."
    }

    # Afficher les résultats
    Write-Output "Lien du secret : $secretUrl"
    Write-Output "Message secret : $secretMessage"
    Write-Output "Détails d'expiration : $expirationDetails"
} else {
    Write-Output "Échec de l'envoi du message."
}
