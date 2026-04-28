// JavaScript/logica.js - Refactorizado con CRUD completo y Selects

document.addEventListener('DOMContentLoaded', function () {
    // === 1. INVENTARIO (Filtros y Búsqueda) ===
    const filterButtons = document.querySelectorAll('.filter-btn');
    const productos = document.querySelectorAll('.producto-card');
    const searchInput = document.getElementById('searchInput');

    if (filterButtons.length > 0) {
        // Filtros por categoría
        filterButtons.forEach(button => {
            button.addEventListener('click', function () {
                filterButtons.forEach(btn => btn.classList.remove('active'));
                this.classList.add('active');
                const filter = this.getAttribute('data-filter');
                productos.forEach(producto => {
                    if (filter === 'todos' || producto.getAttribute('data-categoria') === filter) {
                        producto.style.display = 'block';
                        producto.style.animation = 'fadeInUp 0.4s ease-out';
                    } else {
                        producto.style.display = 'none';
                    }
                });
            });
        });

        // Búsqueda en tiempo real
        searchInput.addEventListener('input', function () {
            const searchTerm = this.value.toLowerCase();
            productos.forEach(producto => {
                const titulo = producto.querySelector('.producto-titulo').textContent.toLowerCase();
                const descripcion = producto.querySelector('.producto-descripcion').textContent.toLowerCase();
                if (titulo.includes(searchTerm) || descripcion.includes(searchTerm)) {
                    producto.style.display = 'block';
                    producto.style.animation = 'fadeInUp 0.4s ease-out';
                } else {
                    producto.style.display = 'none';
                }
            });
        });

        // Animaciones
        productos.forEach((card, index) => { card.style.animationDelay = `${index * 0.1}s`; });
    }

    // === 2. EVENT LISTENERS GLOBALES ===
    const closeGestionBtn = document.getElementById('closeGestionBtn');
    if (closeGestionBtn) {
        closeGestionBtn.onclick = function () { document.getElementById('modalGestion').style.display = 'none'; };
    }

    window.onclick = function (event) {
        const mGestion = document.getElementById('modalGestion');
        const mPerfil = document.getElementById('modalPerfil');
        const mPassword = document.getElementById('modalPassword');
        if (event.target == mGestion) mGestion.style.display = 'none';
        if (event.target == mPerfil) cerrarModalPerfil();
        if (event.target == mPassword) cerrarModalPassword();
    };

    const btnNuevo = document.getElementById('btnNuevoRegistro');
    if (btnNuevo) {
        btnNuevo.addEventListener('click', function () {
            const tipo = this.getAttribute('data-tipo');
            mostrarFormulario(tipo, 'create');
        });
    }

    // Header Parallax
    window.addEventListener('scroll', function () {
        const header = document.querySelector('.header-inventario');
        if (header) header.style.transform = `translateY(${window.pageYOffset * 0.5}px)`;
    });

    // Verificar expiración de sesión/token de forma proactiva
    if (typeof verificarExpiracionTokenAdmin === 'function') {
        verificarExpiracionTokenAdmin();
    }
});

/**
 * Verifica proactivamente si el token JWT en localStorage ha expirado
 * y configura un temporizador para avisar al usuario.
 */
function verificarExpiracionTokenAdmin() {
    const token = localStorage.getItem('token');
    if (!token) return;

    try {
        // El token viene como: Header.Payload.Signature
        const parts = token.split('.');
        if (parts.length !== 3) return;

        // Decodificar payload (Base64URL -> Base64 -> Texto -> JSON)
        // atob puede fallar con caracteres especiales si no se limpia bien,
        // pero para campos estándar como 'exp' suele ser suficiente.
        const payload64 = parts[1].replace(/-/g, '+').replace(/_/g, '/');
        const decodedJson = atob(payload64);
        const payload = JSON.parse(decodedJson);

        if (!payload.exp) return;
        
        // Limpiar temporizador previo si existe
        if (window.sessionTimeoutId) {
            clearTimeout(window.sessionTimeoutId);
        }

        const now = Math.floor(Date.now() / 1000);
        const timeRemaining = (payload.exp - now) * 1000;

        if (timeRemaining <= 0) {
            if (window.UIComponents) window.UIComponents.showSessionExpired();
        } else {
            // Configurar alarma para cuando expire
            window.sessionTimeoutId = setTimeout(() => {
                if (window.UIComponents) window.UIComponents.showSessionExpired();
            }, timeRemaining);

            console.log(`[Session] El token expirará en ${Math.round(timeRemaining / 1000 / 60)} minutos.`);
        }
    } catch (e) {
        console.error('Error al procesar token para verificación:', e);
    }
}

// === 3. FUNCIONES DE PERFIL ===
function abrirModalPerfil() {
    const modal = document.getElementById('modalPerfil');
    modal.style.display = 'block';
    setTimeout(() => { modal.classList.add('show'); }, 10);
}
function cerrarModalPerfil() {
    const modal = document.getElementById('modalPerfil');
    modal.classList.remove('show');
    setTimeout(() => { modal.style.display = 'none'; }, 300);
}

// === SYNC DATALIST HELPER ===
window.syncDatalist = function (input, hiddenId) {
    const hidden = document.getElementById(hiddenId);
    const list = document.getElementById(input.getAttribute('list'));
    if (!hidden || !list) return;

    const options = list.options;
    let foundId = '';
    for (let i = 0; i < options.length; i++) {
        if (options[i].value === input.value) {
            foundId = options[i].getAttribute('data-id');
            break;
        }
    }
    hidden.value = foundId;
};

async function cargaAuxiliares() {
    try {
        // Anti-cache param
        const response = await fetch('./api_gestion.php?tipo=auxiliares&_t=' + new Date().getTime());
        const result = await response.json();
        window.auxiliares = result;
    } catch (e) {
        console.error("Error cargando auxiliares:", e);
    }
}

// Helper to fetch instruments for Kit Builder
window.loadInstrumentOptions = async function () {
    try {
        const response = await fetch('api_gestion.php?tipo=instrumentos');
        const json = await response.json();
        return json.data || [];
    } catch (e) { console.error(e); return []; }
};

window.loadKitOptions = async function () {
    try {
        const response = await fetch('api_gestion.php?tipo=kits');
        const json = await response.json();
        return json.data || [];
    } catch (e) { console.error(e); return []; }
};

// ABRIR GESTIÓN
window.abrirGestion = async function (tipo) {
    const modalGestion = document.getElementById('modalGestion');
    const modalTitle = document.getElementById('modalGestionTitle');
    const modalBody = document.getElementById('modalGestionBody');
    const btnNuevo = document.getElementById('btnNuevoRegistro');

    // Reset to wide mode for tables
    const modalContent = modalGestion.querySelector('.modal-content');
    if (modalContent) modalContent.classList.add('modal-large');

    modalGestion.style.display = 'block';
    modalTitle.textContent = 'Gestión de ' + tipo.charAt(0).toUpperCase() + tipo.slice(1);
    modalBody.innerHTML = '<div style="text-align:center; padding:50px;"><i class="fas fa-spinner fa-spin fa-3x"></i><p>Cargando datos...</p></div>';

    if (tipo === 'nuevos_mes') {
        btnNuevo.style.display = 'none';
    } else {
        btnNuevo.style.display = 'flex';
    }
    btnNuevo.setAttribute('data-tipo', tipo);

    try {
        // Paralelizar carga de tabla y auxiliares
        const [respDatos, _] = await Promise.all([
            fetch(`api_gestion.php?tipo=${tipo}`),
            cargaAuxiliares()
        ]);

        if (!respDatos.ok) throw new Error('Error HTTP: ' + respDatos.status);
        const result = await respDatos.json();

        if (result.error) {
            modalBody.innerHTML = `<div class="alert alert-danger">${result.error}</div>`;
            return;
        }

        currentData = result.data;
        renderTabla(result.data, result.columns, tipo);

    } catch (error) {
        console.error(error);
        modalBody.innerHTML = `<div style="color:red; text-align:center;">Error al cargar datos: ${error.message}</div>`;
    }
};

