/**
 * JavaScript/controllers/instrumental_controller.js
 * Controlador para la gestión de Instrumentos y Kits
 */

// --- 1. SCHEMAS PARA FORMULARIOS ---
window.FormSchemas = window.FormSchemas || {};

window.FormSchemas['instrumentos'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};

    const mapOptions = (list) => {
        if (!list) return [];
        return list.map(item => {
            if (typeof item === 'object' && item !== null) {
                if (item.label) return item;
                const id = item.id || item.id_especializacion;
                const label = item.label || item.nom_espec || item.nom_especializacion;
                if (id && label) return { id, label };
            }
            return { id: item, label: item };
        });
    };

    const optEspecializaciones = mapOptions(aux.especializaciones);
    const optMateriales = [
        { id: 1, label: 'Specialized (Acero)' },
        { id: 2, label: 'Special (Aluminio)' }
    ];

    return [
        { label: 'Nombre Instrumento', name: 'nom_instrumento', type: 'text', value: d.nom_instrumento || d.nombre, required: true, fullWidth: true, placeholder: 'Ej: Espejo Bucal No. 5', maxLength: 35, helpText: 'Nombre descriptivo (Máx 35 caracteres).' },
        { label: 'Especialización', name: 'id_especializacion', type: 'select', options: optEspecializaciones, value: d.id_especializacion || d.especializacion, required: true, placeholder: '-- Seleccione --', helpText: 'Categoría médica del instrumento.' },
        { label: 'Línea de Producción', name: 'tipo_mat', type: 'select', options: optMateriales, value: d.tipo_mat, required: true, placeholder: '-- Seleccione --', helpText: 'Material: Specialized (Acero) o Special (Aluminio).' },
        { label: 'Stock Mínimo', name: 'stock_min', type: 'number', value: d.stock_min || 0, required: true, placeholder: 'Ej: 10', min: 1, max: 999, maxLength: 3, helpText: 'Alerta de stock bajo.' },
        { label: 'Stock Máximo', name: 'stock_max', type: 'number', value: d.stock_max || 0, required: true, placeholder: 'Ej: 100', min: 1, max: 999, maxLength: 3, helpText: 'Límite máximo.' },
        { label: 'Cantidad Disponible', name: 'cant_disp', type: 'number', value: d.cant_disp, required: true, placeholder: 'Ej: 50', min: 1, max: 999, maxLength: 3, helpText: 'Unidades actuales.' },
        { label: 'Lote', name: 'lote', type: 'text', value: d.lote, required: false, placeholder: 'Ej: 101', maxLength: 3, helpText: 'Código numérico (Máx 3 dígitos).' },
        { label: 'Numeral en Kit', name: 'numeral_en_kit', type: 'number', value: d.numeral_en_kit || 0, required: false, placeholder: '0', helpText: 'Orden dentro del kit.' },
        { label: 'Imagen del Instrumento', name: 'img_url', type: 'file', accept: '.jpg, .png', required: !d.id_instrumento, fullWidth: true, placeholder: 'Seleccionar imagen JPG/PNG', helpText: 'Formato JPG/PNG, Máx 5MB.' }
    ];
};

window.FormSchemas['kits'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};

    const mapOptions = (list) => {
        if (!list) return [];
        return list.map(item => {
            if (typeof item === 'object' && item !== null) {
                if (item.label) return item;
                const id = item.id || item.id_especializacion;
                const label = item.label || item.nom_espec || item.nom_especializacion;
                if (id && label) return { id, label };
            }
            return { id: item, label: item };
        });
    };

    const optEspecializaciones = mapOptions(aux.especializaciones);
    const optMateriales = [
        { id: 1, label: 'Specialized (Acero)' },
        { id: 2, label: 'Special (Aluminio)' }
    ];

    return [
        { label: 'Especialización', name: 'nom_especializacion', type: 'select', options: optEspecializaciones, value: d.nom_especializacion || d.especializacion, required: true, placeholder: '-- Seleccione --', helpText: 'Especialización médica de este kit.' },
        { label: 'Nombre Kit', name: 'nom_kit', type: 'text', value: d.nom_kit || d.nombre, required: true, fullWidth: true, placeholder: 'Ej: Kit de Ortodoncia Básico', maxLength: 35, helpText: 'Nombre descriptivo (Máx 35 caracteres).' },
        { label: 'Línea de Producción', name: 'tipo_mat', type: 'select', options: optMateriales, value: d.tipo_mat, required: true, placeholder: '-- Seleccione --', helpText: 'Línea: Specialized (Acero) o Special (Aluminio).' },
        { label: 'Cantidad Disponible', name: 'cant_disp', type: 'number', value: d.cant_disp, required: true, placeholder: 'Ej: 20', helpText: 'Unidades completas disponibles.' },
        { label: 'Stock Mínimo', name: 'stock_min', type: 'number', value: d.stock_min || 0, required: true, placeholder: 'Ej: 5', helpText: 'Alerta de reabastecimiento.' },
        { label: 'Stock Máximo', name: 'stock_max', type: 'number', value: d.stock_max || 0, required: true, placeholder: 'Ej: 50', helpText: 'Límite de almacenamiento.' },
        { label: 'Imagen del Kit', name: 'img_url', type: 'file', accept: '.jpg, .png', required: !d.id_kit, fullWidth: true, placeholder: 'Seleccionar imagen JPG/PNG', helpText: 'Imagen representativa del kit.' }
    ];
};

// --- 2. VALIDACIONES ESPECIFICAS ---
window.ValidationRules = window.ValidationRules || {};

Object.assign(window.ValidationRules, {
    lote: {
        validate: (val) => {
            if (val.length > 3) return { valid: false, msg: "Máximo 3 caracteres." };
            if (/^-?\d+$/.test(val) && parseInt(val) < 0) return { valid: false, msg: "No puede ser menor a 0." };
            return { valid: true, msg: "Lote válido." };
        }
    },

    nom_kit: {
        validate: (val) => {
            if (val.length > 35) return { valid: false, msg: "El nombre no puede exceder 35 caracteres." };
            if (!val) return { valid: false, msg: "Requerido." };
            return { valid: true, msg: "Nombre válido." };
        }
    },
    cant_disp: {
        validate: (val) => {
            const n = parseInt(val);
            if (isNaN(n)) return { valid: false, msg: "Debe ser un número." };
            if (n < 0) return { valid: false, msg: "La cantidad no puede ser negativa." };
            return { valid: true, msg: "Cantidad válida." };
        }
    },
    stock_min: {
        validate: (val) => {
            if (!val || val.trim() === '') return { valid: false, msg: "Requerido." };
            const n = parseInt(val);
            if (isNaN(n)) return { valid: false, msg: "Número inválido." };
            if (n <= 0) return { valid: false, msg: "Debe ser mayor a 0." };
            return { valid: true, msg: "Válido." };
        }
    },
    stock_max: {
        validate: (val) => {
            if (!val || val.trim() === '') return { valid: false, msg: "Requerido." };
            const n = parseInt(val);
            if (isNaN(n)) return { valid: false, msg: "Número inválido." };
            if (n <= 0) return { valid: false, msg: "Debe ser mayor a 0." };
            return { valid: true, msg: "Válido." };
        }
    }
});


// --- 3. LOGICA DE VISTAS (Anterior instrumental.js) ---

