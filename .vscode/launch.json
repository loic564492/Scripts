# === Paramètres à personnaliser ===
$message = "Ceci est un message temporaire"
$ttl = 10       # Durée en minutes
$views = 1      # Nombre de vues avant expiration

# === Construction de la requête ===
$body = @{
    message = $message
    ttl     = $ttl
    views   = $views
}

$headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
}

# === Envoi de la requête POST ===
try {
    $null = Invoke-WebRequest -Uri 'https://quickforget.com/' `
                              -Method POST `
                              -Body $body `
                              -ContentType 'application/x-www-form-urlencoded' `
                              -Headers $headers `
                              -MaximumRedirection 0 `
                              -ErrorAction Stop
} catch {
    if ($_.Exception.Response.StatusCode.value__ -eq 302) {
        $location = $_.Exception.Response.Headers['Location']
        if (-not $location.StartsWith("http")) {
            $url = "https://quickforget.com$location"
        } else {
            $url = $location
        }

        Write-Host "✅ Message créé avec succès !"
        Write-Host "🔗 Lien : $url"

        # Tentative de copie dans le presse-papier si autorisé
        try {
            Set-Clipboard -Value $url
            Write-Host "📋 Lien copié dans le presse-papier."
        } catch {
            Write-Warning "❗ Impossible de copier dans le presse-papier (non autorisé dans ce contexte)."
        }
    } else {
        Write-Error "❌ Erreur HTTP : $($_.Exception.Message)"
    }
}