window.renderTabla = function (data, columns, tipo) {
    const modalBody = document.getElementById('modalGestionBody');
    if (!data || data.length === 0) {
        modalBody.innerHTML = '<div style="text-align:center; padding:30px; color:#666;">No hay registros. <br>¡Crea el primero!</div>';
        return;
    }

    let html = '<div style="overflow-x:auto;"><table class="gestion-table">';
    html += '<thead><tr>';
    columns.forEach(col => { html += `<th>${col.label}</th>`; });
    html += '<th style="text-align:center;">Acciones</th></tr></thead><tbody>';

    data.forEach((row) => {
        const idKey = columns[0].key;
        html += '<tr>';
        columns.forEach(col => { html += `<td>${row[col.key] || ''}</td>`; });
        html += `<td style="text-align:center; white-space:nowrap;">
            <button class="btn-icon" onclick="prepararEdicion('${tipo}', ${row[idKey]})" title="Editar">
                 <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-pencil-square" viewBox="0 0 16 16" style="color:#36498f;">
                    <path d="M15.502 1.94a.5.5 0 0 1 0 .706L14.459 3.69l-2-2L13.502.646a.5.5 0 0 1 .707 0l1.293 1.293zm-1.75 2.456-2-2L4.939 9.21a.5.5 0 0 0-.121.196l-.805 2.414a.25.25 0 0 0 .316.316l2.414-.805a.5.5 0 0 0 .196-.12l6.813-6.814z"/>
                    <path fill-rule="evenodd" d="M1 13.5A1.5 1.5 0 0 0 2.5 15h11a1.5 1.5 0 0 0 1.5-1.5v-6a.5.5 0 0 0-1 0v6a.5.5 0 0 1-.5.5h-11a.5.5 0 0 1-.5-.5v-11a.5.5 0 0 1 .5-.5H9a.5.5 0 0 0 0-1H2.5A1.5 1.5 0 0 0 1 2.5v11z"/>
                </svg>
            </button>
            <button class="btn-icon" onclick="eliminarRegistro('${tipo}', ${row[idKey]})" title="Eliminar" style="margin-left:10px;">
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-trash-fill" viewBox="0 0 16 16" style="color:#dc3545;">
                    <path d="M2.5 1a1 1 0 0 0-1 1v1a1 1 0 0 0 1 1H3v9a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V4h.5a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H10a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1H2.5zm3 4a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 .5-.5zM8 5a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0v-7A.5.5 0 0 1 8 5zm3 .5v7a.5.5 0 0 1-1 0v-7a.5.5 0 0 1 1 0z"/>
                </svg>
            </button>
        </td></tr>`;
    });
    html += '</tbody></table></div>';
    modalBody.innerHTML = html;
};

window.prepararEdicion = function (tipo, id) {
    let pk = 'id_user';
    let targetTipo = tipo;
    let targetId = id;

    // Lógica para Productos (ELIMINADA REDIRECCION) - Ahora editamos el PRODUCTO en sí
    if (tipo === 'productos') {
        const rowGeneral = currentData.find(item => item.id == id);
        if (rowGeneral) {
            mostrarFormulario('productos', 'update', rowGeneral, 'productos');
            return;
        }
    }

    if (tipo !== 'usuarios' && tipo !== 'nuevos_mes' && tipo !== 'productos') {
        pk = tipo === 'clientes' ? 'id_cliente' : tipo === 'empleados' ? 'id_empleado' : 'id_prov';
    }

    // Fallback normal
    // If we are looking for 'instrumentos' or 'kits', and we are here, it means 'localData' in logica is different from instrumental.js?
    // Instrumental.js uses 'localData' locally. Logica.js uses 'currentData'.
    // When calling from instrumental.js, we pass the row!
    // But wait, instrumental.js: window.mostrarFormulario(type, 'update', row, 'local');
    // So 'data' IS passed. We don't need to look it up in 'currentData'.

    // However, pre-edit logic (window.prepararEdicion) in logica.js is for the TABLE view of logica.js.
    // Instrumental.js calls mostrarFormulario DIRECTLY.

    const row = currentData.find(item => item[pk] == id);
    if (row) mostrarFormulario(tipo, 'update', row, tipo);
};

