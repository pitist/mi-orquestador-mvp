#!/bin/bash

echo "🚀 Iniciando configuración automática para tu orquestador en Termux..."

# --- 1. Actualizar Termux ---
echo -e "\n--- Actualizando Termux y paquetes esenciales ---"
pkg update -y && pkg upgrade -y
pkg install -y git python python-pip

# --- 2. Pedir URL del Repositorio y Clonar ---
echo -e "\n--- Clonando tu Repositorio de GitHub ---"
read -p "Por favor, introduce la URL HTTPS de tu repositorio de GitHub (ej. https://github.com/tu_usuario/tu_repo.git): " GITHUB_REPO_URL

# Extraer el nombre de la carpeta del repositorio
REPO_NAME=$(basename "$GITHUB_REPO_URL" .git)

if [ -d "$REPO_NAME" ]; then
    echo "El directorio '$REPO_NAME' ya existe. Saltando la clonación."
    cd "$REPO_NAME" || { echo "Error: No se pudo entrar al directorio '$REPO_NAME'."; exit 1; }
else
    echo "Clonando repositorio '$GITHUB_REPO_URL'..."
    git clone "$GITHUB_REPO_URL" || { echo "Error: Falló la clonación del repositorio. Verifica la URL."; exit 1; }
    cd "$REPO_NAME" || { echo "Error: No se pudo entrar al directorio '$REPO_NAME'."; exit 1; }
fi

echo "Ubicación actual: $(pwd)"

# --- 3. Crear Estructura de Carpetas y Archivos Básicos ---
echo -e "\n--- Creando estructura de carpetas y archivos esenciales ---"

# Crear carpeta src/python si no existe
mkdir -p src/python

# Crear requirements.txt
echo "Creando requirements.txt..."
cat <<EOF > requirements.txt
flask==3.0.3
gunicorn==22.0.0
requests==2.32.3
python-dotenv==1.0.1
Pillow==10.3.0
EOF
echo "requirements.txt creado."

# Crear Procfile
echo "Creando Procfile..."
cat <<EOF > Procfile
web: gunicorn src.python.main_orchestrator:app --timeout 120
EOF
echo "Procfile creado."

# Crear .gitignore
echo "Creando .gitignore para evitar subir archivos sensibles..."
cat <<EOF > .gitignore
.env
__pycache__/
*.pyc
.DS_Store
EOF
echo ".gitignore creado."

# --- 4. Crear main_orchestrator.py y Copiar Contenido ---
echo -e "\n--- Creando src/python/main_orchestrator.py con el código base ---"
cat <<'EOF' > src/python/main_orchestrator.py
from flask import Flask, request, jsonify
import os
import requests
import logging
from datetime import datetime, timedelta
from PIL import Image
import io
from dotenv import load_dotenv

# --- Configuración de Logging ---
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- Cargar Variables de Entorno (Solo para uso LOCAL) ---
if os.getenv('FLASK_ENV') != 'production':
    load_dotenv() 

app = Flask(__name__)

# --- Función Auxiliar para Obtener Claves API Seguras ---
def get_api_key(key_name):
    key = os.getenv(key_name)
    if not key:
        logging.error(f"ERROR CRÍTICO: Variable de entorno '{key_name}' no configurada.")
    return key

# --- Ruta Home para verificar que la app está viva ---
@app.route('/', methods=['GET'])
def home():
    logging.info("Petición GET a la raíz recibida. Aplicación activa.")
    return jsonify({"status": "activo", "message": "Orquestador de eventos Python funcionando."}), 200