document.addEventListener('DOMContentLoaded', function () {
    const btnInstrumental = document.getElementById('btn-instrumental');
    const mainContent = document.querySelector('.a2');

    let currentView = null; // 'instrumentos' o 'kits'

    if (btnInstrumental && mainContent) {
        btnInstrumental.addEventListener('click', function (e) {
            e.preventDefault();
            loadSelectionView();
        });
    }

    // Export global view function
    window.loadSelectionView = function (container) {
        const targetContainer = container || document.getElementById('dynamic-view') || document.querySelector('.a2');
        targetContainer.innerHTML = '';
        currentView = null;

        const viewWrapper = document.createElement('div');
        viewWrapper.className = 'instrumental-view-wrapper';
        viewWrapper.style.cssText = 'display: flex; flex-direction: column; width: 100%; height: 100%; overflow-y: auto;';

        const selectionContainer = document.createElement('div');
        selectionContainer.className = 'instrumental-selection-container';

        injectStyles();

        selectionContainer.innerHTML = `
            <div class="selection-card instrumentos" id="card-instrumentos">
                <div class="card-icon"><img src="../../images/instrum.png" alt="Instrumentos" class="card-img"></div>
                <div class="card-title">Instrumentos</div>
                <div class="card-description">Gestión de herramientas de precisión individuales.</div>
            </div>

            <div class="selection-card kits" id="card-kits">
                <div class="card-icon"><img src="../../images/kit.png" alt="Kits" class="card-img"></div>
                <div class="card-title">Kits</div>
                <div class="card-description">Gestión de conjuntos y paquetes especializados.</div>
            </div>
        `;

        viewWrapper.appendChild(selectionContainer);

        // --- BOTÓN DE MOVIMIENTO GLOBAL (NUEVO) ---
        const globalActions = document.createElement('div');
        globalActions.className = 'global-actions-container';
        globalActions.style.cssText = 'display: flex; justify-content: center; padding: 0 0 80px 0; width: 100%;';
        globalActions.innerHTML = `
            <button id="btn-movimiento-global" class="btn-add" 
                style="background: #087d4e; color: white; border: none; padding: 18px 45px; border-radius: 45px; cursor: pointer; display: flex; align-items: center; gap: 15px; font-weight: bold; font-size: 1.3rem; box-shadow: 0 10px 30px rgba(8,125,78,0.3); transition: all 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275);">
                <i class="fa-solid fa-truck-ramp-box" style="font-size: 1.5rem;"></i> Registrar Movimiento de Inventario
            </button>
        `;
        viewWrapper.appendChild(globalActions);
        targetContainer.appendChild(viewWrapper);

        document.getElementById('btn-movimiento-global').addEventListener('click', openGlobalMovementModal);
        document.getElementById('btn-movimiento-global').addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px) scale(1.03)';
            this.style.boxShadow = '0 12px 30px rgba(8,125,78,0.35)';
        });
        document.getElementById('btn-movimiento-global').addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
            this.style.boxShadow = '0 8px 25px rgba(8,125,78,0.25)';
        });

        document.getElementById('card-instrumentos').addEventListener('click', () => loadManagementView('instrumentos', targetContainer));
        document.getElementById('card-kits').addEventListener('click', () => loadManagementView('kits', targetContainer));
    }

    /**
     * FUNCIÓN: loadManagementView
     * PROPÓSITO: Construye la interfaz de Instrumentación o Kits.
     * DISPARADOR: Se ejecuta al hacer clic en las tarjetas de selección.
     * FLUJO: Carga controles de búsqueda, filtros y dispara fetchData().
     */
    function loadManagementView(type, container) {
        currentView = type;
        const title = type === 'instrumentos' ? 'Gestión de Instrumentos' : 'Gestión de Kits';
        const btnColor = type === 'instrumentos' ? '#36498f' : '#087d4e';
        
        // Resetear filtros al entrar
        currentStatusFilter = 'true';

        const targetContainer = container || document.getElementById('dynamic-view') || document.querySelector('.a2');

        if (!targetContainer) return;

        targetContainer.innerHTML = `
            <div id="view-root-${type}" class="mat-prim-slide-up" style="padding: 20px; animation: matPrimFadeIn 0.3s ease-out; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid var(--border-color); padding-bottom:10px; margin-bottom:20px;">
                    <button class="back-btn" id="btn-back-selection" style="background: none; border: none; font-size: 1.2rem; cursor: pointer; color: var(--text-muted); display: flex; align-items: center; gap: 8px;">
                        <i class="fa-solid fa-arrow-left"></i> Volver al Inicio
                    </button>
                    <h2 style="color: var(--text-main);">${title}</h2>
                </div>

                <div class="controls-bar" style="display: flex; gap: 15px; margin-bottom: 20px; background: var(--bg-secondary); padding: 15px; border-radius: 10px; box-shadow: 0 4px 6px var(--card-shadow); align-items: center; flex-wrap: wrap;">
                    <div class="search-wrapper" style="flex: 2; position: relative; min-width: 250px;">
                        <i class="fa-solid fa-search" style="position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text-muted);"></i>
                        <input type="text" id="search-${type}" placeholder="Buscar ${title}..." 
                            style="width: 100%; padding: 10px 10px 10px 40px; border: 1px solid var(--border-color); border-radius: 20px; outline: none; background: var(--bg-primary); color: var(--text-main);">
                    </div>

                    <div class="status-filters" style="display: flex; background: var(--bg-primary); padding: 5px; border-radius: 25px; gap: 5px; flex: 1; min-width: 250px;">
                        <button onclick="window.toggleStatusFilter('true')" id="filter-btn-hab" 
                            style="flex: 1; padding: 8px 15px; border: none; border-radius: 20px; cursor: pointer; font-size: 0.9rem; font-weight: 600; transition: all 0.3s; background: ${btnColor}; color: white; box-shadow: 0 2px 5px rgba(0,0,0,0.1);">
                            Habilitados
                        </button>
                        <button onclick="window.toggleStatusFilter('false')" id="filter-btn-inhab" 
                            style="flex: 1; padding: 8px 15px; border: none; border-radius: 20px; cursor: pointer; font-size: 0.9rem; font-weight: 600; transition: all 0.3s; background: transparent; color: var(--text-muted);">
                            Inhabilitados
                        </button>
                    </div>

                    <button id="btn-add-${type}" class="btn-add" 
                        style="background: ${btnColor}; color: white; border: none; padding: 10px 20px; border-radius: 20px; cursor: pointer; display: flex; align-items: center; gap: 8px; font-weight: bold; box-shadow: 0 4px 10px rgba(0,0,0,0.1);">
                        <i class="fa-solid fa-plus"></i> Agregar Nuevo
                    </button>
                </div>

                <div class="data-table-container" style="background: var(--bg-secondary); border-radius: 10px; padding: 0; box-shadow: 0 4px 15px var(--card-shadow); overflow: hidden; display: flex; flex-direction: column; max-height: 500px;">
                    <div id="grid-container-${type}">
                        <div style="padding: 20px; text-align: center; color: var(--text-main);">Cargando datos...</div>
                    </div>
                    
                    <div class="stats-footer" style="padding: 15px; text-align: right; color: var(--text-muted); font-size: 0.9rem; border-top: 1px solid var(--border-color); background: var(--bg-secondary);">
                        Total Registros: <span id="total-${type}">0</span>
                    </div>
                </div>
            </div>
        `;

        document.getElementById('btn-back-selection').addEventListener('click', () => window.loadSelectionView(targetContainer));
        document.getElementById(`btn-add-${type}`).addEventListener('click', () => openAddModal(type));
        const searchInput = document.getElementById(`search-${type}`);
        searchInput.addEventListener('input', (e) => filterTable(type, e.target.value));

        fetchData(type);
    }

    let currentColumns = [];
    let localData = [];
    let currentStatusFilter = 'true';

    window.toggleStatusFilter = function(estado) {
        if (currentStatusFilter === estado) return;
        currentStatusFilter = estado;

        // Estilos visuales de los botones
        const btnHab = document.getElementById('filter-btn-hab');
        const btnInhab = document.getElementById('filter-btn-inhab');
        const activeColor = currentView === 'instrumentos' ? '#36498f' : '#087d4e';

        if (estado === 'true') {
            btnHab.style.background = activeColor;
            btnHab.style.color = 'white';
            btnHab.style.boxShadow = '0 2px 5px rgba(0,0,0,0.1)';
            btnInhab.style.background = 'transparent';
            btnInhab.style.color = '#666';
            btnInhab.style.boxShadow = 'none';
        } else {
            btnInhab.style.background = '#dc3545';
            btnInhab.style.color = 'white';
            btnInhab.style.boxShadow = '0 2px 5px rgba(0,0,0,0.1)';
            btnHab.style.background = 'transparent';
            btnHab.style.color = 'var(--text-muted)';
            btnHab.style.boxShadow = 'none';
        }

        // Limpiar búsqueda al cambiar de estado
        const searchInput = document.getElementById(`search-${currentView}`);
        if (searchInput) {
            searchInput.value = '';
        }

        fetchData(currentView);
    };

    /**
     * FUNCIÓN: fetchData (Asíncrona)
     * PROPÓSITO: Trae los datos desde la BD filtrados por estado.
     * DISPARADOR: Carga inicial o cambio en el filtro de estado.
     */
    async function fetchData(type) {
        const container = document.getElementById(`grid-container-${type}`);
        if (!container) return;

        try {
            // Se le añade timestamp (t) para evitar caché del navegador
            const response = await window.ApiService.get(`../php/api_gestion.php?tipo=${type}&estado=${currentStatusFilter}&t=${new Date().getTime()}`);
            if (response.columns) currentColumns = response.columns;
            localData = (response.data || []).reverse();
            renderGrid(type, localData);
        } catch (err) {
            console.error(err);
            container.innerHTML = `<div style="color:red; margin:20px;">Error al cargar datos del servidor</div>`;
        }
    }

    function renderGrid(type, data) {
        const container = document.querySelector('.data-table-container');
        const gridContainer = document.getElementById(`grid-container-${type}`);
        const totalSpan = document.getElementById(`total-${type}`);
        if (totalSpan) totalSpan.textContent = data.length;

        if (container) {
            container.style.maxHeight = 'none';
            container.style.height = 'auto';
            container.style.overflow = 'visible';
        }

        const mainView = document.querySelector('.a2') || document.getElementById('dynamic-view');
        if (mainView) {
            mainView.style.overflowY = 'auto';
            mainView.style.overflowX = 'hidden';
            mainView.style.height = '100vh';
        }

        if (data.length === 0) {
            gridContainer.innerHTML = '<div style="width:100%; text-align:center; color:#666; padding:40px;">No hay registros creados.</div>';
            return;
        }

        let gridHtml = `<div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 20px; padding: 20px; background: var(--bg-primary);">`;

        data.forEach(item => {
            const pk = type === 'instrumentos' ? item.id_instrumento : item.id_kit;
            const isInactive = item.ind_vivo === false || item.ind_vivo === 0 || item.ind_vivo === 'f';
            const imgUrl = item.img_url || (type === 'instrumentos' ? '../../images/instrum.png' : '../../images/kit.png');
            
            // Lógica de color: Rojo si está por debajo o igual al stock mínimo
            const isCritical = item.cant_disp <= (item.stock_min || 0);
            const stockColor = isCritical ? '#dc3545' : (type === 'instrumentos' ? '#36498f' : '#087d4e');
            
            const name = type === 'instrumentos' ? item.nom_instrumento : item.nom_kit;
            const espec = item.especializacion || item.nom_especializacion || 'General';

            gridHtml += `
                <div class="instrumento-card" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 4px 15px var(--card-shadow); overflow: hidden; transition: transform 0.2s, box-shadow 0.2s; cursor: pointer; border: 1px solid var(--border-color); position: relative; ${isInactive ? 'opacity: 0.75; filter: grayscale(0.5);' : ''}" onclick="verDetalle('${type}', ${pk})">
                    ${isInactive ? '<span style="position: absolute; top: 10px; left: 10px; background: #dc3545; color: white; padding: 2px 8px; border-radius: 10px; font-size: 0.7rem; font-weight: bold; z-index: 10;">INACTIVO</span>' : ''}
                    <div style="height: 160px; overflow: hidden; position: relative;">
                        <img src="${imgUrl}" alt="${name}" style="width: 100%; height: 100%; object-fit: cover;">
                        <div style="position: absolute; top: 10px; right: 10px; background: ${isCritical ? '#fff5f5' : 'rgba(255,255,255,0.9)'}; padding: 4px 10px; border-radius: 20px; color: ${stockColor}; font-weight: bold; font-size: 0.8rem; box-shadow: 0 2px 5px rgba(0,0,0,0.1); border: ${isCritical ? '1px solid #ffcccc' : 'none'};">
                            <i class="${isCritical ? 'fa-solid fa-triangle-exclamation' : 'fa-solid fa-check-circle'}" style="margin-right: 4px;"></i> ${item.cant_disp} Disp.
                        </div>
                    </div>
                    <div style="padding: 15px;">
                        <h3 style="margin: 0 0 5px 0; color: var(--text-main); font-size: 1.1rem; overflow: hidden; white-space: nowrap; text-overflow: ellipsis;">${name}</h3>
                        <p style="margin: 0; color: var(--text-muted); font-size: 0.9rem;">${espec}</p>
                        <p style="margin: 5px 0 0 0; color: var(--text-muted); font-size: 0.8rem; opacity: 0.8;">Ref: #${pk}</p>
                        
                        <div style="margin-top: 15px; display: flex; gap: 10px; justify-content: flex-end;">
                            ${!isInactive ? `
                                <button onclick="event.stopPropagation(); openMovementModal('${type}', ${pk})" style="background:none; border:none; color: #087d4e; cursor: pointer; padding: 5px;" title="Registrar Movimiento">
                                    <i class="fa-solid fa-truck-ramp-box"></i>
                                </button>
                                <button onclick="event.stopPropagation(); editLocal('${type}', ${pk})" style="background:none; border:none; color: #36498f; cursor: pointer; padding: 5px;" title="Editar">
                                    <i class="fa-solid fa-pencil"></i>
                                </button>
                                <button onclick="event.stopPropagation(); deleteLocal('${type}', ${pk})" style="background: #dc3545; border: 1px solid #000; color: white; cursor: pointer; width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s;" title="Eliminar">
                                    <i class="fa-solid fa-trash-can" style="font-size: 0.9rem;"></i>
                                </button>
                            ` : `
                                <button onclick="event.stopPropagation(); restoreItem('${type}', ${pk})" style="background: #28a745; border: 1px solid #000; color: white; cursor: pointer; width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s;" title="Restaurar Registro">
                                    <i class="fa-solid fa-trash-can-arrow-up" style="font-size: 1rem;"></i>
                                </button>
                            `}
                        </div>
                    </div>
                </div>
            `;
        });

        gridHtml += `</div>`;
        gridContainer.innerHTML = gridHtml;
    }

    window.verDetalle = async function (type, id) {
        const pkCol = type === 'kits' ? 'id_kit' : 'id_instrumento';
        const item = localData.find(i => i[pkCol] == id);
        if (!item) return;

        const modalGestion = document.getElementById('modalGestion');
        const modalTitle = document.getElementById('modalGestionTitle');
        const modalBody = document.getElementById('modalGestionBody');

        const modalContent = modalGestion.querySelector('.modal-content');
        if (modalContent) modalContent.classList.remove('modal-large');

        const globalFooter = modalGestion.querySelector('.modal-footer');
        if (globalFooter) globalFooter.style.display = 'none';

        const btnNuevo = document.getElementById('btnNuevoRegistro');
        if (btnNuevo) btnNuevo.style.display = 'none';

        modalGestion.style.display = 'block';
        modalTitle.textContent = 'Detalle de ' + (type === 'kits' ? 'Kit' : 'Instrumento');

        const img = item.img_url || (type === 'kits' ? '../../images/kit.png' : '../../images/instrum.png');
        const nombre = type === 'kits' ? item.nom_kit : item.nom_instrumento;
        const espec = item.especializacion || item.nom_especializacion || 'General';
        const cant = item.cant_disp;
        const min = item.stock_min || 0;
        const max = item.stock_max || 0;
        const ref = type === 'kits' ? item.id_kit : item.id_instrumento;

        const isInactive = item.ind_vivo === false || item.ind_vivo === 0 || item.ind_vivo === 'f';

        let extraInfo = '';
        if (type === 'instrumentos') {
            extraInfo = `
                <div style="margin-bottom:10px;"><strong>Línea:</strong> ${item.nom_tipo_mat || 'N/A'}</div>
                <div style="margin-bottom:10px;"><strong>Lote:</strong> ${item.lote || 'N/A'}</div>
            `;
        }

        let kitContentHtml = '';
        if (type === 'kits') {
            try {
                const response = await window.ApiService.fetchApiGestion('read', 'kit_instruments', null, id);
                if (response.data && response.data.length > 0) {
                    kitContentHtml = `<div style="margin-top:20px; padding-top:15px; border-top:1px solid #ddd;">
                        <h4 style="margin-top:0; color:#36498f; font-size:1rem;">Contenido del Kit:</h4>
                        <ul style="padding-left:20px; margin:10px 0; color:#555;">
                            ${response.data.map(inst => `<li>${inst.nom_instrumento} <span style="font-size:0.8rem; color:#888;">(x${inst.cantidad || 1})</span></li>`).join('')}
                        </ul>
                    </div>`;
                } else {
                    kitContentHtml = `<div style="margin-top:20px; padding-top:15px; border-top:1px solid #ddd; color:#888; font-style:italic;">Este kit no tiene instrumentos asignados.</div>`;
                }
            } catch (e) {
                console.error("Error cargando contenido del kit", e);
            }
        }

        modalBody.innerHTML = `
            <div style="display:flex; flex-direction:column; gap:20px; padding:20px;">
                <div style="text-align:center;">
                    <img src="${img}" style="max-width:100%; max-height:250px; border-radius:10px; box-shadow:0 4px 15px rgba(0,0,0,0.1);">
                </div>
                
                <div style="background: var(--bg-primary); padding: 20px; border-radius: 10px; border: 1px solid var(--border-color);">
                    <h2 style="color: var(--text-main); margin-top: 0;">${nombre}</h2>
                    <p style="color: var(--text-muted); font-size: 1.1rem;">${espec}</p>
                    
                    <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-top:20px; border-top:1px solid var(--border-color); padding-top:15px;">
                        <div><span style="display:block; font-size:0.85rem; color: var(--text-muted);">Referencia</span><span style="font-weight:bold; color: var(--text-main);">#${ref}</span></div>
                        <div><span style="display:block; font-size:0.85rem; color: var(--text-muted);">Cantidad Actual</span><span style="font-weight:bold; color:${cant <= min ? '#dc3545' : '#087d4e'}">${cant} Unidades</span></div>
                        <div><span style="display:block; font-size:0.85rem; color: var(--text-muted);">Stock Mínimo</span><span style="font-weight:bold; color: var(--text-main);">${min}</span></div>
                        <div><span style="display:block; font-size:0.85rem; color: var(--text-muted);">Stock Máximo</span><span style="font-weight:bold; color: var(--text-main);">${max}</span></div>
                    </div>
                    ${type === 'instrumentos' ? `<div style="margin-top:20px; padding-top:15px; border-top:1px solid var(--border-color);">${extraInfo}</div>` : ''}
                    ${kitContentHtml}
                </div>
                <div style="display:flex; justify-content:flex-end; gap:15px; margin-top:10px;">
                    <button class="btn-modal btn-secondary" onclick="document.getElementById('modalGestion').style.display='none'">Cerrar</button>
                    ${!isInactive ? `
                        <button class="btn-modal btn-primary" style="background:#087d4e;" onclick="openMovementModal('${type}', ${ref})">
                            <i class="fa-solid fa-truck-ramp-box"></i> Registrar Movimiento
                        </button>
                        <button class="btn-modal btn-primary" onclick="editLocal('${type}', ${ref}, 'detalle')">
                            <i class="fa-solid fa-pencil"></i> Editar
                        </button>
                    ` : `
                        <div style="background:#fff5f5; color:#dc3545; padding:10px 15px; border-radius:8px; border:1px solid #ffcccc; font-weight:bold; font-size:0.9rem;">
                            <i class="fa-solid fa-ban"></i> Registro Inactivo
                        </div>
                    `}
                </div>
            </div>
        `;
    };

    function filterTable(type, query) {
        const filtered = localData.filter(item => {
            return currentColumns.some(col => {
                const val = String(item[col.key] || '').toLowerCase();
                return val.includes(query.toLowerCase());
            });
        });
        renderGrid(type, filtered);
    }

    window.editLocal = function (type, id, originType = 'local') {
        const pk = type === 'instrumentos' ? 'id_instrumento' : 'id_kit';
        const row = localData.find(item => item[pk] == id);

        if (row && typeof window.mostrarFormulario === 'function') {
            const modal = document.getElementById('modalGestion');
            if (modal) {
                modal.style.display = 'block';
                window.mostrarFormulario(type, 'update', row, originType);
            }
        } else {
            console.error("No se encontró el registro o logica.js no está cargado");
        }
    };

    window.refreshInstrumentalTable = function (type) {
        if (currentView === type || !currentView) fetchData(type);
    };

    /**
     * FUNCIÓN: deleteLocal
     * PROPÓSITO: Primera línea de defensa para eliminar un registro.
     * DISPARADOR: Se llama desde el ícono de basura en la tabla de Instrumentos/Kits.
     * LLAMADO EN: renderGrid() -> Botón .btn-delete
     */
    window.deleteLocal = async function (type, id) {
        if (typeof window.UIComponents !== 'undefined') {
            // UIComponents.showConfirm -> Muestra el modal de confirmación SweetAlert2
            UIComponents.showConfirm('¿Eliminar registro?', 'Esta acción no se puede deshacer.', () => performDelete(type, id));
        } else if (confirm("¿Estás seguro de eliminar este registro?")) {
            performDelete(type, id);
        }
    };

    /**
     * FUNCIÓN: performDelete (Asíncrona)
     * PROPÓSITO: Se comunica con el backend para ejecutar el borrado lógico.
     * DISPARADOR: Se ejecuta tras la confirmación del usuario en deleteLocal().
     * LLAMADO A: ApiService.fetchApiGestion -> api_gestion.php
     */
    async function performDelete(type, id) {
        if (window.UIComponents) UIComponents.toggleLoading(true); // Bloquea la UI para evitar clics dobles
        try {
            // .fetchApiGestion('delete', ...) -> Envía la petición DELETE al servidor
            const response = await window.ApiService.fetchApiGestion('delete', type, null, id);
            if (window.UIComponents) UIComponents.toggleLoading(false);

            if (response.success) {
                // Tras el éxito, recargar la página para actualizar métricas globales
                if (window.UIComponents) UIComponents.showSuccess('Eliminado correctamente', () => window.location.reload());
                else { alert('Eliminado correctamente'); window.location.reload(); }
            } else {
                // Muestra error específico del backend (ej: "Tiene dependencias")
                if (window.UIComponents) UIComponents.showError('Error', response.error || response.message);
                else alert('Error: ' + (response.error || response.message));
            }
        } catch (err) {
            if (window.UIComponents) window.UIComponents.toggleLoading(false);
            console.error(err);
            // Si el servidor falla (Error 500), capturamos el mensaje real aquí
            const errorMsg = err.message || 'No se pudo conectar al servidor';
            if (window.UIComponents) window.UIComponents.showError('Error en la operación', errorMsg);
            else alert('Error: ' + errorMsg);
        }
    }

    window.openAddModal = function (type) {
        if (typeof window.mostrarFormulario === 'function') {
            const modal = document.getElementById('modalGestion');
            const modalTitle = document.getElementById('modalGestionTitle');
            const btnNuevo = document.getElementById('btnNuevoRegistro');

            if (modal) {
                if (modalTitle) modalTitle.textContent = 'Gestión de ' + type.charAt(0).toUpperCase() + type.slice(1);
                if (btnNuevo) btnNuevo.style.display = 'none';

                modal.style.display = 'block';
                window.mostrarFormulario(type, 'create', null, 'local');
            }
        } else {
            console.error("logica.js no cargado");
        }
    };

    window.openMovementModal = function (type, id) {
        const pkCol = type === 'kits' ? 'id_kit' : 'id_instrumento';
        const item = localData.find(i => i[pkCol] == id);
        if (!item) return;

        // --- 1. SEPARACIÓN DE FUNCIONALIDADES: Usar modal exclusivo ---
        const modal = document.getElementById('modalMovimientoInstrumental');
        const modalTitle = document.getElementById('modalMovimientoTitle');
        const modalBody = document.getElementById('modalMovimientoBody');

        if (!modal) {
            console.error("Modal de movimientos no encontrado. Verifique footer.php");
            return;
        }

        modal.style.display = 'block';
        modalTitle.textContent = (type === 'kits' ? 'Kit: ' : 'Instrumento: ') + (type === 'kits' ? item.nom_kit : item.nom_instrumento);

        // --- 2. RECREACIÓN DE LA OPCIÓN DE REGISTRAR MOVIMIENTO ---
        modalBody.innerHTML = `
            <form id="form-movimiento" style="display: flex; flex-direction: column; gap: 15px;">
                <div style="background: var(--bg-primary); padding: 15px; border-radius: 10px; margin-bottom: 5px; border-left: 5px solid #36498f;">
                    <div style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 5px;">Estado de Inventario</div>
                    <div style="font-size: 1.1rem; font-weight: 700; color: var(--text-main);">${item.cant_disp} <span style="font-weight: 400; font-size: 0.9rem;">unidades disponibles</span></div>
                </div>
                
                <div class="form-group">
                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Tipo de Movimiento</label>
                    <select id="mov-tipo" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);" required>
                        <option value="1">📦 Entrada (Producción/Fabricación)</option>
                        <option value="3">⚙️ Ajuste de Inventario (+)</option>
                        <option value="4">⚠️ Baja / Daño / Pérdida (-)</option>
                    </select>
                </div>


                <div class="form-group">
                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Cantidad</label>
                    <input type="number" id="mov-cantidad" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);" min="1" step="1" required placeholder="Ej: 5">
                </div>

                <div class="form-group">
                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Observaciones / Motivo</label>
                    <textarea id="mov-obs" class="form-user-input" style="width: 100%; border: 1px solid var(--border-color); border-radius: 8px; padding: 12px; height: 90px; resize: none; font-family: inherit; background: var(--bg-primary); color: var(--text-main);" placeholder="Ej: Venta directa a consultorio dental..."></textarea>
                </div>

                <div style="display: flex; justify-content: flex-end; gap: 12px; margin-top: 10px; padding-top: 20px; border-top: 1px solid var(--border-color);">
                    <button type="button" class="btn-modal btn-secondary" style="border: 1px solid var(--border-color); background: var(--bg-primary); color: var(--text-muted);" onclick="document.getElementById('modalMovimientoInstrumental').style.display='none'">Cancelar</button>
                    <button type="submit" class="btn-modal btn-primary" style="background: #36498f; font-weight: bold;">
                        <i class="fa-solid fa-cloud-arrow-up"></i> Guardar Movimiento
                    </button>
                </div>
            </form>
        `;



        document.getElementById('form-movimiento').onsubmit = async (e) => {
            e.preventDefault();
            const data = {
                tipo_item: type === 'instrumentos' ? 1 : 2,
                id_item: id,
                tipo_movimiento: document.getElementById('mov-tipo').value,
                cantidad: document.getElementById('mov-cantidad').value,
                observaciones: document.getElementById('mov-obs').value.trim() || 'N/A'
            };

            if (window.UIComponents) UIComponents.toggleLoading(true);
            try {
                const response = await window.ApiService.fetchApiGestion('create', 'kardex_producto', data, null, null, 'ApiHistorialController');
                if (window.UIComponents) UIComponents.toggleLoading(false);

                if (response.success || response.result) {
                    if (window.refreshSidebarStats) window.refreshSidebarStats();
                    modal.style.display = 'none';
                    if (window.UIComponents) {
                        UIComponents.showSuccess('Movimiento registrado con éxito', () => window.location.reload());
                    } else {
                        alert('Movimiento registrado');
                        window.location.reload();
                    }
                } else {
                    const errorMsg = response.error || response.message || 'Error desconocido';
                    if (window.UIComponents) UIComponents.showError('No se pudo registrar', errorMsg);
                }
            } catch (err) {
                if (window.UIComponents) UIComponents.toggleLoading(false);
                console.error(err);
                if (window.UIComponents) UIComponents.showError('Error al registrar', err.message || 'No se pudo comunicar con el servidor');
            }
        };
    };

    window.openGlobalMovementModal = async function() {
        const modal = document.getElementById('modalMovimientoGlobal');
        const modalBody = document.getElementById('modalGlobalMovBody');
        const modalTitle = document.getElementById('modalGlobalMovTitle');
        if (!modal || !modalBody) return;

        // Restaurar título correcto (evita contaminación desde materia prima)
        if (modalTitle) modalTitle.innerHTML = '<i class="fa-solid fa-truck-ramp-box"></i> Registro General de Movimientos';

        modal.style.display = 'block';
        modalBody.innerHTML = '<div style="text-align:center; padding:20px; color: var(--text-muted);"><i class="fas fa-spinner fa-spin"></i> Cargando opciones...</div>';

        // Estructura básica del formulario (Limpio, sin autoincrementales)
        modalBody.innerHTML = `
            <form id="form-movimiento-global" style="display: flex; flex-direction: column; gap: 20px;">
                <div class="form-group">
                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Tipo de Movimiento</label>
                    <select id="glob-mov-tipo" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);" required>
                        <option value="">-- Seleccione Tipo --</option>
                        <option value="2">🤝 Salida por Venta / Comercial (-)</option>
                        <option value="5">🔄 Entrada por Devolución de Cliente (+)</option>
                        <option value="1">📦 Ingreso de Producción a Inventario (+)</option>
                        <option value="4">⚠️ Salida de Inventario por Daño / Pérdida (-)</option>
                    </select>
                </div>

                <div id="container-seleccion-item" style="display: none; animation: fadeIn 0.3s ease;"></div>

                <div id="container-info-descuento" style="display:none; transition: all 0.3s ease;">
                    <div style="background: rgba(255, 248, 225, 0.1); border: 1px solid rgba(255, 236, 179, 0.3); padding: 12px; border-radius: 8px; margin-bottom: 15px; display: flex; align-items: center; gap: 10px; color: #ffecb3; font-size: 0.95rem;">
                        <i class="fa-solid fa-circle-info"></i>
                        <span>El sistema aplicará un descuento automático del <strong id="glob-mov-desc-pocentaje">0</strong>% según los parámetros actuales.</span>
                    </div>
                </div>

                <div id="container-cliente-venta" style="display:none; margin-bottom:15px; background: var(--bg-secondary); padding: 15px; border-radius: 10px; border: 1px solid var(--border-color);">
                    <div class="form-group" style="margin-bottom:10px;">
                        <label style="display: block; margin-bottom: 8px; font-weight: 700; color: var(--welcome-blue);"><i class="fa-solid fa-user-tag"></i> Seleccionar Cliente</label>
                        <select id="glob-mov-cliente" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);">
                            <option value="">-- Buscando clientes... --</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label style="display: block; margin-bottom: 8px; font-weight: 700; color: var(--welcome-blue);"><i class="fa-solid fa-credit-card"></i> Forma de Pago</label>
                        <select id="glob-mov-pago" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);">
                            <option value="1">💵 Efectivo</option>
                            <option value="2">🏦 Transferencia Bancaria</option>
                            <option value="3">💳 Tarjeta Débito/Crédito</option>
                        </select>
                    </div>
                </div>

                <div id="container-detalles-mov" style="display: none; border-top: 1px solid var(--border-color); padding-top: 20px; animation: fadeIn 0.3s ease;">
                    <div class="form-group" style="margin-bottom:18px;">
                        <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Cantidad</label>
                        <input type="number" id="glob-mov-cantidad" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);" min="1" step="1" required placeholder="Ingrese cantidad manual">
                    </div>

                    <div class="form-group">
                        <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Observaciones / Motivo</label>
                        <textarea id="glob-mov-obs" class="form-user-input" style="width: 100%; border: 1px solid var(--border-color); border-radius: 8px; padding: 12px; height: 90px; resize: none; font-family: inherit; background: var(--bg-primary); color: var(--text-main);" placeholder="Escriba aquí los detalles del movimiento..."></textarea>
                    </div>

                    <div style="display: flex; justify-content: flex-end; gap: 12px; margin-top: 20px; padding-top: 20px; border-top: 1px solid var(--border-color);">
                        <button type="button" class="btn-modal" style="border: 1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main); padding: 10px 25px; border-radius: 10px; cursor: pointer; font-weight: 700; transition: all 0.2s;" onclick="document.getElementById('modalMovimientoGlobal').style.display='none'">Cancelar</button>
                        <button type="submit" class="btn-modal" style="background: #087d4e; color: white; border: none; font-weight: 800; padding: 12px 30px; border-radius: 10px; cursor: pointer; display: flex; align-items: center; gap: 10px; box-shadow: 0 4px 12px rgba(8, 125, 78, 0.2); transition: transform 0.2s;">
                            <i class="fa-solid fa-cloud-arrow-up"></i> Registrar Movimiento
                        </button>
                    </div>
                </div>
            </form>
        `;

        const tipoSelect = document.getElementById('glob-mov-tipo');
        const containerItem = document.getElementById('container-seleccion-item');
        const containerDetalles = document.getElementById('container-detalles-mov');

        tipoSelect.addEventListener('change', async () => {
             const val = tipoSelect.value;
             
             // 1. Resetear estados comunes
             const obsField = document.getElementById('glob-mov-obs');
             if (obsField) obsField.value = '';
             
             // Por defecto quitamos 'required' de campos que podrían estar ocultos
             const cantInput = document.getElementById('glob-mov-cantidad');
             if (cantInput) cantInput.removeAttribute('required');
             
             containerItem.style.display = 'none';
             containerDetalles.style.display = 'none';
             
             const containerCliente = document.getElementById('container-cliente-venta');

             if (containerCliente) {
                 containerCliente.style.display = (val == '2') ? 'block' : 'none';
                 const containerInfoDesc = document.getElementById('container-info-descuento');
                 if (containerInfoDesc) containerInfoDesc.style.display = (val == '2') ? 'block' : 'none';

                 if (val == '2') {
                     try {
                         const statsResp = await window.ApiService.fetchApiGestion('read', 'stats');
                         if (statsResp && statsResp.data && statsResp.data.val_pordesc !== undefined) {
                             const elPorc = document.getElementById('glob-mov-desc-pocentaje');
                             if (elPorc) elPorc.textContent = statsResp.data.val_pordesc;
                         }

                         const resp = await window.ApiService.fetchApiGestion('read', 'clientes');
                         if (resp.data) {
                             let opts = '<option value="">-- Seleccione Cliente (Opcional: Venta General) --</option>';
                             opts += resp.data.map(c => `<option value="${c.id}">${c.nombre_completo} [${c.num_documento}]</option>`).join('');
                             document.getElementById('glob-mov-cliente').innerHTML = opts;
                         }
                     } catch(e) { console.error("Error cargando datos de venta", e); }
                 }
             }

             if (!val) return;

             containerItem.innerHTML = '<div style="padding:15px; color: var(--text-muted); text-align:center;"><i class="fas fa-spinner fa-spin"></i> Cargando...</div>';
             containerItem.style.display = 'block';

             if (val == '2') {
                 // VENTAS MÚLTIPLES
                 try {
                     const response = await window.ApiService.fetchApiGestion('read', 'productos');
                     if (response.data) {
                         const catalogo = response.data;
                         let rows = [{ id: '', cant: 1 }];

                         const renderRows = () => {
                             let html = `
                                <div style="background: var(--bg-primary); border: 1px solid var(--border-color); border-radius: 12px; padding: 15px;">
                                    <label style="display: block; margin-bottom: 12px; font-weight: 700; color: var(--text-main);"><i class="fa-solid fa-list-ul"></i> Items de la Venta</label>
                                    <div id="venta-rows-container" style="display:flex; flex-direction:column; gap:10px;"></div>
                                    <button type="button" id="btn-add-venta-row" class="btn-secondary" style="margin-top:10px; width:100%; height:40px; border:2px dashed var(--border-color); background: var(--bg-secondary); border-radius:8px; cursor:pointer; color: var(--text-muted); font-weight:600;">
                                        <i class="fa-solid fa-plus"></i> Agregar Otro Item (Máx 10)
                                    </button>
                                </div>
                             `;
                             containerItem.innerHTML = html;

                             const rowsDiv = document.getElementById('venta-rows-container');
                             rows.forEach((row, idx) => {
                                 const rowDiv = document.createElement('div');
                                 rowDiv.style = "display:grid; grid-template-columns: 1fr 110px 45px; gap:10px; align-items: center; background: var(--bg-secondary); padding: 10px; border-radius: 8px; border: 1px solid var(--border-color); box-shadow: 0 2px 4px var(--card-shadow);";
                                 rowDiv.innerHTML = `
                                    <select class="form-user-input row-prod-select" style="width:100%; height:45px; border-radius:8px; border: 1px solid var(--border-color); background: var(--bg-primary); padding: 0 10px; color: var(--text-main);">
                                        <option value="">-- Seleccione Producto --</option>
                                        ${catalogo.map(p => `<option value="${p.id}" ${row.id == p.id ? 'selected' : ''}>${p.nombre} ($${new Intl.NumberFormat().format(p.precio || 0)})</option>`).join('')}
                                    </select>
                                    <input type="number" class="form-user-input row-prod-cant" value="${row.cant}" min="1" style="height:45px; border-radius:8px; padding:0 12px; border: 1px solid var(--border-color); width: 100%; background: var(--bg-primary); color: var(--text-main);">
                                    <button type="button" class="btn-remove-row" style="background: #dc3545; border: 1px solid #000; color: white; height: 45px; border-radius: 8px; cursor: pointer; width: 100%; display: flex; align-items: center; justify-content: center; transition: all 0.2s; box-shadow: 0 2px 5px rgba(0,0,0,0.2);" data-idx="${idx}" title="Eliminar fila">
                                        <i class="fa-solid fa-trash-can"></i>
                                    </button>
                                 `;
                                 rowsDiv.appendChild(rowDiv);
                             });

                             document.getElementById('btn-add-venta-row').onclick = () => {
                                 if (rows.length < 10) {
                                     updateRowsData();
                                     rows.push({ id: '', cant: 1 });
                                     renderRows();
                                 }
                             };

                             rowsDiv.querySelectorAll('.btn-remove-row').forEach(btn => {
                                 btn.onclick = () => {
                                     if (rows.length > 1) {
                                         updateRowsData();
                                         rows.splice(btn.dataset.idx, 1);
                                         renderRows();
                                     }
                                 };
                             });
                         };

                         const updateRowsData = () => {
                             const selects = containerItem.querySelectorAll('.row-prod-select');
                             const cants = containerItem.querySelectorAll('.row-prod-cant');
                             rows = Array.from(selects).map((s, i) => ({ id: s.value, cant: cants[i].value }));
                         };

                         renderRows();
                         containerDetalles.style.display = 'block';
                         // Quitar required del campo individual ya que usamos filas múltiples
                         document.getElementById('glob-mov-cantidad').removeAttribute('required');
                         document.getElementById('glob-mov-cantidad').closest('.form-group').style.display = 'none'; 
                     }
                 } catch (e) { console.error(e); }

             } else if (val == '5') {
                 // DEVOLUCIÓN POR FACTURA
                 containerItem.innerHTML = `
                    <div style="background: var(--bg-secondary); padding: 15px; border-radius: 12px; border: 1px solid var(--border-color);">
                        <label style="display: block; margin-bottom: 12px; font-weight: 700; color: var(--text-main);"><i class="fa-solid fa-magnifying-glass"></i> Buscar Factura / Venta</label>
                        <div style="display: grid; grid-template-columns: repeat(3, 1fr) 50px; gap: 8px; margin-bottom: 15px;">
                            <select id="dev-busc-mes" class="form-user-input" style="height:45px; border-radius:8px; width: 100%; border: 1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                                <option value="0">Mes (Todos)</option>
                                <option value="1">Enero</option><option value="2">Febrero</option><option value="3">Marzo</option>
                                <option value="4">Abril</option><option value="5">Mayo</option><option value="6">Junio</option>
                                <option value="7">Julio</option><option value="8">Agosto</option><option value="9">Septiembre</option>
                                <option value="10">Octubre</option><option value="11">Noviembre</option><option value="12">Diciembre</option>
                            </select>
                            <select id="dev-busc-anio" class="form-user-input" style="height:45px; border-radius:8px; width: 100%; border: 1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                                ${[2024, 2025, 2026].map(y => `<option value="${y}" ${y == new Date().getFullYear() ? 'selected' : ''}>${y}</option>`).join('')}
                            </select>
                            <input type="text" id="dev-busc-q" placeholder="Cliente o ID..." class="form-user-input" style="height:45px; border-radius:8px; padding:0 10px; width: 100%; border: 1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                            <button type="button" id="btn-buscar-fact" style="background:#36498f; color:white; border:none; border-radius:8px; cursor:pointer; height:45px;">
                                <i class="fa-solid fa-search"></i>
                            </button>
                        </div>
                        <div id="results-facturas" style="max-height: 200px; overflow-y: auto; background: var(--bg-primary); border-radius: 8px; border: 1px solid var(--border-color);">
                            <div style="padding: 10px; color: var(--text-muted); text-align: center; font-size: 0.9rem;">Realice una búsqueda para ver ventas recientes</div>
                        </div>
                        <div id="items-factura-container" style="display:none; margin-top: 15px; padding-top: 15px; border-top: 2px dashed var(--border-color);"></div>
                        <div id="dev-tip-box" style="display:none; margin-top:10px; font-size:0.85rem; color: var(--text-muted); background: rgba(255, 251, 230, 0.1); padding:8px 12px; border-radius:8px; border:1px solid rgba(255, 229, 143, 0.3);">
                            💡 <strong>Tip:</strong> Marque la casilla (check) a la izquierda de cada producto para incluirlo en la devolución.
                        </div>
                    </div>
                 `;

                 const btnBuscar = document.getElementById('btn-buscar-fact');
                 btnBuscar.onclick = async () => {
                     const mes = document.getElementById('dev-busc-mes').value;
                     const anio = document.getElementById('dev-busc-anio').value;
                     const q = document.getElementById('dev-busc-q').value;
                     const resDiv = document.getElementById('results-facturas');
                     resDiv.innerHTML = '<div style="padding:20px; text-align:center;"><i class="fas fa-spinner fa-spin"></i></div>';
                     
                     try {
                         const queryParams = `&mes=${mes}&anio=${anio}&q=${q}`;
                         const resp = await window.ApiService.fetchApiGestion('read', 'buscar_facturas_devolucion' + queryParams);
                         if (resp.data && resp.data.length > 0) {
                             resDiv.innerHTML = resp.data.map(f => `
                                 <div class="fact-row-item" data-id="${f.id_factura}" style="padding: 10px; border-bottom: 1px solid var(--border-color); cursor: pointer; transition: background 0.2s;">
                                    <div style="display: flex; justify-content: space-between; font-weight: 600;">
                                        <span style="color: var(--text-main);">Factura #${f.id_factura}</span>
                                        <span style="color:#087d4e;">$${new Intl.NumberFormat().format(f.val_tot_fact)}</span>
                                    </div>
                                    <div style="font-size: 0.85rem; color: var(--text-muted);">
                                        Cliente: ${f.cliente_nombre} | Fecha: ${f.fecha_venta.split(' ')[0]}
                                    </div>
                                </div>
                             `).join('');

                             resDiv.querySelectorAll('.fact-row-item').forEach(row => {
                                 row.onclick = () => loadFacturaItems(row.dataset.id, row);
                             });
                         } else {
                             resDiv.innerHTML = '<div style="padding:20px; text-align:center; color:#999;">No se encontraron facturas</div>';
                         }
                     } catch (e) { console.error(e); }
                 };

                 const loadFacturaItems = async (id, rowEl) => {
                     document.querySelectorAll('.fact-row-item').forEach(r => r.style.background = 'transparent');
                     rowEl.style.background = 'rgba(54, 73, 143, 0.1)';
                     
                     const itemsDiv = document.getElementById('items-factura-container');
                     itemsDiv.innerHTML = '<div style="padding:15px; text-align:center;"><i class="fas fa-spinner fa-spin"></i> Cargando items...</div>';
                     itemsDiv.style.display = 'block';

                     try {
                         const resp = await window.ApiService.fetchApiGestion('read', 'detalle_factura', null, id);
                         if (resp && resp.data) {
                             itemsDiv.innerHTML = `
                                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
                                    <span style="font-weight:700; color: var(--text-main); font-size: 0.95rem;">Productos de Factura #${id}</span>
                                    <button type="button" id="btn-sel-all-dev" style="font-size:0.75rem; padding:6px 10px; border-radius:6px; border:1px solid #36498f; color:#36498f; background:transparent; cursor:pointer; font-weight:600;">Seleccionar Todo</button>
                                </div>
                                <div id="dev-item-rows-list" style="display:flex; flex-direction:column; gap:10px;">
                                    ${resp.data.map(i => `
                                         <div class="dev-prod-row" data-id-prod="${i.id_producto}" data-cant-facturada="${i.cantidad}" style="display:grid; grid-template-columns: 35px 1fr 130px; gap:10px; background: var(--bg-secondary); padding: 10px; border-radius:8px; border:1px solid var(--border-color); align-items: center; box-shadow: 0 2px 4px var(--card-shadow);">
                                            <input type="checkbox" class="chk-dev-item" checked style="width:20px; height:20px; cursor:pointer;">
                                            <div style="font-size:0.9rem;">
                                                <div style="font-weight:700; color: var(--text-main);">${i.nombre_producto}</div>
                                                <div style="color: var(--text-muted); font-size: 0.8rem;">Facturado: ${i.cantidad} unidades</div>
                                            </div>
                                            <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-end;">
                                                <div style="font-size:0.75rem; font-weight:700; color:#ef4444; text-transform:uppercase;">Dañado / Descarte</div>
                                                <div style="display:flex; align-items:center; gap:5px;">
                                                    <label style="font-size:0.65rem; color: var(--text-muted); margin:0; text-transform: uppercase; font-weight:700;">Cant. a Devolver:</label>
                                                    <input type="text" class="inp-dev-cant" value="${i.cantidad}" 
                                                           oninput="this.value = this.value.replace(/[^0-9]/g, ''); if(this.value.startsWith('0')) this.value = this.value.replace(/^0+/, ''); if(parseInt(this.value) > ${i.cantidad}) this.value = ${i.cantidad};" 
                                                           onblur="if(this.value === '' || parseInt(this.value) < 1) this.value = 1;"
                                                           style="width:45px; height:28px; border-radius:6px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main); text-align:center; font-size:0.85rem; font-weight:bold;">
                                                </div>
                                            </div>
                                        </div>
                                    `).join('')}
                                </div>
                                <input type="hidden" id="dev-fact-id-selected" value="${id}">
                             `;
                             
                             const tipBox = document.getElementById('dev-tip-box');
                             if (tipBox) tipBox.style.display = 'block';

                             document.getElementById('btn-sel-all-dev').onclick = () => {
                                 const chks = itemsDiv.querySelectorAll('.chk-dev-item');
                                 const allChecked = Array.from(chks).every(c => c.checked);
                                 chks.forEach(c => c.checked = !allChecked);
                             };

                             containerDetalles.style.display = 'block';
                             document.getElementById('glob-mov-cantidad').removeAttribute('required');
                             document.getElementById('glob-mov-cantidad').closest('.form-group').style.display = 'none';
                         }
                     } catch(e) { console.error(e); }
                 };

             } else if (val == '1' || val == '4') {
                 // REGLA 2: Producción o Daño -> Selector Instrumento/Kit -> Selector Específico
                 containerItem.innerHTML = `
                    <div style="background: var(--bg-secondary); padding: 15px; border-radius: 10px; border: 1px solid var(--border-color);">
                        <div class="form-group" style="margin-bottom:15px;">
                            <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">¿Qué tipo de registro desea realizar?</label>
                            <select id="glob-mov-subtipo" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);" required>
                                <option value="">-- Seleccione Categoría --</option>
                                <option value="1">🩺 Instrumento Individual</option>
                                <option value="2">🧰 Kit de Especialidad</option>
                            </select>
                        </div>
                        <div id="container-specific-item" style="display:none; animation: fadeIn 0.3s ease;"></div>
                    </div>
                 `;

                 const subTipoSelect = document.getElementById('glob-mov-subtipo');
                 const specificContainer = document.getElementById('container-specific-item');

                 subTipoSelect.addEventListener('change', async () => {
                     const subVal = subTipoSelect.value;
                     specificContainer.style.display = 'none';
                     containerDetalles.style.display = 'none';
                     if (!subVal) return;

                     specificContainer.innerHTML = '<div style="padding:10px; color:#666; text-align:center;"><i class="fas fa-spinner fa-spin"></i> Cargando items...</div>';
                     specificContainer.style.display = 'block';

                     const apiType = subVal == '1' ? 'instrumentos' : 'kits';
                     try {
                         const resp = await window.ApiService.fetchApiGestion('read', apiType);
                         if (resp.data) {
                             const pk = subVal == '1' ? 'id_instrumento' : 'id_kit';
                             const nameCol = subVal == '1' ? 'nom_instrumento' : 'nom_kit';
                             let options = resp.data.map(i => `<option value="${i[pk]}">${i[nameCol]} (Stock: ${i.cant_disp})</option>`).join('');
                             
                             specificContainer.innerHTML = `
                                <div class="form-group">
                                    <label style="display: block; margin-bottom: 8px; font-weight: 600; color: var(--text-main);">Seleccionar ${subVal == '1' ? 'Instrumento' : 'Kit'} Específico</label>
                                    <select id="glob-mov-target" class="form-user-input" style="width: 100%; height: 45px; border: 1px solid var(--border-color); border-radius: 8px; padding: 0 15px; background: var(--bg-primary); color: var(--text-main);" required>
                                        <option value="">-- Seleccione de la lista --</option>
                                        ${options}
                                    </select>
                                </div>
                             `;
                             containerDetalles.style.display = 'block';
                             document.getElementById('glob-mov-cantidad').setAttribute('required', 'true');
                             document.getElementById('glob-mov-cantidad').closest('.form-group').style.display = 'block';
                         }
                     } catch (e) {
                         specificContainer.innerHTML = '<div style="color:#dc3545; text-align:center; padding:10px;">Error al cargar items de inventario</div>';
                     }
                 });
             }
        });

        document.getElementById('form-movimiento-global').onsubmit = async (e) => {
            e.preventDefault();
            const val = tipoSelect.value;
            const descInput = document.getElementById('glob-mov-obs').value;
            
            let data = {
                tipo_movimiento: val,
                observaciones: descInput,
                jreparable: true
            };

            let apiAction = 'kardex_producto';

            if (val == '2') {
                // Venta múltiple
                apiAction = 'venta_formal';
                const rowsSelects = containerItem.querySelectorAll('.row-prod-select');
                const rowsCants = containerItem.querySelectorAll('.row-prod-cant');
                
                data.id_productos = Array.from(rowsSelects).map(s => s.value).filter(v => v);
                data.cantidades = Array.from(rowsCants).map((c, i) => rowsSelects[i].value ? c.value : null).filter(v => v !== null);
                
                if (data.id_productos.length === 0) {
                    if (window.UIComponents) UIComponents.showError('Validación', 'Debe seleccionar al menos un producto válido.');
                    return;
                }

                data.id_cliente = document.getElementById('glob-mov-cliente').value;
                data.id_forma_pago = document.getElementById('glob-mov-pago').value;

            } else if (val == '5') {
                // Devolución múltiple por factura
                apiAction = 'devolucion_factura';
                const factId = document.getElementById('dev-fact-id-selected')?.value;
                if (!factId) {
                    if (window.UIComponents) UIComponents.showError('Validación', 'Por favor busque y seleccione una factura primero.');
                    return;
                }

                const prodsRows = containerItem.querySelectorAll('.dev-prod-row');
                data.id_factura = factId;
                data.id_productos = [];
                data.cantidades = [];
                data.reparables = [];

                prodsRows.forEach(row => {
                    const chk = row.querySelector('.chk-dev-item');
                    if (chk.checked) {
                        data.id_productos.push(row.dataset.idProd);
                        const cantInput = row.querySelector('.inp-dev-cant');
                        data.cantidades.push(cantInput ? cantInput.value : row.dataset.cantFacturada);
                        data.reparables.push(false); // Por defecto todos entran como dañados/pendientes
                    }
                });

                if (data.id_productos.length === 0) {
                    if (window.UIComponents) UIComponents.showError('Validación', 'Seleccione al menos un item para procesar la devolución.');
                    return;
                }

            } else {
                // Movimiento estándar (Producción / Daño) - Single Item
                const targetSelect = document.getElementById('glob-mov-target');
                if (!targetSelect || !targetSelect.value) {
                    if (window.UIComponents) UIComponents.showError('Validación', 'Seleccione un item del catálogo.');
                    return;
                }

                data.id_item = targetSelect.value;
                data.tipo_item = document.getElementById('glob-mov-subtipo').value;
                data.cantidad = document.getElementById('glob-mov-cantidad').value;
            }

            if (window.UIComponents) UIComponents.toggleLoading(true);
            try {
                const response = await window.ApiService.fetchApiGestion('create', apiAction, data);
                if (window.UIComponents) UIComponents.toggleLoading(false);

                if (response.success || response.result) {
                    if (window.refreshSidebarStats) window.refreshSidebarStats();
                    modal.style.display = 'none';
                    if (window.UIComponents) {
                        UIComponents.showSuccess('Operación completada con éxito', () => {
                             window.location.reload();
                        });
                    } else {
                        alert('Operación exitosa');
                        window.location.reload();
                    }
                } else {
                    const errorMsg = response.error || response.message || 'Error en la validación de la base de datos';
                    if (window.UIComponents) UIComponents.showError('Error en Operación', errorMsg);
                }
            } catch (err) {
                if (window.UIComponents) UIComponents.toggleLoading(false);
                console.error(err);
                if (window.UIComponents) UIComponents.showError('Fallo Crítico', err.message || 'Error de comunicación');
            }
        };
    };

    window.refreshSidebarStats = async function() {
        try {
            const res = await ApiService.fetchApiGestion('read', 'stats');
            if (res && res.success && res.data) {
                const d = res.data;
                const fmt = new Intl.NumberFormat('es-CO', { 
                    style: 'currency', 
                    currency: 'COP', 
                    minimumFractionDigits: 0,
                    maximumFractionDigits: 0
                });
                
                const elTotal = document.getElementById('sidebar-total-ventas');
                const elDiarias = document.getElementById('sidebar-ventas-diarias');
                const elProd = document.getElementById('sidebar-total-productos');
                
                if (elTotal) elTotal.textContent = fmt.format(d.total_ventas);
                if (elDiarias) elDiarias.textContent = fmt.format(d.ventas_diarias);
                if (elProd) elProd.textContent = d.total_productos;
                
                console.log("Estadísticas de la barra lateral actualizadas");
            }
        } catch (e) {
            console.error("Error al refrescar estadísticas:", e);
        }
    };

    function injectStyles() {
        if (document.getElementById('instrumental-styles')) return;
        const style = document.createElement('style');
        style.id = 'instrumental-styles';
        style.textContent = `
            .instrumental-view-wrapper { animation: fadeIn 0.4s ease-out; background: var(--bg-primary); display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 80vh; padding: 20px 0; }
            .instrumental-selection-container { display: flex; justify-content: center; align-items: center; gap: 40px; padding: 30px; min-height: 450px; flex-shrink: 0; width: 100%; }
            .selection-card { width: 300px; height: 400px; background: var(--bg-secondary); border-radius: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.3); display: flex; flex-direction: column; justify-content: center; align-items: center; cursor: pointer; transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.4s, background 0.4s, border 0.4s; position: relative; overflow: hidden; border: 1px solid var(--border-color); }
            @media (max-width: 992px) { .instrumental-selection-container { flex-direction: column; padding: 20px; gap: 20px; height: auto; min-height: 100%; } .selection-card { width: 100%; max-width: 350px; height: 300px; box-shadow: 0 5px 20px rgba(0,0,0,0.3); border: 1px solid var(--border-color); } }
            .selection-card:hover { transform: translateY(-15px) scale(1.02); box-shadow: 0 30px 60px rgba(0,0,0,0.5); }
            .selection-card.instrumentos:hover { border: 2px solid #36498f !important; background: rgba(54, 73, 143, 0.25) !important; box-shadow: 0 15px 40px rgba(54, 73, 143, 0.4); }
            .selection-card.kits:hover { border: 2px solid #087d4e !important; background: rgba(8, 125, 78, 0.25) !important; box-shadow: 0 15px 40px rgba(8, 125, 78, 0.4); }
            .card-icon { width: 100px; height: 100px; background: var(--bg-primary); border-radius: 50%; display: flex; justify-content: center; align-items: center; margin-bottom: 30px; z-index: 1; box-shadow: 0 4px 10px rgba(0,0,0,0.1); transition: transform 0.4s ease; overflow: hidden; }
            .selection-card:hover .card-icon { transform: scale(1.1) rotate(5deg); }
            .card-img { width: 100%; height: 100%; object-fit: cover; }
            .card-title { font-size: 24px; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 15px; z-index: 1; }
            .instrumentos .card-title { color: #36498f; }
            .kits .card-title { color: #087d4e; }
            .card-description { text-align: center; color: var(--text-muted); font-size: 14px; padding: 0 30px; z-index: 1; line-height: 1.6; }
            @keyframes fadeIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }
            
            .instrumento-card:hover { transform: translateY(-5px); box-shadow: 0 10px 25px var(--card-shadow) !important; border-color: var(--primary-color) !important; }
        `;
        document.head.appendChild(style);
    }
});






    window.restoreItem = function(type, id) {
        if (!window.UIComponents) return;
        
        UIComponents.showConfirm(
            '¿Restaurar registro?', 
            'El registro volverá a estar disponible en el inventario.', 
            async () => {
                if (window.UIComponents) UIComponents.toggleLoading(true);
                try {
                    const response = await window.ApiService.fetchApiGestion('restore', type, null, id);
                    if (window.UIComponents) UIComponents.toggleLoading(false);
                    
                    if (response.success || response.result) {
                        UIComponents.showSuccess('Registro restaurado correctamente', () => window.location.reload());
                    } else {
                        UIComponents.showError('Error al restaurar', response.error || 'No se pudo procesar la solicitud');
                    }
                } catch (err) {
                    if (window.UIComponents) UIComponents.toggleLoading(false);
                    UIComponents.showError('Error de servidor', 'No se pudo comunicar con el servidor');
                }
            },
            'Sí, restaurar'
        );
    };