window.mostrarFormulario = async function (tipo, accion, data = null, originType = null) {
    const modalBody = document.getElementById('modalGestionBody');
    const modalTitle = document.getElementById('modalGestionTitle');

    // Lazy Load Auxiliares if missing
    if (!window.auxiliares || Object.keys(window.auxiliares).length === 0) {
        if (modalBody) modalBody.innerHTML = '<div style="text-align:center; padding:30px;"><i class="fas fa-spinner fa-spin fa-2x"></i><p>Cargando datos auxiliares...</p></div>';
        await cargaAuxiliares();
    }
    const isEdit = accion === 'update';
    // Si no se pasa originType, asumir que es el mismo tipo
    const typeToReturn = originType || tipo;

    // Actualizar Título del Modal
    if (modalTitle) {
        let displayTipo = tipo.charAt(0).toUpperCase() + tipo.slice(1);
        if (tipo === 'materias_primas') displayTipo = 'Materia Prima';

        // Clean up any trailing 's' if not specifically materias primas (auto singular)
        if (tipo !== 'materias_primas' && accion !== 'list') {
            if (displayTipo === 'Proveedores') {
                displayTipo = 'Proveedor';
            } else if (displayTipo.endsWith('s')) {
                displayTipo = displayTipo.slice(0, -1);
            }
        }

        if (accion === 'create') {
            const isFeminine = ['Materia Prima', 'Materia_prima'].includes(displayTipo) || tipo === 'materias_primas';
            displayTipo = (isFeminine ? "Nueva " : "Nuevo ") + displayTipo;
        } else if (accion === 'update') {
            displayTipo = "Editar " + displayTipo;
        } else {
            displayTipo = "Gestión de " + displayTipo;
        }

        modalTitle.textContent = displayTipo;
    }

    // Hide 'Nuevo' button ONLY IF it exists and we are in a form view that shouldn't have it
    // The main dashboard uses this modal too.
    const btnNuevo = document.getElementById('btnNuevoRegistro');
    if (btnNuevo) {
        // En "Instrumental" (local), btnNuevo del modal suele estar oculto pq el botón de crear está afuera.
        // En "Dashboard" (usuarios), btnNuevo del modal es el PRINCIPAL.
        // Si estamos abriendo un FORMULARIO (accion create/update), ocultamos el botón de "Listado" (el + Nuevo del header del modal)
        // para que no se encima.
        btnNuevo.style.display = 'none';
    }



    // Calculate ID (Hoisted for Kit Builder usage)
    let idValue = 'null';
    if (data) {
        // Intentar encontrar el ID según el tipo
        if (tipo === 'instrumentos') idValue = data.id_instrumento || data.id;
        else if (tipo === 'kits') idValue = data.id_kit || data.id;
        else if (data.id) idValue = data.id;
        else idValue = Object.values(data)[0];
    }

    // === SPECIAL KIT BUILDER UI ===
    if (tipo === 'kits') {
        try {
            const modalContainer = document.getElementById('modalGestion');
            const modalContent = modalContainer.querySelector('.modal-content');
            if (modalContent) modalContent.classList.add('modal-large'); // Wide mode for kit builder

            // SAFE VARS
            const auxSpecs = (window.auxiliares && window.auxiliares.especializaciones) ? window.auxiliares.especializaciones : [];

            // Render Base Form + Instrument Builder
            let html = `
            <div style="background:var(--bg-secondary); padding:25px; border-radius:10px;">
                <form id="formGestionDinamico" onsubmit="guardarRegistro(event, '${tipo}', '${accion}', '${idValue}', '${typeToReturn}')">
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:20px; margin-bottom:20px;">
                        <!-- Column 1: Infomation -->
                        <div class="kit-info-col">
                            <div class="form-group">
                                <label>Nombre del Kit <span style="color:red">*</span></label>
                                <input type="text" name="nom_kit" class="form-user-input" value="${data ? (data.nom_kit || '') : ''}" required placeholder="Ej: Kit de Ortodoncia" maxlength="35">
                            </div>
                            <div class="form-group">
                                <label>Especialización <span style="color:red">*</span></label>
                                <select name="id_especializacion" class="form-user-input" required>
                                    <option value="">-- Seleccione --</option>
                                    ${auxSpecs.map(e => {
                const val = (typeof e === 'object' && e.id) ? e.id : e;
                const label = (typeof e === 'object' && e.label) ? e.label : e;
                const selected = (data && (data.id_especializacion == val || data.nom_especializacion == label)) ? 'selected' : '';
                return `<option value="${val}" ${selected}>${label}</option>`;
            }).join('')}
                </select>
                            </div>
                            <div class="form-group">
                                <label>Línea de Producción <span style="color:red">*</span></label>
                                <select name="tipo_mat" class="form-user-input" required>
                                    <option value="">-- Seleccione Material --</option>
                                    <option value="1" ${data && data.tipo_mat == 1 ? 'selected' : ''}>Specialized (Acero)</option>
                                    <option value="2" ${data && data.tipo_mat == 2 ? 'selected' : ''}>Special (Aluminio)</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>Cantidad Disponible <span style="color:red">*</span></label>
                                <input type="number" name="cant_disp" class="form-user-input" value="${data ? (data.cant_disp || '') : ''}" required min="1" max="999" oninput="if(this.value.length>3)this.value=this.value.slice(0,3)">
                            </div>
                            <div class="form-group">
                                <label>Stock Mínimo <span style="color:red">*</span></label>
                                <input type="number" name="stock_min" class="form-user-input" value="${data ? (data.stock_min || 0) : 0}" required min="1" max="999" oninput="if(this.value.length>3)this.value=this.value.slice(0,3)">
                            </div>
                            <div class="form-group">
                                <label>Stock Máximo <span style="color:red">*</span></label>
                                <input type="number" name="stock_max" class="form-user-input" value="${data ? (data.stock_max || 0) : 0}" required min="1" max="999" oninput="if(this.value.length>3)this.value=this.value.slice(0,3)">
                            </div>
                            <div class="form-group">
                                <label>Imagen <span style="color:red">*</span></label>
                                <input type="file" name="img_url" class="form-user-input" accept=".jpg,.png" ${(!data || !data.id_kit) ? 'required' : ''}>
                                ${(data && data.img_url && data.img_url.trim() !== '') ? `<small>Actual: <a href="${data.img_url}" target="_blank">Ver Imagen</a></small>` : ''}
                            </div>
                        </div>

                        <!-- Column 2: Instruments Builder -->
                        <div style="background:var(--bg-primary); padding:15px; border-radius:10px; border:1px solid var(--text-muted);">
                            <h3 style="margin-top:0; color:var(--header-blue);">Contenido del Kit</h3>
                            <p style="font-size:0.85rem; color:var(--text-muted);">Agrega los instrumentos que componen este kit (Máx 10).</p>
                            
                            <div id="kit-instruments-list" style="max-height:300px; overflow-y:auto; margin-bottom:15px;">
                                <!-- Instruments rows will go here -->
                            </div>

                            <button type="button" id="btn-add-inst-to-kit" style="width:100%; border:2px dashed var(--welcome-blue); background:none; color:var(--welcome-blue); padding:10px; border-radius:5px; cursor:pointer; font-weight:bold;">
                                <i class="fa-solid fa-plus"></i> Agregar Instrumento
                            </button>
                        </div>
                    </div>

                    <div class="form-actions" style="margin-top:20px; text-align:right; border-top:1px solid #eee; padding-top:20px;">
                        <button type="button" class="btn-modal btn-secondary" onclick="document.getElementById('modalGestion').style.display='none'">Cancelar</button>
                        <button type="submit" class="btn-modal btn-primary" style="margin-left:10px;">Guardar Kit</button>
                    </div>
                </form>
            </div>
            `;
            modalBody.innerHTML = html;

            // === Init Validations for Kit Form ===
            if (typeof window.initFormValidations === 'function') {
                const form = document.getElementById('formGestionDinamico');
                if (form) window.initFormValidations(form);
            }

            // === Auto-calc Stock for Kits ===
            const minInput = document.querySelector('input[name="stock_min"]');
            const maxInput = document.querySelector('input[name="stock_max"]');
            const cantInput = document.querySelector('input[name="cant_disp"]');

            const calcAvg = () => {
                if (minInput && maxInput && cantInput) {
                    const min = parseInt(minInput.value) || 0;
                    const max = parseInt(maxInput.value) || 0;
                    if (max > min) {
                        const avg = Math.floor((min + max) / 2);
                        cantInput.placeholder = `Sugerido: ${avg}`;
                        // cantInput.value = ... // Removed as per request
                    }
                }
            };
            if (minInput) minInput.addEventListener('change', calcAvg);
            if (maxInput) maxInput.addEventListener('change', calcAvg);

            // Logic for Instrument Builder
            const listContainer = document.getElementById('kit-instruments-list');
            const btnAddInst = document.getElementById('btn-add-inst-to-kit');
            const specSelect = document.querySelector('select[name="id_especializacion"]');
            const matSelect = document.querySelector('select[name="tipo_mat"]');

            // Load Instrument Options and Setup Filtering
            loadInstrumentOptions().then(options => {
                let filteredOptions = [];
                // === LÓGICA DE FILTRADO DINÁMICO ===
                // Esta función se encarga de cruzar los dos criterios principales:
                // 1. Especialización (Endodoncia, Ortodoncia, etc.)
                // 2. Línea de Producción (Acero/Specialized vs Aluminio/Special)
                // Solo si ambos están seleccionados, se muestran los instrumentos compatibles.
                const updateFilteredOptions = () => {
                    const selectedSpecId = specSelect.value;
                    const selectedMatId = matSelect.value;

                    if (!selectedSpecId || !selectedMatId) {
                        // Si no hay especialidad o material, no hay instrumentos que mostrar
                        filteredOptions = [];
                    } else {
                        // Filtrado por doble coincidencia: id_especializacion AND tipo_mat
                        // Usamos String() para asegurar comparación robusta independientemente del tipo (int/string)
                        filteredOptions = options.filter(o =>
                            String(o.id_especializacion) === String(selectedSpecId) &&
                            String(o.tipo_mat) === String(selectedMatId)
                        );
                    }
                    // Update existing selects? 
                    // Careful: if updating, we might have instruments that DON'T match spec if data is inconsistent? 
                    // Assuming data consistency.
                    const allSelects = listContainer.querySelectorAll('.inst-select');
                    allSelects.forEach(sel => {
                        const currentVal = sel.value;
                        const currentText = sel.options[sel.selectedIndex] ? sel.options[sel.selectedIndex].text : '';
                        // Re-populate
                        sel.innerHTML = '<option value="">Buscar instrumento...</option>' +
                            filteredOptions.map(o => `<option value="${o.id_instrumento}">${o.nom_instrumento}</option>`).join('');

                        // Try to restore value if it still exists in filtered list
                        // OR if it was already there (legacy data support)
                        if (currentVal) {
                            // Check if currentVal is in filteredOptions
                            const exists = filteredOptions.find(o => o.id_instrumento == currentVal);
                            if (exists) {
                                sel.value = currentVal;
                            } else {
                                // If not in filter, keep it? Or clear it? 
                                // Better keep it as a "hidden" valid option or warn?
                                // Let's add it manually to preserve data integrity if spec changed but inst wasn't removed yet
                                // sel.innerHTML += `<option value="${currentVal}" selected>${currentText} (No coincide esp.)</option>`;
                                sel.value = ""; // Clear for now to force consistency
                            }
                        }
                    });
                };

                // Listen to Changes
                specSelect.addEventListener('change', () => {
                    updateFilteredOptions();
                });
                matSelect.addEventListener('change', () => {
                    updateFilteredOptions();
                });

                // Init Filter
                updateFilteredOptions();

                const addRow = (instId = '') => {
                    if (listContainer.children.length >= 10) { alert('Máximo 10 instrumentos por kit.'); return; }
                    const row = document.createElement('div');
                    row.className = 'inst-row';
                    row.style.cssText = "display:flex; gap:10px; margin-bottom:10px; align-items:center; background:white; padding:10px; border-radius:5px; box-shadow:0 2px 5px rgba(0,0,0,0.05);";

                    // Use filtered options
                    // If instId exists (Edit mode) and it's NOT in filtered options (e.g. data inconsistency), 
                    // we should probably still show it.
                    let opts = filteredOptions;
                    if (instId && !opts.find(o => o.id_instrumento == instId)) {
                        const original = options.find(o => o.id_instrumento == instId);
                        if (original) opts = [...opts, original];
                    }

                    row.innerHTML = `
                        <select class="form-user-input inst-select" style="flex:2;" required name="instruments[]">
                            <option value="">Buscar instrumento...</option>
                            ${opts.map(o => `<option value="${o.id_instrumento}" ${o.id_instrumento == instId ? 'selected' : ''}>${o.nom_instrumento}</option>`).join('')}
                        </select>
                        <button type="button" style="border:none; background:none; color:#dc3545; cursor:pointer;" onclick="this.parentElement.remove()">
                            <i class="fa-solid fa-trash"></i>
                        </button>
                    `;
                    const select = row.querySelector('.inst-select');
                    select.addEventListener('change', function () {
                        const allSelects = listContainer.querySelectorAll('.inst-select');
                        const currentVal = this.value;
                        if (!currentVal) return;

                        let count = 0;
                        allSelects.forEach(s => { if (s.value === currentVal) count++; });
                        if (count > 1) {
                            alert("¡Este instrumento ya está en la lista! No puedes agregarlo dos veces.");
                            this.value = "";
                        }
                    });

                    listContainer.appendChild(row);
                };

                btnAddInst.onclick = () => {
                    if (!specSelect.value || !matSelect.value) {
                        alert("Por favor seleccione Especialización y Línea de Producción primero.");
                        return;
                    }
                    addRow();
                };

                if (accion === 'update' && data && data.id_kit) {
                    fetch(`api_gestion.php?tipo=kit_instruments&id=${data.id_kit}`)
                        .then(r => r.json())
                        .then(res => {
                            if (res.data && res.data.length > 0) {
                                res.data.forEach(inst => addRow(inst.id_instrumento));
                            }
                        })
                        .catch(e => console.error("Error fetching kit instruments:", e));
                } else if (accion === 'create') {
                    // addRow(); // Don't add default row, wait for spec selection
                }
            }).catch(err => console.error("Error loading instruments:", err));

            // EXIT FUNCTION CORRECTLY
            return;
        } catch (e) {
            console.error("Error rendering Kit Builder:", e);
            modalBody.innerHTML = `<div style="color:red; padding:20px;">Error al cargar el formulario de Kits: ${e.message}</div>`;
            return;
        }
    }

    const titulo = isEdit ? 'Editar Registro' : 'Nuevo Registro';
    const campos = obtenerEsquemaFormulario(tipo, data);

    // (ID logic moved to top of function)

    // Switch to narrow mode for forms
    const modalContainer = document.getElementById('modalGestion');
    const modalContent = modalContainer.querySelector('.modal-content');
    // Reset width override
    if (modalContent) modalContent.style.maxWidth = '';

    if (tipo === 'kits') {
        if (modalContent) modalContent.classList.add('modal-large');
    }
    // Custom width for Instruments as requested
    if (tipo === 'instrumentos') {
        if (modalContent) modalContent.style.maxWidth = '800px';
    }

    // Ajuste de layout: Si es usuarios, usar columna simple para orden vertical "arriba hacia abajo"
    const gridStyle = (tipo === 'usuarios')
        ? 'display:flex; flex-direction:column; gap:15px; max-width:400px; margin:0 auto; background:transparent;'
        : 'display:grid; grid-template-columns: 1fr 1fr; gap:25px; background:transparent;'; // Increased gap

    // ... (omitted cancelAction logic for brevity in replacement if possible, but strict replace needs context. Actually I can just replace the loop part for structural fix and the header for width)

    // Let's split into two replaces for safety or use a larger block. 
    // This tool call is for the structural fix in the loop.

    /* WE WILL USE A SEPARATE REPLACEMENT FOR WIDTH LOGIC TO BE SAFE */


    // Pre-calcular acción de cancelar para evitar errores de sintaxis en template string
    let cancelAction = '';
    let cancelLabel = 'Cancelar';

    if (typeToReturn === 'detalle' || originType === 'detalle') {
        cancelAction = `verDetalle('${tipo}', '${idValue}')`;
        cancelLabel = 'Volver';
    } else if (originType === 'local' || originType === 'local_materia' || originType === 'local_productos') {
        cancelAction = "document.getElementById('modalGestion').style.display='none'";
    } else {
        cancelAction = `abrirGestion('${typeToReturn}')`;
    }

    // Ocultar footer global para evitar duplicados (Botón Cerrar extra)
    const globalFooter = document.querySelector('#modalGestion .modal-footer');
    if (globalFooter) globalFooter.style.display = 'none';

    let boxClass = tipo === 'usuarios' || tipo === 'nuevos_mes' ? 'user-registration-wrapper' : '';
    let formContainerClass = tipo === 'usuarios' || tipo === 'nuevos_mes' ? 'form-user-container' : '';

    let html = `
        <div class="${boxClass}" style="max-width:700px; margin:0 auto; background:var(--bg-secondary); color:var(--text-main); padding:25px; border-radius:10px; box-shadow:0 2px 10px var(--card-shadow);">
            <div class="${formContainerClass}">
            <form id="formGestionDinamico" onsubmit="guardarRegistro(event, '${tipo}', '${accion}', '${idValue}', '${typeToReturn}')">
            <div style="${gridStyle}">
    `;



    campos.forEach(campo => {
        if (campo.type === 'hidden') {
            html += `<input type="hidden" name="${campo.name}" value="${campo.value || ''}">`;
            return; // Skip the rest of the visual wrapper
        }

        let groupClass = tipo === 'usuarios' || tipo === 'nuevos_mes' ? 'form-user-group' : 'form-group';
        let inputClass = tipo === 'usuarios' || tipo === 'nuevos_mes' ? 'form-user-input' : 'form-control';

        const span = (campo.fullWidth || tipo === 'usuarios') ? 'grid-column: span 2;' : '';
        const isHidden = campo.hidden ? 'display:none;' : '';
        html += `<div class="${groupClass}" style="margin-bottom:20px; padding:0; ${span} ${isHidden}">
            <label style="display:block; font-weight:600; margin-bottom:8px; color:var(--text-main);">${campo.label} ${campo.required ? '<span style="color:red">*</span>' : ''}</label>`;

        if (campo.type === 'select') {
            html += `<select name="${campo.name}" id="input_${campo.name}" class="${inputClass}" style="width:100%;" ${campo.required ? 'required' : ''}>
                <option value="">-- Seleccione --</option>`;
            campo.options.forEach(opt => {
                const selected = (campo.value == opt.id) ? 'selected' : '';
                html += `<option value="${opt.id}" ${selected}>${opt.label}</option>`;
            });
            html += `</select>`;
        } else if (campo.type === 'datalist') {
            let initialText = campo.initialText || '';
            if (!initialText && campo.value && campo.options) {
                const found = campo.options.find(o => o.id == campo.value);
                if (found) initialText = found.label;
            }

            html += `
                <input type="text" list="list_${campo.name}" 
                    name="display_${campo.name}"
                    data-validate-as="${campo.name}"
                    class="${inputClass}" 
                    style="width:100%; padding:10px; border:1px solid #ddd; border-radius:5px;"
                    value="${initialText}"
                    placeholder="Escriba para buscar..."
                    onchange="syncDatalist(this, '${campo.name}')"
                    oninput="syncDatalist(this, '${campo.name}')"
                    ${campo.required ? 'required' : ''}
                >
                <datalist id="list_${campo.name}">
                    ${campo.options.map(opt => `<option data-id="${opt.id}" value="${opt.label}"></option>`).join('')}
                </datalist>
                <input type="hidden" name="${campo.name}" id="${campo.name}" value="${campo.value || ''}">
            `;
        } else {
            let actualType = campo.type;
            let onInputAttr = '';
            let isNumeric = false;

            // Handle Numeric Fields: Convert to Text to remove steppers and add formatting
            if (actualType === 'number') {
                actualType = 'text'; // Fallback to text to remove browser UI arrows
                isNumeric = true;
                onInputAttr = `oninput="let v = this.value.replace(/[^0-9]/g, '');`;
                if (campo.maxLength) {
                    onInputAttr += ` if(v.length > ${campo.maxLength}) v = v.substring(0, ${campo.maxLength});`;
                }
                onInputAttr += ` this.value = v.replace(/\\B(?=(\\d{3})+(?!\\d))/g, '.');"`;
            } else if (actualType === 'tel') {
                let telInputHandlers = `this.value = this.value.replace(/[^0-9]/g, '');`;
                if (campo.maxLength) {
                    telInputHandlers += ` if(this.value.length > ${campo.maxLength}) this.value = this.value.substring(0, ${campo.maxLength});`;
                }
                onInputAttr = `oninput="${telInputHandlers}" autocomplete="off"`;
            }

            // Remove formatting for value assignment
            let initialValue = campo.value || '';
            if (campo.type === 'number' && initialValue) {
                initialValue = String(initialValue).replace(/\B(?=(\d{3})+(?!\d))/g, ".");
            }

            html += `<input type="${actualType}" name="${campo.name}" value="${initialValue}" 
                class="${inputClass}" style="width:100%;"
                ${isNumeric ? 'data-is-number="true"' : ''}
                ${campo.required ? 'required' : ''} ${campo.readonly ? 'readonly' : ''} 
                placeholder="${campo.placeholder || ''}"
                ${campo.max ? `max="${campo.max}"` : ''}
                ${campo.min ? `min="${campo.min}"` : ''}
                ${campo.maxLength && campo.type !== 'number' ? `maxlength="${campo.maxLength}"` : ''}
                ${onInputAttr}
                ${campo.pattern ? `pattern="${campo.pattern}"` : ''}
                ${campo.pattern ? `title="Formato requerido: ${campo.placeholder || 'Verifique el formato'}"` : ''}>`;
        }

        if (campo.helpText) {
            html += `<small class="form-text text-muted" style="display:block; margin-top:4px; color:var(--text-muted); font-size:0.85em; line-height:1.2;">${campo.helpText}</small>`;
        }
        html += `</div>`;
    });

    html += `
            </div>
            <div class="form-actions" style="margin-top:30px; text-align:right; border-top:1px solid #eee; padding-top:20px;">
                <button type="button" class="btn-modal btn-secondary" onclick="${cancelAction}">${cancelLabel}</button>
                <button type="submit" class="btn-modal btn-primary" style="margin-left:10px;">Guardar</button>
            </div>
            </form>
        </div>
        `;

    modalBody.innerHTML = html;
    
    // Adjuntar eventos onchange dinámicos si están definidos en el esquema
    campos.forEach(campo => {
        if (campo.onchange && typeof campo.onchange === 'function') {
            const el = document.getElementById('input_' + campo.name) || document.getElementsByName(campo.name)[0];
            if (el) {
                el.addEventListener('change', campo.onchange);
            }
        }
    });



    // === INICIALIZAR VALIDACIONES ===
    if (typeof window.initFormValidations === 'function') {
        const form = document.getElementById('formGestionDinamico');
        if (form) window.initFormValidations(form);
    }

    // Validaciones específicas de usuario (contraseña segura en tiempo real)
    if (tipo === 'usuarios' || tipo === 'nuevos_mes') {
        if (typeof window.initUserFormValidation === 'function') {
            window.initUserFormValidation('formGestionDinamico');
        }
    }




    // === Instrumentos: Auto-cálculo de Stock ===
    if (tipo === 'instrumentos') {
        const minInput = document.querySelector('input[name="stock_min"]');
        const maxInput = document.querySelector('input[name="stock_max"]');
        const cantInput = document.querySelector('input[name="cant_disp"]');

        const calcAvg = () => {
            if (minInput && maxInput && cantInput) {
                const min = parseInt(minInput.value) || 0;
                const max = parseInt(maxInput.value) || 0;
                if (max > min) {
                    const avg = Math.floor((min + max) / 2);
                    cantInput.placeholder = `Sugerido: ${avg}`;
                }
            }
        };

        if (minInput) minInput.addEventListener('change', calcAvg);
        if (maxInput) maxInput.addEventListener('change', calcAvg);
        if (minInput) minInput.addEventListener('change', calcAvg);
        if (maxInput) maxInput.addEventListener('change', calcAvg);
    }

    // === LOGICA ESPECIFICA PARA PRODUCTOS (XOR: Kit vs Instrumento) ===
    if (tipo === 'productos') {
        // Cargar opciones si no existen (Datalists)
        Promise.all([loadInstrumentOptions(), loadKitOptions()]).then(([instrs, kits]) => {
            // Populate Datalists manually if empty (Or let obtainingSchema handle it? Schema needs values synchronous?)
            // Schema already returned inputs with empty options or headers.
            // We need to inject options into the Selects/Datalists
            const selInst = document.getElementById('list_id_instrumento'); // Datalist ID
            const selKit = document.getElementById('list_id_kit'); // Datalist ID

            if (selInst) {
                selInst.innerHTML = instrs.map(i => `<option data-id="${i.id_instrumento}" value="${i.nom_instrumento} (Stock: ${i.cant_disp})">`).join('');
            }
            if (selKit) {
                selKit.innerHTML = kits.map(k => `<option data-id="${k.id_kit}" value="${k.nom_kit} (Stock: ${k.cant_disp})">`).join('');
            }
        });

        const selDis = document.querySelector('select[name="discriminador"]');
        // Find inputs by name (they are datalists inputs usually, or selects)
        // In schema below I will use DATALIST for instruments/kits to handle large lists
        // The input name is "id_instrumento" (hidden) but the visible one is valid too.
        // Actually, let's use the container div.

        const inputInst = document.querySelector('input[name="id_instrumento"]');
        const inputKit = document.querySelector('input[name="id_kit"]');

        if (selDis && inputInst && inputKit) {
            const divInst = inputInst.closest('.form-group');
            // The datalist visible input is previous sibling usually? 
            // My helper renders: input(text) ... datalist ... input(hidden)
            // So closest .form-group works.
            const divKit = inputKit.closest('.form-group');

            const toggle = () => {
                const val = selDis.value;
                if (val === 'instrumento') {
                    divInst.style.display = 'block';
                    divKit.style.display = 'none';
                    inputKit.value = ''; // Clean hidden
                    // Clean visible input too
                    const visibleKit = divKit.querySelector('input[list]');
                    if (visibleKit) visibleKit.value = '';
                } else if (val === 'kit') {
                    divInst.style.display = 'none';
                    divKit.style.display = 'block';
                    inputInst.value = '';
                    const visibleInst = divInst.querySelector('input[list]');
                    if (visibleInst) visibleInst.value = '';
                } else {
                    divInst.style.display = 'none';
                    divKit.style.display = 'none';
                }
            };

            selDis.addEventListener('change', toggle);

            // Initial State: If editing, detect based on data
            if (data && data.tipo) {
                selDis.value = data.tipo; // 'instrumento' or 'kit'
            }
            toggle();
        }
    }


    // === MOSTRAR EL MODAL ===
    const modalToOpen = document.getElementById('modalGestion');
    if (modalToOpen) {
        modalToOpen.style.display = 'block';
    }
};