# --- 1. y 2. Automatización de E-commerce y Gestión de Leads/CRM ---
@app.route('/webhook/nuevo-pedido-o-lead', methods=['POST'])
def handle_new_order_or_lead_webhook():
    logging.info("Webhook de nueva orden/lead recibido.")
    data = request.json

    if not data:
        logging.warning("Petición recibida sin datos JSON válidos.")
        return jsonify({"message": "Error: Datos no válidos o vacíos"}), 400

    order_id = data.get('id', 'N/A')
    customer_email = data.get('customer', {}).get('email') or data.get('email')
    customer_name = data.get('customer', {}).get('first_name', '') + ' ' + data.get('customer', {}).get('last_name', '')
    product_items = data.get('line_items', [])

    logging.info(f"Procesando orden/lead ID: {order_id}, Email: {customer_email}")

    slack_webhook_url = get_api_key('SLACK_PEDIDOS_WEBHOOK_URL')
    if slack_webhook_url:
        message_text = f"🚨 ¡Nueva Venta/Lead! 🚨\nOrden/ID: {order_id}\nCliente: {customer_name} ({customer_email})\nItems: {', '.join([item['name'] for item in product_items]) if product_items else 'N/A'}"
        try:
            requests.post(slack_webhook_url, json={'text': message_text}, timeout=10)
            logging.info(f"Notificación enviada a Slack para {order_id}.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al enviar notificación a Slack para {order_id}: {e}")

    inventory_api_base_url = get_api_key('INVENTORY_API_BASE_URL')
    inventory_api_key = get_api_key('INVENTORY_API_KEY')
    if inventory_api_base_url and inventory_api_key and product_items:
        for item in product_items:
            product_id = item.get('product_id')
            quantity = item.get('quantity')
            if product_id and quantity:
                inventory_payload = {'product_id': product_id, 'deduct_quantity': quantity}
                try:
                    response = requests.post(
                        f"{inventory_api_base_url}/products/{product_id}/deduct",
                        json=inventory_payload,
                        headers={'Authorization': f'Bearer {inventory_api_key}'},
                        timeout=10
                    )
                    response.raise_for_status()
                    logging.info(f"Inventario actualizado para producto {product_id} (Orden {order_id}).")
                except requests.exceptions.RequestException as e:
                    logging.error(f"Error al actualizar inventario para producto {product_id} (Orden {order_id}): {e}")

    crm_api_base_url = get_api_key('CRM_API_BASE_URL')
    crm_api_key = get_api_key('CRM_API_KEY')
    if crm_api_base_url and crm_api_key and customer_email:
        crm_payload = {
            'email': customer_email,
            'firstName': data.get('customer', {}).get('first_name'),
            'lastName': data.get('customer', {}).get('last_name'),
            'source': 'E-commerce' if product_items else 'Web Form'
        }
        try:
            response = requests.post(
                f"{crm_api_base_url}/contacts",
                json=crm_payload,
                headers={'Authorization': f'Bearer {crm_api_key}'},
                timeout=10
            )
            response.raise_for_status()
            logging.info(f"Cliente/Lead {customer_email} añadido/actualizado en CRM para {order_id}.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al añadir/actualizar cliente/lead {customer_email} en CRM para {order_id}: {e}")

    return jsonify({"message": f"Webhook para orden/lead {order_id} procesado correctamente."}), 200

# --- 3. Notificaciones Personalizadas y Alertas de Eventos ---
@app.route('/webhook/alertas', methods=['POST'])
def handle_alerts_webhook():
    logging.info("Webhook de alertas recibido.")
    data = request.json

    if not data:
        logging.warning("Petición recibida sin datos JSON válidos para alerta.")
        return jsonify({"message": "Error: Datos no válidos o vacíos"}), 400

    event_type = data.get('type')
    event_source = data.get('source', 'Desconocido')
    event_details = data.get('details', {})

    alert_message = f"🚨 Alerta de {event_source}: {event_type}\nDetalles: {event_details.get('message', 'N/A')}"
    target_webhook_url = None

    if event_type == 'server_down':
        alert_message = f"🔴 ¡CRÍTICO! Servidor {event_details.get('server_name')} CAÍDO. Error: {event_details.get('error_code')}"
        target_webhook_url = get_api_key('SLACK_OPS_ALERT_WEBHOOK_URL')
    elif event_type == 'negative_review':
        alert_message = f"😠 Reseña Negativa Nueva: {event_details.get('platform')} - '{event_details.get('review_text')}'"
        target_webhook_url = get_api_key('SLACK_CUSTOMER_SERVICE_WEBHOOK_URL')
    elif event_type == 'payment_failed':
        alert_message = f"💰 Pago Fallido: Cliente {event_details.get('customer_id')} - Motivo: {event_details.get('reason')}"
        target_webhook_url = get_api_key('SLACK_FINANCE_WEBHOOK_URL')
    else:
        logging.info(f"Tipo de evento '{event_type}' no reconocido o no configurado para alerta.")
        return jsonify({"message": f"Tipo de evento '{event_type}' ignorado o no manejado"}), 200

    if target_webhook_url:
        try:
            requests.post(target_webhook_url, json={'text': alert_message}, timeout=10)
            logging.info(f"Alerta '{event_type}' enviada a {event_source}.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al enviar alerta '{event_type}': {e}")
    else:
        logging.warning(f"URL de webhook de destino no configurada para el evento '{event_type}'.")

    return jsonify({"message": f"Alerta de evento '{event_type}' procesada."}), 200

