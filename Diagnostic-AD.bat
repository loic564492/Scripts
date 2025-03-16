@echo off
:: Script de diagnostic AD - Vérification d'un poste Windows
:: A exécuter en tant qu'administrateur

:: Vérifier l'appartenance au domaine
echo === Vérification du domaine ===
systeminfo | findstr /B /C:"Nom du domaine"

:: Vérifier l'adresse IP et le serveur DNS
echo === Vérification de la configuration réseau ===
ipconfig /all

:: Vérifier la connexion au contrôleur de domaine
echo === Test de connexion AD ===
nltest /dsgetdc:mondomaine.local
nltest /sc_verify:mondomaine.local

:: Vérifier l'intégration au domaine
echo === Vérification de l'intégration au domaine ===
netdom verify %COMPUTERNAME%

:: Vérifier l'état des services essentiels
echo === Vérification des services ===
sc query Netlogon
sc query Dnscache

:: Vérifier les profils utilisateurs
echo === Vérification des profils utilisateurs ===
dir C:\Users
echo === Vérification des profils dans le registre ===
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

:: Vérifier la présence de profils avec .BAK
echo === Vérification des profils avec extension .BAK ===
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" /s | findstr /I ".bak"

:: Vérifier les logs Windows
echo === Vérification des logs d'authentification ===
eventvwr.msc

:: Vérifier les GPO appliquées
echo === Vérification des GPO ===
gpresult /h C:\GPO-Report.html
echo Rapport généré à C:\GPO-Report.html

:: Vérifier la réplication AD (sur un serveur AD uniquement)
echo === Vérification de la réplication AD ===
repadmin /replsummary
dcdiag /v

echo === Diagnostic terminé. Vérifiez les résultats affichés. ===
pause