// ESQUEMAS COMPLETOS SEGUN DB FUNCTIONS
function obtenerEsquemaFormulario(tipo, data = {}) {
    // Si existe un esquema refactorizado en los controladores core, úsalo
    if (window.FormSchemas && typeof window.FormSchemas[tipo] === 'function') {
        return window.FormSchemas[tipo](data);
    }

    const d = data || {};

    // Obtener auxiliares globales o vacíos
    const aux = window.auxiliares || {};

    // Mapeo de auxiliares
    // La función SQL devuele strings para algunos y objetos {id, label} para especializaciones
    const mapOptions = (list) => {
        if (!list) return [];
        return list.map(item => {
            if (typeof item === 'object' && item !== null) {
                if (item.label) return item;
                // Auto-map common fields from Controller (Raw DB columns)
                const id = item.id || item.id_documento || item.id_ciudad || item.id_cargo || item.id_tipo_sangre || item.id_banco || item.id_especializacion || item.id_genero || item.id_unidad_medida;
                const label = item.label || item.nom_tipo_docum || item.nom_ciudad || item.nom_cargo || item.nom_tip_sang || item.nom_banco || item.nom_espec || item.nom_especializacion || item.nom_genero || item.nom_unidad;
                if (id && label) return { id, label };
            }
            return { id: item, label: item };
        });
    };




    return [];
}

