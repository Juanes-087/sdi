/**
 * JavaScript/core/ui_components.js
 * Funcionalidades transversales para pintar UI
 */

const UIComponents = {
    /**
     * Muestra o oculta un indicador de carga genérico
     * @param {boolean} show Mostrar (true) u ocultar (false)
     */
    toggleLoading: (show) => {
        if (typeof window.mostrarCargando === 'function') {
            if (show) window.mostrarCargando();
            else window.ocultarCargando();
        } else {
            // Fallback si no existen las funciones globales
            console.warn('[UIComponents] Funciones globales de carga no encontradas.');
        }
    },

    /**
     * Genera una tabla estandarizada
     * @param {HTMLElement} container Elemento donde se inyectará la tabla
     * @param {Array} columns Definición de columnas [{key: 'id', label: 'ID'}]
     * @param {Array} data Los datos a renderizar
     * @param {Function} actionsHtmlFn Función que retorna el HTML de los botones de acción para cada fila
     */
    renderTable: (container, columns, data, actionsHtmlFn = null) => {
        if (!container) return;

        if (!data || data.length === 0) {
            container.innerHTML = `<div style="padding: 20px; text-align: center; color: #666;">No hay registros encontrados.</div>`;
            return;
        }

        let headerHtml = '';
        columns.forEach(col => {
            headerHtml += `<th style="padding: 15px; position: sticky; top: 0; background: inherit; z-index: 10;">${col.label}</th>`;
        });
        if (actionsHtmlFn) {
            headerHtml += `<th style="padding: 15px; position: sticky; top: 0; background: inherit; z-index: 10;">Acciones</th>`;
        }

        let rowsHtml = '';
        data.forEach(item => {
            let rowHtml = '<tr style="border-bottom: 1px solid #eee; color: #333;">';
            columns.forEach(col => {
                let val = item[col.key] || '';
                if (col.key === 'cant_disp') {
                    const color = val > 0 ? '#d4edda' : '#f8d7da';
                    const text = val > 0 ? '#155724' : '#721c24';
                    val = `<span style="background: ${color}; color: ${text}; padding: 4px 8px; border-radius: 4px; font-size: 0.85rem;">${val}</span>`;
                }
                rowHtml += `<td style="padding: 12px 15px;">${val}</td>`;
            });

            if (actionsHtmlFn) {
                rowHtml += `<td style="padding: 12px 15px; white-space: nowrap; text-align: center;">${actionsHtmlFn(item)}</td>`;
            }
            rowHtml += '</tr>';
            rowsHtml += rowHtml;
        });

        // Usar los colores integrados en el CSS existente o fallbacks
        container.innerHTML = `
            <table class="custom-table" style="width: 100%; border-collapse: collapse;">
                <thead>
                    <tr style="background: #36498f; color: white; text-align: left;">
                        ${headerHtml}
                    </tr>
                </thead>
                <tbody>
                    ${rowsHtml}
                </tbody>
            </table>
        `;
    },

    /**
     * Muestra un toast/alerta exito
     */
    showSuccess: (msg, callback = null) => {
        if (typeof window.mostrarExitoCustom === 'function') {
            window.mostrarExitoCustom(msg, callback);
        } else {
            alert(msg);
            if (callback) callback();
        }
    },

    /**
     * Muestra un toast/alerta de error
     */
    showError: (title, msg) => {
        if (typeof window.mostrarErrorCustom === 'function') {
            window.mostrarErrorCustom(title, msg);
        } else {
            alert(`${title}: ${msg}`);
        }
    },

    /**
     * Muestra un confirm custom
     */
    showConfirm: (title, msg, onConfirm) => {
        if (typeof window.mostrarConfirmacionCustom === 'function') {
            window.mostrarConfirmacionCustom(title, msg, onConfirm);
        } else {
            if (confirm(`${title}\n${msg}`)) {
                onConfirm();
            }
        }
    },

    /**
     * Muestra un diálogo de sesión expirada que obliga el logout
     * (Estilo personalizado igual al menú de cliente)
     */
    showSessionExpired: () => {
        // Evitar múltiples modales de expiración
        if (window.sessionExpiredShowing) return;
        window.sessionExpiredShowing = true;

        // Eliminar cualquier otro modal abierto para evitar superposición
        const currentModals = document.querySelectorAll('.modal, .modal-client-custom, #modalExpiracionAdmin');
        currentModals.forEach(m => m.style.display = 'none');

        let modal = document.getElementById('modalExpiracionAdmin');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'modalExpiracionAdmin';

            // Estilo de fondo (Overlay)
            modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); display: flex; align-items: center; justify-content: center; z-index: 2147483647 !important; backdrop-filter: blur(5px);';

            // HTML interno (Estructura igual a menuCliente.php)
            modal.innerHTML = `
        <div style="background: var(--bg-secondary); border: 1px solid var(--border-color); padding: 40px; border-radius: 20px; width: 400px; max-width: 90%; text-align: center; box-shadow: 0 10px 40px rgba(0,0,0,0.5); animation: modalSlideIn 0.3s ease;">
            <div style="width: 80px; height: 80px; background: rgba(244, 67, 54, 0.1); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px; border: 3px solid #f44336;">
                <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#f44336" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                </svg>
            </div>
            <h2 style="margin: 0 0 10px; color: var(--text-main); font-size: 24px;">Sesión Caducada</h2>
            <p style="color: var(--text-main); font-size: 16px; line-height: 1.5; margin-bottom: 30px; opacity: 0.8;">
                Tu sesión se ha cerrado automáticamente por seguridad debido a inactividad o expiración del token.
            </p>
            <button id="btnAceptarExpiracion" style="
                background: #f44336; color: white; border: none; padding: 12px 30px; 
                border-radius: 50px; cursor: pointer; font-size: 16px; font-weight: bold;
                box-shadow: 0 4px 15px rgba(244, 67, 54, 0.3); transition: transform 0.2s;
            ">Aceptar y Salir</button>
        </div>
            <style>
                @keyframes modalSlideIn {
                    from { transform: translateY(-30px); opacity: 0; }
                    to { transform: translateY(0); opacity: 1; }
                }
            </style>
            `;
            document.body.appendChild(modal);

            document.getElementById('btnAceptarExpiracion').onclick = function () {
                this.disabled = true;
                this.innerHTML = "Cerrando...";

                if (typeof window.ejecutarLogout === 'function') {
                    window.ejecutarLogout();
                } else {
                    window.location.href = '../../index.html';
                }
            };
        } else {
            modal.style.display = 'flex';
        }
    }
};

window.UIComponents = UIComponents;






