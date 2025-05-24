import requests
from bs4 import BeautifulSoup

def envoyer_secret(message, expire_after_views, expire_after_hours):
    url = "https://quickforget.com/secret/submit/"

    # Données du formulaire
    data = {
        "secret": message,
        "expire_after_views": expire_after_views,
        "expire_after": expire_after_hours
    }

    # Envoyer la requête POST
    response = requests.post(url, data=data)

    # Vérifier si la requête a réussi
    if response.status_code == 200:
        return response.text
    else:
        print(f"Échec de l'envoi du message. Code de statut : {response.status_code}")
        return None

def parser_reponse(html_content):
    # Analyser le contenu HTML
    soup = BeautifulSoup(html_content, 'html.parser')

    # Extraire le lien secret
    secret_url = soup.find('code').text.strip()

    # Extraire le message secret
    secret_message = soup.find(id='secret').text.strip()

    # Extraire les détails d'expiration
    expiration_details = soup.find(id='secret_meta').text.strip()

    return secret_url, secret_message, expiration_details

def main():
    message = "Votre message secretzz"
    expire_after_views = 2
    expire_after_hours = 72

    # Envoyer le secret et obtenir la réponse HTML
    html_content = envoyer_secret(message, expire_after_views, expire_after_hours)

    if html_content:
        # Parser la réponse pour obtenir les informations
        secret_url, secret_message, expiration_details = parser_reponse(html_content)

        print("Lien du secret :", secret_url)
        print("Message secret :", secret_message)
        print("Détails d'expiration :", expiration_details)

if __name__ == "__main__":
    main()
