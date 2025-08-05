import os
import sys
import logging
import json
from datetime import datetime
import random
from flask import Flask, jsonify, request, send_from_directory
import time

# --- Configuración y Logging ---
# Paths relativos al directorio raíz del proyecto para despliegue en la nube
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__))) # Apunta a mi_proyecto_orquestado_cloud/

# Configuración de logs para producción (stdout para Render)
logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s',
                    handlers=[logging.StreamHandler(sys.stdout)]) # Envía logs a la consola para Render

app = Flask(__name__, static_folder=os.path.join(PROJECT_ROOT, 'src', 'web', 'static'))

logging.info("╔═══════════════════════════════════════════════════════════╗")
logging.info("║         Python Orchestrator: Directing the Operation        ║")
logging.info("╚═══════════════════════════════════════════════════════════╝")

# Ejemplo de cómo cargar configuración de variables de entorno (preferido en la nube)
# y un fallback para desarrollo local
def get_config_value(key, default_value=None):
    """Obtiene un valor de configuración de las variables de entorno o usa un valor por defecto."""
    return os.environ.get(key.upper(), default_value) # Las variables de entorno suelen ser mayúsculas

# Claves sensibles o URLs de BD: NUNCA en el código directamente para producción
API_KEY = get_config_value("API_KEY", "tu_clave_api_local_secreta")
DATABASE_URL = get_config_value("DATABASE_URL", "sqlite:///./local_database.db")
DEBUG_MODE = get_config_value("DEBUG_MODE", "false").lower() == "true" # Las variables de entorno son strings

# Flask debug mode
app.config["DEBUG"] = DEBUG_MODE

logging.info(f"Configuración cargada: API_KEY={'***' if API_KEY != 'tu_clave_api_local_secreta' else API_KEY}, DB_URL={DATABASE_URL}, DEBUG={DEBUG_MODE}")


def simular_uso_logica_lean():
    """Simulates the use of verified Lean logic."""
    logging.info("▶️ Utilizing verified Lean logic (we trust its correctness!)...")
    time.sleep(1) # Simula trabajo
    logging.info("✅ Lean logic applied successfully (simulated).")

def _get_random_module_and_method():
    """Simulates selecting a random module and method for the vulnerability."""
    modules = ["auth_service.py", "data_handler.py", "payment_processor.py"]
    methods = {
        "auth_service.py": ["login", "register", "change_password"],
        "data_handler.py": ["get_user_data", "save_record", "delete_file"],
        "payment_processor.py": ["process_transaction", "refund", "check_status"]
    }
    module = random.choice(modules)
    method = random.choice(methods.get(module, ["general_method"]))
    return module, method

def identify_and_transform_vulnerabilities():
    """Simulates the identification, evaluation, and transformation of vulnerabilities."""
    logging.info("🚨 Initiating Security Audit (Simulated)...")

    vulnerabilities = []
    possible_vuln_types = {
        "Crítica": [
            "Remote Code Injection",
            "Critical Credential Exposure",
            "Total Authorization Bypass",
            "Blind SQL Injection"
        ],
        "Alta": [
            "Sensitive Information Leakage",
            "Logical Denial of Service (DoS)",
            "Cross-Site Scripting (XSS)"
        ],
        "Media": [
            "User Enumeration",
            "Weak Password Brute Force",
            "Incorrect Security Configuration"
        ]
    }

    num_vulnerabilities = random.randint(0, 3) # May find none
    
    for i in range(num_vulnerabilities):
        severity = random.choices(list(possible_vuln_types.keys()), weights=[0.4, 0.4, 0.2], k=1)[0]
        vuln_type = random.choice(possible_vuln_types[severity])
        module, method = _get_random_module_and_method()
        
        vulnerabilities.append({
            "id": i + 1,
            "module": module,
            "method": method,
            "type": vuln_type,
            "severity": severity,
            "status": "Identified"
        })
        logging.warning(f"  Vulnerability {vuln_type} ({severity}) found in {module}::{method}.")

    if not vulnerabilities:
        logging.info("  ✅ No new critical vulnerabilities detected in this audit.")
        return []

    logging.info("📊 Evaluating and Prioritizing Vulnerabilities...")
    vulnerabilities.sort(key=lambda x: {"Crítica": 3, "Alta": 2, "Media": 1}[x['severity']], reverse=True)

    report_content = f"\n--- Security Audit Report ({datetime.now()}) ---\n"
    report_content += "Identified and prioritized vulnerabilities:\n\n"

    for vul in vulnerabilities:
        logging.info(f"  Priority {vulnerabilities.index(vul) + 1}: {vul['type']} in {vul['module']}::{vul['method']} ({vul['severity']})")
        report_content += f"  - ID: {vul['id']}\n"
        report_content += f"    Module: {vul['module']}:: Method: {vul['method']}\n"
        report_content += f"    Type: {vul['type']}\n"
        report_content += f"    Severity: {vul['severity']}\n"
        report_content += f"    Status: {vul['status']}\n"

        suggestion = _suggest_transformation(vul['type'])
        logging.info(f"    ▶️ Transforming into strength: {suggestion}")
        report_content += f"    Transformation Suggestion: {suggestion}\n\n"
        vul['status'] = "Mitigated (Simulated)"
    
    report_content += "--- End of Audit ---\n"
    logging.info(report_content) # Esto enviará el reporte a los logs de Render
    
    logging.info("✅ Transformation and closure process completed (simulated).")
    return vulnerabilities

