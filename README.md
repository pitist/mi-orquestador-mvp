# Mi Proyecto Orquestado (MVP para la Nube)

Este proyecto es un Producto Mínimo Viable (MVP) diseñado para ser desplegado en un entorno de nube como Render, utilizando Python (Flask) como orquestador backend y una interfaz web (HTML, CSS, JS) para el frontend.

## Estructura de Carpetas

-   `src/python/`: Contiene el orquestador principal (`main_orchestrator.py`) con la lógica de negocio y la API Flask.
-   `src/web/`: Contiene los archivos del frontend web (`index.html`, `static/css/`, `static/js/`).
-   `Procfile`: Un archivo esencial para plataformas como Render que indica cómo iniciar el servidor web (Gunicorn).
-   `requirements.txt`: Lista las dependencias de Python que Render instalará automáticamente.
-   `.gitignore`: Define qué archivos y carpetas debe ignorar Git (ej. logs, entornos virtuales).

## Despliegue en la Nube con Render (¡Recomendado!)

Este proyecto está optimizado para un despliegue rápido y continuo con Render.com.

### 1. Preparar en GitHub desde Termux

1.  **Crea un nuevo repositorio en GitHub** (ej. `mi-orquestador-mvp`) **desde tu navegador en el móvil**. NO marques la opción de inicializar con README, .gitignore o licencia.
    

2.  **Desde Termux, navega a la raíz de tu proyecto:**
    ```bash
    cd ~/mi_proyecto_orquestado_cloud/
    ```

3.  **Inicializa Git y sube el código:**
    ```bash
    git init
    git add .
    git commit -m "Initial commit of MVP project for cloud deployment"
    git branch -M main
    # IMPORTANTE: Reemplaza con el enlace REAL de tu repositorio de GitHub
    git remote add origin [https://github.com/TU_USUARIO/TU_REPOSITORIO.git](https://github.com/TU_USUARIO/TU_REPOSITORIO.git) 
    
    # Si tienes 2FA en GitHub, necesitarás un Token de Acceso Personal (PAT)
    # Genera un PAT en GitHub -> Settings -> Developer settings -> Personal access tokens
    # Usa "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" en lugar de tu contraseña
    git push -u origin main
    ```

### 2. Desplegar en Render.com desde el Móvil

1.  **Regístrate en Render.com** (o inicia sesión) desde el navegador de tu móvil.
2.  Haz clic en **"New"** y selecciona **"Web Service"**.
3.  Conecta tu cuenta de **GitHub** (si no lo has hecho ya) y selecciona el repositorio de tu proyecto (`mi-orquestador-mvp`).
4.  Configura tu servicio:
    * **Name:** Dale un nombre a tu servicio (ej. `my-orchestrator-mvp`).
    * **Root Directory:** Deja en blanco.
    * **Runtime:** `Python 3`
    * **Build Command:** `pip install -r requirements.txt` (Render lo detecta automáticamente).
    * **Start Command:**
        ```
        gunicorn src.python.main_orchestrator:app --timeout 120
        ```
        *(Render leerá el puerto automáticamente de su variable de entorno `$PORT`)*.
    * **Plan:** Selecciona el plan **"Free"** (gratuito).
5.  **Variables de Entorno (Environment Variables):**
    * En la configuración de Render, ve a la sección "Environment". Aquí debes añadir las variables de entorno que tu `main_orchestrator.py` espera:
        * `API_KEY`: Dale un valor seguro (ej. `tu_clave_api_segura_aqui_para_render`).
        * `DATABASE_URL`: (Opcional, si usas DB remota) `postgresql://...`
        * `DEBUG_MODE`: `false` (si quieres desactivar el modo debug en producción).
6.  Haz clic en **"Create Web Service"**.

Render automáticamente construirá tu aplicación e la desplegará. Una vez que el despliegue esté completo, Render te proporcionará una URL pública (ej. `https://my-orchestrator-mvp.onrender.com`).

### 3. Acceso a la Aplicación Desplegada

Una vez que tu servicio en Render esté "Live" (en vivo), podrás acceder a tu aplicación desde cualquier navegador web usando la **URL de Render** que te proporcionó (será algo como `https://[tu-nombre-de-servicio].onrender.com`).

### Desarrollo Local en Termux (Opcional)

Si necesitas probar el proyecto localmente en Termux antes de subir a GitHub:

1.  Abre Termux y navega a la raíz de tu proyecto (`~/mi_proyecto_orquestado_cloud/`).
2.  Instala las dependencias (si no lo hiciste con el script principal o necesitas reinstalar): `pip install -r requirements.txt`
3.  Ejecuta el servidor de desarrollo Flask: `python src/python/main_orchestrator.py`
4.  Accede en tu navegador del móvil a: `http://127.0.0.1:5000`

---