// ...

window.guardarRegistro = async function (event, tipo, accion, id, originType = null) {
    event.preventDefault();
    if (id === 'null') id = null;

    const form = event.target;

    // === VALIDAR ANTES DE ENVIAR ===
    if (typeof window.checkFormValidity === 'function') {
        if (!window.checkFormValidity(form)) {
            // Si hay errores, mostrar mensaje genérico o dejar que el usuario vea los rojos
            if (typeof window.mostrarErrorCustom === 'function') {
                window.mostrarErrorCustom('Datos inválidos', 'Por favor corrija los campos marcados en rojo.');
            } else {
                alert('Por favor corrija los campos marcados en rojo.');
            }
            return;
        }
    }

    const btnSubmit = form.querySelector('button[type="submit"]');
    const oldText = btnSubmit.textContent;

    // === VALIDACION DIRECTA DE IMAGEN (ULTIMO INTENTO) ===
    // Si es CREATE de Instrumentos o Kits, VALIDAR INPUT FILE DIRECTAMENTE
    // Usamos 'accion' porque 'id' puede ser engañoso
    if (accion === 'create' && (tipo === 'instrumentos' || tipo === 'kits')) {
        const fileInput = form.querySelector('input[name="img_url"]');
        if (fileInput && fileInput.files.length === 0) {
            alert("⚠️ DEBE SELECCIONAR UNA IMAGEN OBLIGATORIAMENTE.");
            // Tambien usar modal custom si existe
            if (typeof window.mostrarErrorCustom === 'function') {
                window.mostrarErrorCustom('Imagen Requerida', 'Es obligatorio subir una imagen para crear el registro.');
            }
            return; // DETENER EJECUCION
        }
    }

    btnSubmit.disabled = true;

    mostrarCargando();
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Si estamos en la vista de 'nuevos_mes', guardamos como 'usuarios'
    const tipoEnvio = (tipo === 'nuevos_mes') ? 'usuarios' : tipo;

    try {
        const formData = new FormData(form);
        const dataObj = {};
        const finalFormData = new FormData();

        finalFormData.append('accion', accion);
        finalFormData.append('tipo', tipoEnvio);
        if (id) finalFormData.append('id', id);

        // Separar archivos de datos texto y VALIDAR
        for (let [key, value] of formData.entries()) {
            if (value instanceof File) {
                if (value.size > 0) {
                    // VALIDACIÓN DE TIPO (Solo JPG/PNG)
                    const validTypes = ['image/jpeg', 'image/png', 'image/jpg'];
                    if (!validTypes.includes(value.type)) {
                        ocultarCargando();
                        mostrarErrorCustom('Archivo no permitido', 'Solo se permiten imágenes JPG o PNG.');
                        btnSubmit.disabled = false;
                        btnSubmit.textContent = oldText;
                        return; // Detener envío
                    }

                    // VALIDACIÓN DE TAMAÑO (Max 5MB)
                    const maxSize = 5 * 1024 * 1024; // 5MB
                    if (value.size > maxSize) {
                        ocultarCargando();
                        mostrarErrorCustom('Archivo muy pesado', 'La imagen no puede pesar más de 5MB.');
                        btnSubmit.disabled = false;
                        btnSubmit.textContent = oldText;
                        return; // Detener envío
                    }

                    finalFormData.append(key, value);
                }
            } else {
                // Remove formatting dots before sending ONLY if it's a formatted numeric field
                let cleanValue = value;
                const inputElement = form.querySelector(`[name="${key}"]`);
                if (inputElement && inputElement.getAttribute('data-is-number') === 'true' && typeof value === 'string') {
                    cleanValue = value.replace(/\./g, '');
                }

                // HANDLER FOR ARRAYS (instruments[])
                if (key.endsWith('[]')) {
                    const realKey = key.slice(0, -2); // remove []
                    if (!dataObj[realKey]) dataObj[realKey] = [];
                    dataObj[realKey].push(cleanValue);
                } else {
                    // Normalizar campos opcionales que ahora son NOT NULL DEFAULT 'N/A'
                    const optionalFields = ['observaciones', 'observ', 'motivo', 'ind_calidad', 'lote', 'tipo_mat_prima', 'reg_invima', 'segun_nom', 'segun_apell'];
                    if (optionalFields.includes(key) && (cleanValue === '' || cleanValue === null)) {
                        cleanValue = 'N/A';
                    }
                    dataObj[key] = cleanValue;
                }
            }
        }

        // VALIDATION: IMAGE REQUIRED FOR CREATE (Instruments & Kits)
        if (accion === 'create' && (tipo === 'instrumentos' || tipo === 'kits')) {
            // Si el loop anterior no agrego la imagen (por ser size 0 o no existir), es error.
            if (!finalFormData.has('img_url')) {
                ocultarCargando();
                mostrarErrorCustom('Imagen requerida', 'Debes seleccionar una imagen para crear el registro.');
                btnSubmit.disabled = false;
                btnSubmit.textContent = oldText;
                return;
            }
        }

        // VALIDATION: MIN 3 INSTRUMENTS FOR KITS
        if (tipo === 'kits' && accion === 'create') {
            if (!dataObj['instruments'] || dataObj['instruments'].length < 3) {
                ocultarCargando();
                mostrarErrorCustom('Kit Incompleto', 'El kit debe tener al menos 3 instrumentos.');
                btnSubmit.disabled = false;
                btnSubmit.textContent = oldText;
                return;
            }
        }

        finalFormData.append('data', JSON.stringify(dataObj));

        const response = await fetch('./api_gestion.php', {
            method: 'POST',
            body: finalFormData // Enviar como multipart/form-data
        });

        const text = await response.text();
        let result;
        try {
            result = JSON.parse(text);
        } catch (e) {
            console.error("Respuesta no JSON:", text);
            throw new Error("El servidor devolvió un error: " + text.substring(0, 200));
        }

        // Ocultar cargando
        ocultarCargando();

        if (result.success) {
            mostrarExitoCustom('Registro guardado correctamente', function () {
                window.location.reload();
            });
        } else {
            const rawError = result.error || 'Error desconocido';
            let cleanError = rawError;
            
            // Si el error viene de la validación BD, tratar de ser más específico
            if (rawError.includes('Validación BD') || rawError.includes('Error al actualizar empleado')) {
                cleanError = "No se pudo actualizar el registro debido a una restricción de la base de datos (Ej: Documento duplicado o formato incompatible). Por favor verifique los campos.";
            }

            mostrarErrorCustom('Error en la operación', cleanError);
            btnSubmit.disabled = false;
            btnSubmit.textContent = oldText;
        }
    } catch (error) {
        ocultarCargando();
        console.error(error);
        mostrarErrorCustom('Error de conexión', error.message || 'No se pudo conectar con el servidor.');
        btnSubmit.disabled = false;
        btnSubmit.textContent = oldText;
    }
};

