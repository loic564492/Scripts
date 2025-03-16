#!/bin/bash

# url inventaire http://localhost:62354/now


set -euo pipefail  # Arrête le script en cas d'erreur ou d'utilisation de variables non définies

# Variables
GLP_URL="https://example.com/path/to/glp-agent.pkg"  # Remplace par l'URL de l'agent GLP
PKG_NAME="glp-agent.pkg"
SERVICE_NAME="com.glp.agent"
INSTALL_PATH="/usr/local/bin/glp-agent"
LAUNCHD_PLIST="/Library/LaunchDaemons/$SERVICE_NAME.plist"
TMP_PKG="/tmp/$PKG_NAME"

# Fonction de log
log() { echo "[INFO] $1"; }

# Vérification des permissions et des dépendances
if [[ $EUID -ne 0 ]]; then
    echo "[ERREUR] Ce script doit être exécuté en tant que root." >&2
    exit 1
fi

for cmd in curl installer launchctl pkgutil df awk grep; do
    command -v "$cmd" &>/dev/null || { echo "[ERREUR] La commande '$cmd' est requise mais introuvable." >&2; exit 1; }
done

# Vérification de l'espace disque (en Mo)
DISK_FREE=$(df -m / | awk 'NR==2 {print $4}')
if (( DISK_FREE < 50 )); then
    echo "[ERREUR] Espace disque insuffisant (moins de 50 Mo disponibles)." >&2
    exit 1
fi

# Nettoyage après installation ou en cas d'erreur
cleanup() { rm -f "$TMP_PKG"; }
trap cleanup EXIT

# Désinstallation complète
uninstall() {
    log "Désinstallation de l'agent GLP..."
    launchctl bootout system "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$LAUNCHD_PLIST" "$INSTALL_PATH"
    log "Agent GLP supprimé."
}

# Téléchargement et installation
log "Téléchargement et installation de l'agent GLP..."
curl -fsSL -o "$TMP_PKG" "$GLP_URL"

# Vérification de la signature du package
if ! pkgutil --check-signature "$TMP_PKG" | grep -q "Status: signed by"; then
    echo "[ERREUR] Signature invalide ou inconnue." >&2
    exit 1
fi

installer -pkg "$TMP_PKG" -target / || { echo "[ERREUR] Échec de l'installation." >&2; exit 1; }

# Vérification de l'installation
if [[ ! -f "$INSTALL_PATH" ]]; then
    echo "[ERREUR] Installation échouée." >&2
    exit 1
fi

# Configuration du service launchd
log "Configuration du service au démarrage..."
cat <<EOF > "$LAUNCHD_PLIST"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_NAME</string>
    <key>ProgramArguments</key>
    <array>
        <string>$INSTALL_PATH</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>7200</integer>  # Modifier cette valeur (en secondes) pour changer la fréquence d'exécution
</dict>
</plist>
EOF

chmod 644 "$LAUNCHD_PLIST" && chown root:wheel "$LAUNCHD_PLIST"

# Démarrage du service
log "Démarrage du service..."
launchctl bootstrap system "$LAUNCHD_PLIST"

# Vérification du service
if launchctl list | grep -q "$SERVICE_NAME"; then
    log "L'agent GLP est installé et fonctionne."
else
    echo "[ERREUR] Service inactif." >&2
    exit 1
fi