def _suggest_transformation(vuln_type):
    """Suggests a strategy to transform a vulnerability into a strength."""
    suggestions = {
        "Remote Code Injection": "Implement sandboxing, strict input validation, and avoid dynamic code execution with external data.",
        "Critical Credential Exposure": "Use managed secrets (e.g., HashiCorp Vault if cloud), secure environment variables. Never hardcode credentials.",
        "Total Authorization Bypass": "Review and strengthen RBAC (Role-Based Access Control) logic. Apply the principle of least privilege.",
        "Blind SQL Injection": "Refactor to ORM (Object-Relational Mapper) or use prepared statements with bound parameters.",
        "Sensitive Information Leakage": "Implement encryption in transit and at rest, data anonymization, and DLP (Data Loss Prevention).",
        "Logical Denial of Service (DoS)": "Optimize algorithms, implement rate limiting, timeouts, and load balancing.",
        "Cross-Site Scripting (XSS)": "Sanitize all user inputs before rendering them in HTML. Use Content Security Policy (CSP).",
        "User Enumeration": "Implement generic error messages for login/registration that do not reveal user existence.",
        "Weak Password Brute Force": "Implement login attempt limits, temporary account locking, and reCAPTCHA. Enforce strong passwords.",
        "Incorrect Security Configuration": "Perform regular configuration audits, use secure configuration templates (e.g., CIS Benchmarks)."
    }
    return suggestions.get(vuln_type, "General strategy: Forensic analysis and application of security patches. Architecture review.")

# --- API Routes (Flask) ---
@app.route('/')
def serve_index():
    """Sirve el index.html."""
    return send_from_directory(os.path.join(PROJECT_ROOT, 'src', 'web'), 'index.html')

@app.route('/static/<path:filename>')
def serve_static(filename):
    """Sirve archivos estáticos (CSS, JS)."""
    # Flask ya usa el static_folder configurado en la app
    return send_from_directory(app.static_folder, filename)

@app.route('/api/audit', methods=['GET'])
def run_audit():
    """Endpoint para ejecutar la auditoría de seguridad y devolver resultados."""
    logging.info("Request received for /api/audit.")
    vulnerabilities = identify_and_transform_vulnerabilities()
    return jsonify({"status": "Audit completed", "vulnerabilities": vulnerabilities})

@app.route('/api/lean_check', methods=['GET'])
def run_lean_check():
    """Endpoint para simular el uso de lógica Lean."""
    logging.info("Request received for /api/lean_check.")
    simular_uso_logica_lean()
    return jsonify({"status": "Verified Lean logic (simulated) applied"})

# Este bloque solo se ejecuta si corres el script directamente (para desarrollo local)
# En producción (Render), Gunicorn llamará directamente a 'app'.
if __name__ == "__main__":
    logging.info("Starting Flask development server for local testing...")
    host = '0.0.0.0'
    port = 5000
    logging.info(f"🌐 Server web Flask iniciado en http://{host}:{port}")
    logging.warning("⚠️ Advertencia: NO USAR ESTO PARA PRODUCCIÓN PÚBLICA. Para eso, usa Gunicorn/WSGI.")
    app.run(host=host, port=port, debug=DEBUG_MODE) # Usa el modo debug de la config
