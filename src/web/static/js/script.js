async function runAudit() {
    const mensajeDiv = document.getElementById('mensaje');
    mensajeDiv.innerHTML = '<h3>Iniciando Auditoría...</h3><p>Esto puede tardar unos segundos...</p>';
    console.log('Botón "Ejecutar Auditoría" presionado en la web.');

    try {
        const response = await fetch('/api/audit'); // Calls Flask API
        const data = await response.json();

        let resultHtml = '<h3>Resultado de Auditoría:</h3>';
        if (data.vulnerabilities && data.vulnerabilities.length > 0) {
            resultHtml += '<p>¡Vulnerabilidades detectadas y transformadas!</p><ul>';
            data.vulnerabilities.forEach(vuln => {
                resultHtml += `<li><strong>${vuln.type}</strong> (${vuln.severity}) en ${vuln.module}::${vuln.method}</li>`;
            });
            resultHtml += '</ul><p>Los detalles completos se encuentran en los logs del servidor (Render).</p>';
        } else {
            resultHtml += '<p>✅ No se detectaron vulnerabilidades críticas en esta ronda.</p>';
        }
        mensajeDiv.innerHTML = resultHtml;

    } catch (error) {
        mensajeDiv.innerHTML = '<h3>Error al ejecutar la auditoría:</h3><p>' + error.message + '</p>';
        console.error('Error calling audit API:', error);
    }
}

async function checkLeanLogic() {
    const leanDiv = document.getElementById('lean-status');
    leanDiv.innerHTML = '<h3>Verificando Lógica Lean...</h3>';
    try {
        const response = await fetch('/api/lean_check');
        const data = await response.json();
        leanDiv.innerHTML = '<h3>Status Lógica Lean:</h3><p>' + data.status + '</p>';
    } catch (error) {
        leanDiv.innerHTML = '<h3>Error al verificar lógica Lean:</h3><p>' + error.message + '</p>';
        console.error('Error calling Lean API:', error);
    }
}

// Ensure DOM is loaded before adding event listeners
document.addEventListener('DOMContentLoaded', () => {
    const auditButton = document.getElementById('audit-button');
    if (auditButton) {
        auditButton.addEventListener('click', runAudit);
    }

    const leanButton = document.getElementById('lean-button');
    if (leanButton) {
        leanButton.addEventListener('click', checkLeanLogic);
    }
});