# --- 4. Enriquecimiento y Validación de Datos en Tiempo Real ---
@app.route('/webhook/enriquecer-lead', methods=['POST'])
def handle_enrich_lead_webhook():
    logging.info("Webhook de enriquecimiento de lead recibido.")
    data = request.json

    if not data:
        logging.warning("Petición recibida sin datos JSON válidos para enriquecimiento.")
        return jsonify({"message": "Error: Datos no válidos o vacíos"}), 400

    lead_id = data.get('lead_id')
    email_to_enrich = data.get('email')

    if not email_to_enrich:
        logging.warning("Email no proporcionado para enriquecimiento.")
        return jsonify({"message": "Error: 'email' es un campo requerido"}), 400

    enriched_data = {}

    # Validación de Email
    email_validator_api_url = get_api_key('EMAIL_VALIDATOR_API_URL')
    email_validator_api_key = get_api_key('EMAIL_VALIDATOR_API_KEY')
    if email_validator_api_url and email_validator_api_key:
        try:
            response = requests.get(
                f"{email_validator_api_url}/verify?email={email_to_enrich}",
                headers={'X-Api-Key': email_validator_api_key},
                timeout=10
            )
            response.raise_for_status()
            validation_result = response.json()
            enriched_data['email_is_valid'] = validation_result.get('status') == 'valid'
            logging.info(f"Email {email_to_enrich} validado: {enriched_data['email_is_valid']}.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al validar email {email_to_enrich}: {e}")

    # Enriquecimiento de Datos de Empresa
    if email_to_enrich and '@' in email_to_enrich and enriched_data.get('email_is_valid', True):
        domain = email_to_enrich.split('@')[-1]
        company_enrichment_api_url = get_api_key('COMPANY_ENRICHMENT_API_URL')
        company_enrichment_api_key = get_api_key('COMPANY_ENRICHMENT_API_KEY')
        if company_enrichment_api_url and company_enrichment_api_key:
            try:
                response = requests.get(
                    f"{company_enrichment_api_url}/company?domain={domain}",
                    headers={'Authorization': f'Bearer {company_enrichment_api_key}'},
                    timeout=10
                )
                response.raise_for_status()
                company_info = response.json()
                enriched_data['company_name'] = company_info.get('name')
                enriched_data['company_industry'] = company_info.get('industry')
                enriched_data['company_employees'] = company_info.get('employees')
                logging.info(f"Información de empresa enriquecida para {domain}.")
            except requests.exceptions.RequestException as e:
                logging.error(f"Error al enriquecer datos de empresa para {domain}: {e}")

    # Actualizar el CRM/Base de Datos
    crm_api_base_url = get_api_key('CRM_API_BASE_URL')
    crm_api_key = get_api_key('CRM_API_KEY')
    if crm_api_base_url and crm_api_key and lead_id:
        update_payload = {
            'enriched_data': enriched_data,
            'status': 'enriched' if any(enriched_data.values()) else 'basic'
        }
        try:
            response = requests.patch(
                f"{crm_api_base_url}/leads/{lead_id}",
                json=update_payload,
                headers={'Authorization': f'Bearer {crm_api_key}'},
                timeout=10
            )
            response.raise_for_status()
            logging.info(f"Lead {lead_id} actualizado en CRM con datos enriquecidos.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al actualizar lead {lead_id} en CRM con datos enriquecidos: {e}")

    return jsonify({"message": f"Lead {lead_id} procesado para enriquecimiento", "data": enriched_data}), 200