window.eliminarRegistro = async function (tipo, id) {
    const result = await Swal.fire({
        title: '¿Estás seguro?',
        text: "¡No podrás revertir esto!",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#3085d6',
        cancelButtonColor: '#d33',
        confirmButtonText: 'Sí, eliminarlo',
        cancelButtonText: 'Cancelar'
    });

    if (result.isConfirmed) {
        const tipoEnvio = (tipo === 'nuevos_mes') ? 'usuarios' : tipo;
        try {
            const response = await fetch('./api_gestion.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ accion: 'delete', tipo: tipoEnvio, id })
            });
            const res = await response.json();
            if (res.success) {
                Swal.fire(
                    '¡Eliminado!',
                    'El registro ha sido eliminado.',
                    'success'
                );
                abrirGestion(tipo);
                actualizarContadores();
            }
        } catch (error) { Swal.fire('Error', 'Error de conexión', 'error'); }
    }
};

// === K. UTILS: SWEETALERT2 INTEGRATION ===
function mostrarCargando() {
    Swal.fire({
        title: 'Cargando...',
        text: 'Por favor espere un momento',
        allowOutsideClick: false,
        didOpen: () => {
            Swal.showLoading();
        }
    });
}

function ocultarCargando() {
    Swal.close();
}

/**
 * Muestra una alerta de éxito con auto-cierre opcional
 * @param {string} mensaje 
 * @param {function} callback 
 */
