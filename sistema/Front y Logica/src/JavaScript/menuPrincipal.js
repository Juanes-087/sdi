
// JavaScript/menuPrincipal.js

document.addEventListener('DOMContentLoaded', function () {
    console.log('menuPrincipal.js cargado correctamente');

    // Referencias a elementos
    const modalGestion = document.getElementById('modalGestion');
    if (!modalGestion) console.error('ELEMENTO modalGestion NO ENCONTRADO AL CARGAR');

    const closeGestion = document.getElementById('closeGestionBtn');
    const modalTitle = document.getElementById('modalGestionTitle');
    const modalBody = document.getElementById('modalGestionBody');

    // --- GLOBAL ERROR HANDLER ---
    window.onerror = function (msg, url, line) {
        alert('Error JS: ' + msg + '\nLinea: ' + line);
        return false;
    };

    // --- FUNCIÓN PARA ABRIR EL MODAL DE GESTIÓN ---
    window.abrirGestion = async function (tipo) {
        alert('DEBUG: Click detectado en ' + tipo); // ALERT INMEDIATO

        console.log('Intentando abrir gestion para:', tipo);

        if (!modalGestion) {
            console.error('No se encontró el elemento modalGestion');
            alert('Error CRITICO: No se encontró el modal en el DOM (ID modalGestion)');
            return;
        }

        // 1. Mostrar modal cargando

        modalGestion.style.display = 'flex';
        modalGestion.classList.add('show');
        modalTitle.textContent = 'Cargando ' + tipo + '...';
        modalBody.innerHTML = '<div class="cargando"><i class="fas fa-spinner fa-spin"></i> Cargando datos...</div>';

        try {
            // 2. Fetch datos
            const response = await fetch(`../php/api_gestion.php?tipo=${tipo}`);
            const result = await response.json();

            if (result.error) {
                modalBody.innerHTML = `<div class="alert alert-error">${result.error}</div>`;
                return;
            }

            // 3. Renderizar Tabla
            modalTitle.textContent = 'Gestión de ' + tipo.charAt(0).toUpperCase() + tipo.slice(1);
            renderTabla(result.data, result.columns, tipo);

        } catch (error) {
            console.error(error);
            modalBody.innerHTML = `<div class="alert alert-error">Error al conectar con el servidor</div>`;
        }
    };

    function renderTabla(data, columns, tipo) {
        if (!data || data.length === 0) {
            modalBody.innerHTML = '<p>No hay registros encontrados.</p>';
            return;
        }

        let html = '<div class="table-responsive"><table class="gestion-table">';

        // Header
        html += '<thead><tr>';
        columns.forEach(col => {
            html += `<th>${col.label}</th>`;
        });
        html += '<th>Acciones</th></tr></thead>';

        // Body
        html += 'tbody';
        data.forEach(row => {
            html += '<tr>';
            columns.forEach(col => {
                html += `<td>${row[col.key] || ''}</td>`;
            });
            // Acciones
            html += `<td>
                <button class="btn-icon edit" onclick="editarRegistro('${tipo}', ${row[columns[0].key]})" title="Editar"><i class="fas fa-edit"></i></button>
            </td>`;
            html += '</tr>';
        });
        html += '</tbody></table></div>';

        modalBody.innerHTML = html;
    }

    // --- FUNCIONES DE CIERRE ---
    if (closeGestion) {
        closeGestion.addEventListener('click', function () {
            cerrarModal(modalGestion);
        });
    }

    function cerrarModal(modal) {
        if (!modal) return;
        modal.classList.remove('show');
        setTimeout(() => {
            modal.style.display = 'none';
        }, 300);
    }

    window.onclick = function (event) {
        if (event.target == modalGestion) {
            cerrarModal(modalGestion);
        }
        // Mantener funcionalidad de otros modales si existen
        const modalPerfil = document.getElementById('modalPerfil');
        const modalPass = document.getElementById('modalPassword');
        if (event.target == modalPerfil) cerrarModalPerfil();
        if (event.target == modalPass) cerrarModalPassword();
    };

    // --- EDITAR (Placeholder) ---
    // --- EDITAR (Placeholder) ---
    window.editarRegistro = function (tipo, id) {
        alert(`Funcionalidad de edición para ${tipo} ID: ${id} en construcción.`);
    };

    // --- SESSION EXPIRATION LOGIC (Added for Security) ---
    verificarExpiracionToken();

    function verificarExpiracionToken() {
        const token = localStorage.getItem('token');
        if (!token) return;

        try {
            const payloadBase64 = token.split('.')[1];
            const decodedJson = atob(payloadBase64);
            const payload = JSON.parse(decodedJson);
            const exp = payload.exp;
            const now = Math.floor(Date.now() / 1000);

            if (exp < now) {
                mostrarModalExpiracionAdmin();
            } else {
                const timeRemaining = (exp - now) * 1000;
                setTimeout(() => {
                    mostrarModalExpiracionAdmin();
                }, timeRemaining);
            }
        } catch (e) {
            console.error('Error al verificar token:', e);
        }
    }

    function mostrarModalExpiracionAdmin() {
        // Remove existing modals
        const existing = document.getElementById('modalExpiracionAdmin');
        if (existing) existing.remove();

        const modal = document.createElement('div');
        modal.id = 'modalExpiracionAdmin';
        modal.className = 'modal'; // Use existing modal class structure
        modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); display: flex; align-items: center; justify-content: center; z-index: 99999 !important; backdrop-filter: blur(3px);';

        modal.innerHTML = `
        <div class="modal-content" style="max-width: 400px; text-align: center; border-radius: 15px; overflow: hidden; box-shadow: 0 10px 40px rgba(0,0,0,0.5); background: var(--bg-secondary); border: 1px solid var(--border-color);">
            <div class="modal-header" style="background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%); padding: 20px; color: white; display: block; border: none;">
                <h2 style="margin: 0; font-size: 24px;"><i class="fa-solid fa-clock-rotate-left"></i> Sesión Caducada</h2>
            </div>
            <div class="modal-body" style="padding: 30px 20px; background: transparent;">
                <p style="font-size: 16px; color: var(--text-main); margin-bottom: 25px; opacity: 0.9;">
                    Tu sesión ha expirado por seguridad. Por favor, inicia sesión nuevamente.
                </p>
                <div style="display: flex; justify-content: center;">
                    <button id="btnAceptarExpiracionAdmin" class="btn-modal btn-primary" style="background: #e74c3c; border: none; padding: 12px 30px; font-size: 16px; color: white; border-radius: 8px; cursor: pointer; font-weight: bold;">
                        Aceptar y Salir
                    </button>
                </div>
            </div>
        </div>
        `;
        document.body.appendChild(modal);

        // Force display
        modal.style.display = 'flex';
        modal.classList.add('show');

        // Logic
        document.getElementById('btnAceptarExpiracionAdmin').onclick = function () {
            this.disabled = true;
            this.innerHTML = "Cerrando...";

            // Check if global logout function exists (from footer.php)
            if (typeof window.ejecutarLogout === 'function') {
                window.ejecutarLogout();
            } else {
                // Fallback
                window.location.replace('../../index.html');
            }
        };
    }
});