# --- 5. Procesamiento Automatizado de Archivos ---
@app.route('/webhook/procesar-archivo', methods=['POST'])
def handle_file_processing_webhook():
    logging.info("Webhook de procesamiento de archivo recibido.")
    data = request.json

    if not data or 'file_url' not in data:
        logging.warning("Petición sin 'file_url' en los datos JSON.")
        return jsonify({"message": "Error: 'file_url' es requerido"}), 400

    file_url = data.get('file_url')
    original_filename = data.get('filename', file_url.split('/')[-1])
    file_type = data.get('type', 'desconocido')
    output_bucket_url = get_api_key('PROCESSED_FILES_BUCKET_URL')

    if not output_bucket_url:
        logging.error("PROCESSED_FILES_BUCKET_URL no configurada. No se puede guardar el archivo procesado.")
        return jsonify({"message": "Error interno del servidor"}), 500

    logging.info(f"Iniciando procesamiento de archivo: {original_filename} desde {file_url}")

    try:
        response = requests.get(file_url, stream=True, timeout=30)
        response.raise_for_status()
        file_content_stream = io.BytesIO(response.content)

        processed_content_bytes = None
        processed_filename = original_filename

        if 'image' in file_type:
            try:
                img = Image.open(file_content_stream)
                img.thumbnail((800, 600))
                
                processed_stream = io.BytesIO()
                img.save(processed_stream, format=img.format if img.format else 'PNG')
                processed_content_bytes = processed_stream.getvalue()
                processed_filename = f"resized_{original_filename}"
                logging.info(f"Imagen {original_filename} redimensionada a {img.size}.")
            except Exception as img_err:
                logging.error(f"Error al procesar imagen {original_filename}: {img_err}")
                processed_content_bytes = file_content_stream.getvalue()
                processed_filename = f"error_{original_filename}"
                
        elif 'pdf' in file_type:
            logging.info(f"Procesamiento de PDF para {original_filename} no implementado en este ejemplo.")
            processed_content_bytes = file_content_stream.getvalue()
        else:
            logging.info(f"Tipo de archivo '{file_type}' no soportado para procesamiento. Subiendo original.")
            processed_content_bytes = file_content_stream.getvalue()

        if processed_content_bytes:
            upload_api_url = f"{output_bucket_url}/{processed_filename}"
            upload_headers = {'Authorization': f'Bearer {get_api_key("CLOUD_STORAGE_API_KEY")}'}
            
            try:
                upload_response = requests.put(upload_api_url, data=processed_content_bytes, headers=upload_headers, timeout=30)
                upload_response.raise_for_status()
                logging.info(f"Archivo procesado '{processed_filename}' subido con éxito.")
            except requests.exceptions.RequestException as upload_err:
                logging.error(f"Error al subir archivo procesado '{processed_filename}': {upload_err}")
                return jsonify({"message": "Error al subir archivo procesado", "details": str(upload_err)}), 500
        else:
            logging.error("No se generó contenido procesado para subir.")
            return jsonify({"message": "Error: No se pudo procesar el archivo"}), 500

    except requests.exceptions.RequestException as e:
        logging.error(f"Error al descargar archivo {file_url}: {e}")
        return jsonify({"message": "Error al descargar archivo", "details": str(e)}), 500
    except Exception as e:
        logging.error(f"Error inesperado en el procesamiento de archivo: {e}")
        return jsonify({"message": "Error interno del servidor", "details": str(e)}), 500

    return jsonify({"message": f"Archivo '{original_filename}' procesado y subido como '{processed_filename}'"}), 200

