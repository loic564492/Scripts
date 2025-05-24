# Charger l'assembly nécessaire pour HttpClient
Add-Type -AssemblyName System.Net.Http

class QuickForgetClient {
    hidden [System.Net.Http.HttpClient] $httpClient

    QuickForgetClient() {
        $this.httpClient = [System.Net.Http.HttpClient]::new()
    }

    [void] SendSecret([string]$message, [int]$expireAfterViews, [int]$expireAfterHours) {
        $url = "https://quickforget.com/secret/submit/"

        # Données du formulaire
        $formData = @{
            secret              = $message
            expire_after_views  = "$expireAfterViews"
            expire_after        = "$expireAfterHours"
        }

        # Convertir les données du formulaire en contenu de formulaire URL-encodé
        $keyValuePairs = [System.Collections.Generic.List[System.Collections.Generic.KeyValuePair[string,string]]]::new()
        foreach ($key in $formData.Keys) {
            $keyValuePairs.Add([System.Collections.Generic.KeyValuePair[string,string]]::new($key, $formData[$key]))
        }

        $content = [System.Net.Http.FormUrlEncodedContent]::new($keyValuePairs)

        # Envoyer la requête POST
        $response = $this.httpClient.PostAsync($url, $content).Result

        if ($response.IsSuccessStatusCode) {
            $this.ProcessResponse($response.Content.ReadAsStringAsync().Result)
        } else {
            Write-Output "Échec de l'envoi du message. Code de statut : $($response.StatusCode)"
        }
    }

    [void] ProcessResponse([string]$htmlContent) {
        # Créer un document HTML
        $htmlDocument = New-Object -ComObject "HTMLFile"
        $htmlDocument.IHTMLDocument2_write($htmlContent)

        # Extraire le lien secret
        $secretUrlNode = $htmlDocument.getElementsByTagName('code')
        if ($secretUrlNode -ne $null -and $secretUrlNode.length -gt 0) {
            $secretUrl = $secretUrlNode.item(0).innerText
            Write-Output "Lien du secret : $secretUrl"
        } else {
            Write-Output "Lien du secret non trouvé."
        }

        # Extraire le message secret
        $secretMessageNode = $htmlDocument.getElementById('secret')
        if ($secretMessageNode -ne $null) {
            $secretMessage = $secretMessageNode.innerText
            Write-Output "Message secret : $secretMessage"
        } else {
            Write-Output "Message secret non trouvé."
        }

        # Extraire les détails d'expiration
        $expirationDetailsNode = $htmlDocument.getElementById('secret_meta')
        if ($expirationDetailsNode -ne $null) {
            $expirationDetails = $expirationDetailsNode.innerText
            Write-Output "Détails d'expiration : $expirationDetails"
        } else {
            Write-Output "Détails d'expiration non trouvés."
        }
    }
}

# Utilisation de la classe
$client = [QuickForgetClient]::new()
$client.SendSecret("Votre message secret", 2, 72)