function mostrarExitoCustom(mensaje, callback) {
    Swal.fire({
        title: '¡Éxito!',
        text: mensaje,
        icon: 'success',
        timer: 3000,
        timerProgressBar: true,
        confirmButtonText: 'Aceptar',
        confirmButtonColor: '#36498f'
    }).then((result) => {
        // Ejecutar callback si el timer expira o se pulsa el botón
        if (callback) callback();
    });
}

/**
 * Muestra una alerta de error
 * @param {string} titulo 
 * @param {string} mensaje 
 */
function mostrarErrorCustom(titulo, mensaje) {
    Swal.fire({
        title: titulo,
        text: mensaje,
        icon: 'error',
        confirmButtonText: 'Cerrar',
        confirmButtonColor: '#dc3545'
    });
}

/**
 * Muestra un diálogo de confirmación personalizado (HTML)
 */
function mostrarConfirmacionCustom(titulo, mensaje, callbackAceptar, btnText = 'Sí, continuar', btnColor = '#36498f') {
    const modal = document.getElementById('modalConfirmacionCustom');
    const titleEl = document.getElementById('confirmTitle');
    const messageEl = document.getElementById('confirmMessage');
    const btnAccept = document.getElementById('confirmBtnAccept');

    if (modal && titleEl && messageEl && btnAccept) {
        titleEl.textContent = titulo;
        messageEl.textContent = mensaje;
        btnAccept.textContent = btnText;
        
        // Manejar el clic en aceptar
        btnAccept.onclick = function() {
            cerrarConfirmacionCustom();
            if (callbackAceptar) callbackAceptar();
        };

        modal.style.display = 'block';
    }
}

window.cerrarConfirmacionCustom = function() {
    const modal = document.getElementById('modalConfirmacionCustom');
    if (modal) modal.style.display = 'none';
};

window.abrirModalConfig = function() {
    if (typeof abrirModalAccesibilidad === 'function') {
        abrirModalAccesibilidad();
    }
};


window.guardarRegistroUsuario = async function (event) {
    event.preventDefault();
    const form = event.target;
    const btn = form.querySelector('button[type="submit"]');
    const oldText = btn.textContent;

    btn.disabled = true;

    // 1. Mostrar "Guardando..."
    mostrarCargando();

    // 2. Esperar 1 segundo (Simulado, según requerimiento)
    await new Promise(resolve => setTimeout(resolve, 1000));

    const formData = new FormData(form);

    try {
        const response = await fetch('./registrar.php', {
            method: 'POST',
            body: formData
        });

        // Parsear JSON (ya no usamos redirects)
        let result;
        try {
            result = await response.json();
        } catch (err) {
            // Fallback si no es JSON válido
            throw new Error("Respuesta inválida del servidor");
        }

        // Ocultamos cargando antes de mostrar el resultado
        ocultarCargando();

        if (result.success) {
            // 3. Mostrar modal de Éxito Custom
            mostrarExitoCustom(result.message || 'Usuario creado con éxito', function () {
                // 4. Al dar aceptar, RECARGAR LA PÁGINA
                window.location.reload();
            });
        } else {
            mostrarErrorCustom('Error', result.error || 'Error desconocido');
            btn.disabled = false;
            btn.textContent = oldText;
        }
    } catch (e) {
        ocultarCargando();
        console.error("Error en fetch:", e);
        mostrarErrorCustom('Error de Conexión', e.message || 'No se pudo contactar con el servidor.');
        btn.disabled = false;
        btn.textContent = oldText;
    }
};