# --- 6. Tareas Programadas y Automatización Recurrente ---
@app.route('/webhook/tarea-diaria', methods=['POST'])
def handle_daily_task_webhook():
    logging.info("Webhook para tarea diaria recibido.")
    data = request.json
    task_id = data.get('task_id', 'daily_report_generation')
    current_date = datetime.now().strftime("%Y-%m-%d")

    logging.info(f"Iniciando tarea programada: {task_id} para la fecha: {current_date}")

    sales_api_base_url = get_api_key('SALES_API_BASE_URL')
    sales_api_key = get_api_key('SALES_API_KEY')
    sales_data = None
    if sales_api_base_url and sales_api_key:
        try:
            yesterday_date = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
            response = requests.get(
                f"{sales_api_base_url}/reports/daily?date={yesterday_date}",
                headers={'Authorization': f'Bearer {sales_api_key}'},
                timeout=20
            )
            response.raise_for_status()
            sales_data = response.json()
            logging.info(f"Datos de ventas para {yesterday_date} obtenidos con éxito.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al obtener datos de ventas para {yesterday_date}: {e}")

    google_sheets_api_url = get_api_key('GOOGLE_SHEETS_API_URL')
    google_sheets_api_key = get_api_key('GOOGLE_SHEETS_API_KEY')
    sales_report_sheet_id = get_api_key('SALES_REPORT_SHEET_ID')

    if sales_data and google_sheets_api_url and google_sheets_api_key and sales_report_sheet_id:
        try:
            sheet_payload = {
                'majorDimension': 'ROWS',
                'values': [
                    [current_date, sales_data.get('total_sales', 0), sales_data.get('new_customers', 0)]
                ]
            }
            response = requests.post(
                f"{google_sheets_api_url}/{sales_report_sheet_id}/values/Sheet1!A1:append?valueInputOption=RAW",
                json=sheet_payload,
                headers={
                    'Authorization': f'Bearer {google_sheets_api_key}',
                    'Content-Type': 'application/json'
                },
                timeout=15
            )
            response.raise_for_status()
            logging.info(f"Informe de ventas para {current_date} subido a Google Sheets.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al subir informe a Google Sheets para {current_date}: {e}")

    email_api_base_url = get_api_key('EMAIL_API_BASE_URL')
    email_api_key = get_api_key('EMAIL_API_KEY')
    recipient_email = get_api_key('DAILY_REPORT_RECIPIENT_EMAIL')

    if email_api_base_url and email_api_key and recipient_email:
        email_subject = f"Informe Diario de Ventas - {current_date}"
        email_body = f"Resumen de ventas del día {current_date}: Total Vendido: {sales_data.get('total_sales', 'N/A')} EUR. Nuevos Clientes: {sales_data.get('new_customers', 'N/A')}."
        email_payload = {
            'personalizations': [{'to': [{'email': recipient_email}]}],
            'from': {'email': 'noreply@tuempresa.com'},
            'subject': email_subject,
            'content': [{'type': 'text/plain', 'value': email_body}]
        }
        try:
            response = requests.post(
                f"{email_api_base_url}/mail/send",
                json=email_payload,
                headers={'Authorization': f'Bearer {email_api_key}', 'Content-Type': 'application/json'},
                timeout=10
            )
            response.raise_for_status()
            logging.info(f"Resumen diario de ventas enviado a {recipient_email}.")
        except requests.exceptions.RequestException as e:
            logging.error(f"Error al enviar resumen diario por email a {recipient_email}: {e}")

    return jsonify({"message": f"Tarea programada '{task_id}' para {current_date} completada."}), 200

# --- INICIO DE LA APLICACIÓN FLASK (PARA PRUEBAS LOCALES) ---
if __name__ == '__main__':
    logging.info("Iniciando Flask app en modo desarrollo local.")
    # Puedes comentar 'debug=True' para no ver el reloaded, o añadir host='0.0.0.0' para acceso externo en LAN si lo necesitas.
    app.run(debug=True, port=5000)
EOF
echo "src/python/main_orchestrator.py creado."

# --- 5. Instalar Dependencias de Python ---
echo -e "\n--- Instalando dependencias de Python... ---"
pip install -r requirements.txt || { echo "Error: Falló la instalación de dependencias."; exit 1; }
echo "Dependencias instaladas."

# --- 6. Confirmación y Siguiente Paso ---
echo -e "\n🎉 ¡Configuración de Termux completada! 🎉"
echo "Ahora, por favor, edita el archivo .env en la raíz de tu proyecto para añadir tus claves API y URLs REALES."
echo "Puedes hacerlo con: nano .env"
echo "Una vez que hayas configurado .env, puedes iniciar tu orquestador LOCALMENTE con:"
echo "python src/python/main_orchestrator.py"
echo -e "\nPara desplegar en Render, asegúrate de haber configurado las MISMAS variables de entorno en el dashboard de Render."
echo "Luego, haz git add ., git commit -m 'initial setup', y git push origin main."
echo "¡Mucha suerte con tu orquestador!"



