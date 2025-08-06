import requests
import os

url = "https://mi-orquestador-mvp.onrender.com/webhook"
headers = {
    "Content-Type": "application/json",
    "X-API-Key": "tu_clave_de_ejemplo_segura_aqui"  # <-- ¡USA LA CLAVE EXACTA DE RENDER AQUÍ!
}
data = {
    "origen": "prueba_script_python",
    "payload": {"nombre": "usuario", "id": 123}
}

try:
    response = requests.post(url, headers=headers, json=data, timeout=15)
    response.raise_for_status() # Lanza un error si el código de estado es 4xx o 5xx
    print(f"Estado HTTP: {response.status_code}")
    print(f"Respuesta del Orquestador: {response.json()}")
except requests.exceptions.HTTPError as e:
    print(f"Error HTTP: {e.response.status_code} - {e.response.text}")
except requests.exceptions.ConnectionError as e:
    print(f"Error de conexión: {e}")
except requests.exceptions.Timeout:
    print("La petición excedió el tiempo de espera (timeout).")
except requests.exceptions.RequestException as e:
    print(f"Error desconocido al enviar la petición: {e}")