window.eliminarRegistro = function (tipo, id) {
    mostrarConfirmacionCustom(
        '¿Estás seguro?',
        '¡No podrás revertir esto! Se inhabilitará el registro.',
        async function () {
            const tipoEnvio = (tipo === 'nuevos_mes') ? 'usuarios' : tipo;

            mostrarCargando();

            try {
                const response = await fetch('./api_gestion.php', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ accion: 'delete', tipo: tipoEnvio, id })
                });
                const res = await response.json();

                ocultarCargando();

                if (res.success) {
                    mostrarExitoCustom('El registro ha sido eliminado exitosamente.', function () {
                        window.location.reload();
                    });
                } else {
                    mostrarErrorCustom('Error', res.error || 'No se pudo eliminar.');
                }
            } catch (error) {
                ocultarCargando();
                mostrarErrorCustom('Error', 'Error de conexión');
            }
        }
    );
};

// === FUNCIONES DE VALIDACIÓN Y REGISTRO DE USUARIO (SOLUCIÓN REFACTORIZADA) ===

window.initUserFormValidation = function (formId = 'formNuevoUsuario') {
    const form = document.getElementById(formId);
    if (!form) return;

    const inputs = form.querySelectorAll('input:not([type="hidden"])');

    inputs.forEach(input => {
        // Crear elemento para mensaje si no existe
        let msg = input.parentNode.querySelector('.validation-msg');
        if (!msg) {
            msg = document.createElement("div");
            msg.className = "validation-msg";
            // Add a little padding to the message for the new dynamic layout
            msg.style.marginTop = "5px";
            msg.style.fontSize = "0.85em";
            input.parentNode.appendChild(msg);
        }

        input.addEventListener('focus', () => showHelp(input, msg));
        input.addEventListener('input', () => validateInput(input, msg));
        input.addEventListener('blur', () => { setTimeout(() => msg.style.display = 'none', 200); });
    });

    function showHelp(input, msg) {
        msg.style.display = 'block';
        if (input.name === 'usuario' || input.name === 'nom_user') msg.textContent = "3-50 caracteres, letras y números.";
        if (input.name === 'mail_user') msg.textContent = "Ingresa un correo electrónico válido.";
        if (input.name === 'tel_user') msg.textContent = "Solo números (7-10 dígitos).";
        if (input.name === 'password' || input.name === 'pass_user') msg.textContent = "Min. 8 caracteres, 1 Mayúscula, 1 Minúscula, 1 Número.";
    }

    function validateInput(input, msg) {
        msg.style.display = 'block';
        let valid = true;

        // Usuario
        if (input.name === 'usuario' || input.name === 'nom_user') {
            if (!/^[a-zA-Z0-9_\s]{3,50}$/.test(input.value)) { // Added space for 'Nombre completo' if used as nom_user
                msg.style.color = "#dc3545";
                msg.textContent = "3-50 caracteres, no símbolos especiales raros.";
                valid = false;
            } else {
                msg.style.color = "#087d4e";
                msg.textContent = "Usuario válido.";
            }
        }
        // Email
        if (input.name === 'mail_user') {
            if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.value)) {
                msg.style.color = "#dc3545";
                msg.textContent = "Correo inválido.";
                valid = false;
            } else {
                msg.style.color = "#087d4e";
                msg.textContent = "Correo válido.";
            }
        }
        // Teléfono
        if (input.name === 'tel_user') {
            // Strip dots if formatted
            const cleanTel = input.value.replace(/\./g, '');
            if (!/^[0-9]{6,10}$/.test(cleanTel)) {
                msg.style.color = "#dc3545";
                msg.textContent = "Debe tener entre 6 y 10 dígitos numéricos.";
                valid = false;
            } else {
                msg.style.color = "#087d4e";
                msg.textContent = "Teléfono válido.";
            }
        }
        // Password
        if (input.name === 'password' || input.name === 'pass_user') {
            const val = input.value;
            // Let's enforce the DB rules: uppercase, numbers, at least 6-8 chars.
            if (val.length < 6 || !/[A-Z]/.test(val) || !/[0-9]/.test(val)) {
                msg.style.color = "#dc3545";
                // Mensaje detallado
                let errs = [];
                if (val.length < 6) errs.push("6+ caracteres");
                if (!/[A-Z]/.test(val)) errs.push("1 Mayúscula");
                if (!/[0-9]/.test(val)) errs.push("1 Número");
                msg.textContent = "Faltan: " + errs.join(", ");
                valid = false;
            } else {
                msg.style.color = "#087d4e";
                msg.textContent = "Contraseña segura.";
            }
        }
        return valid;
    }
};




// === 4. VALIDACIÓN DE CONTRASEÑA (ADMIN) ===
document.addEventListener('DOMContentLoaded', function () {
    setupPasswordValidationAdmin();
});

function setupPasswordValidationAdmin() {
    const newPassInput = document.getElementById('password_nueva');
    const confirmPassInput = document.getElementById('password_confirmar');

    if (!newPassInput || !confirmPassInput) return;

    // Icons & Help Text
    const checkIcon = document.getElementById('checkIconAdmin');
    const errorIcon = document.getElementById('errorIconAdmin');
    const matchIcon = document.getElementById('matchIconAdmin');
    const passHelp = document.getElementById('passwordHelpAdmin');
    const confirmHelp = document.getElementById('confirmHelpAdmin');

    // 1. Validate Password Strength
    newPassInput.addEventListener('input', function () {
        const password = this.value;
        const validations = [
            password.length >= 8,
            /[A-Z]/.test(password),
            /[0-9]/.test(password)
        ];
        const allValid = validations.every(v => v);

        if (password.length === 0) {
            passHelp.textContent = 'Mínimo 8 caracteres, mayúscula y número';
            passHelp.style.color = '#666';
            if (checkIcon) checkIcon.style.opacity = '0';
            if (errorIcon) errorIcon.style.opacity = '0';
        } else if (allValid) {
            passHelp.textContent = 'Contraseña segura';
            passHelp.style.color = '#2ecc71';
            if (checkIcon) checkIcon.style.opacity = '1';
            if (errorIcon) errorIcon.style.opacity = '0';
        } else {
            passHelp.textContent = 'Debe tener 8+ caracteres, mayúscula y número';
            passHelp.style.color = '#e74c3c';
            if (checkIcon) checkIcon.style.opacity = '0';
            if (errorIcon) errorIcon.style.opacity = '1';
        }

        validateMatchAdmin();
    });

    // 2. Validate Match
    confirmPassInput.addEventListener('input', validateMatchAdmin);

    function validateMatchAdmin() {
        const pass1 = newPassInput.value;
        const pass2 = confirmPassInput.value;

        if (pass2.length === 0) {
            confirmHelp.textContent = 'Las contraseñas deben coincidir';
            confirmHelp.style.color = '#666';
            if (matchIcon) matchIcon.style.opacity = '0';
            return;
        }

        if (pass1 === pass2 && pass1.length > 0) {
            confirmHelp.textContent = 'Las contraseñas coinciden';
            confirmHelp.style.color = '#2ecc71';
            if (matchIcon) matchIcon.style.opacity = '1';
        } else {
            confirmHelp.textContent = 'Las contraseñas no coinciden';
            confirmHelp.style.color = '#e74c3c';
            if (matchIcon) matchIcon.style.opacity = '0';
        }
    }
}





