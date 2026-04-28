/**
 * JavaScript/controllers/mat_prim_controller.js
 * CONTROLADOR ATÓMICO: Gestión de Materia Prima y Categorías
 * 
 * Encapsula la lógica de inventario de materia prima, movimientos de kardex e historial de precios.
 */

window.FormSchemas = window.FormSchemas || {};

// Esquema de formulario para la gestión de Materia Prima
window.FormSchemas['materias_primas'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};

    const mapOptions = (list) => {
        if (!list) return [];
        return list.map(item => {
            if (typeof item === 'object' && item !== null) {
                if (item.label) return item;
                const id = item.id || item.id_prov || item.id_unidad_medida;
                const label = item.label || item.nom_prov || item.nom_unidad_medida || item.nombre;
                if (id && label) return { id, label };
            }
            return { id: item, label: item };
        });
    };

    const optProveedores = mapOptions(aux.proveedores);
    const optUnidades = mapOptions(aux.unidades || aux.unidades_medida) || [{ id: 1, label: 'Unidad' }];
    const isCreate = !d.id_mat_prima;

    return [
        { name: 'id_cat_mat', type: 'hidden', value: d.id_cat_mat || window.MatPrimController.state.currentCategory || '' },
        { label: 'Nombre Materia Prima', name: 'nom_materia_prima', type: 'text', value: d.nom_materia_prima || d.nombre, required: true, fullWidth: true, placeholder: 'Ej: Alambre Níquel-Titanio', helpText: 'Nombre descriptivo.' },
        { label: 'Stock Mínimo', name: 'stock_min', type: 'number', value: d.stock_min || '', required: true, min: 1, max: 10000, helpText: 'Límite de alerta mínima.' },
        { label: 'Stock Máximo', name: 'stock_max', type: 'number', value: d.stock_max || '', required: true, min: 1, max: 10000, helpText: 'Capacidad máxima en bodega.' },
        { label: 'Imagen', name: 'img_url', type: 'file', accept: '.jpg, .png', required: isCreate, fullWidth: true, helpText: 'Seleccione archivo JPG o PNG.' },
        { label: 'Proveedor', name: 'id_prov', type: 'select', options: optProveedores, value: d.id_prov, required: true, placeholder: '-- Seleccione --', helpText: 'Proveedor que suministra esta materia.' },
        { label: 'Valor de Medida', name: 'valor_medida', type: 'number', value: d.valor_medida || '', required: true, placeholder: 'Ej: 10', step: '0.01', helpText: 'Valor numérico (Ej: 10, 0.5).' },
        { label: 'Unidad de Medida', name: 'id_unidad_medida', type: 'select', options: optUnidades, value: d.id_unidad_medida, required: true, helpText: 'Unidad física (Kg, Gramos, Metros).' },
        { label: 'Precio Actual (Unidad)', name: 'precio_inicial', type: 'number', required: true, min: 0, value: (d.precio_actual || d.precio_inicial || d.precio) ? Math.round(Number(d.precio_actual || d.precio_inicial || d.precio)) : '', placeholder: 'Ej: 1500', helpText: 'Costo por unidad de esta materia prima.' },
        ...(isCreate ? [
            { label: 'Lote Inicial', name: 'lote', type: 'text', required: false, maxLength: 20, placeholder: 'Ej: L0T-992', helpText: 'Código de lote del proveedor.' },
            { label: 'Tipo Material', name: 'tipo_mat_prima', type: 'text', required: false, maxLength: 50, placeholder: 'Ej: Metal', helpText: 'Clasificación del material.' },
            { label: 'Cantidad Inicial', name: 'cant_mat_prima', type: 'number', required: true, min: 1, max: 10000, placeholder: 'Ej: 50', helpText: 'Cantidad de unidades que ingresan por primera vez.' }
        ] : [])
    ];
};

// Esquema de formulario para movimientos
window.FormSchemas['movimiento_materia'] = (data = {}) => {
    const aux = window.auxiliares || {};
    const optMP = (window.MatPrimController.state.materiasData || []).map(m => ({ id: m.id_mat_prima, label: m.nom_materia_prima }));
    const optProveedores = (aux.proveedores || []).map(p => ({ 
        id: p.id || p.id_prov, 
        label: p.label || p.nom_prov 
    }));
    
    // Si no hay materias en el estado (ej: abierto desde vista de categorías), cargarlas
    if (optMP.length === 0 && window.MatPrimController.state.allMateriasSimple) {
        window.MatPrimController.state.allMateriasSimple.forEach(m => optMP.push({ id: m.id_mat_prima, label: m.nom_materia_prima }));
    }

    return [
        { label: 'Materia Prima', name: 'id_materia', type: 'select', options: optMP, value: data.id_mat_prima || '', required: true },
        { label: 'Proveedor', name: 'id_proveedor', type: 'select', options: optProveedores, value: data.id_prov || '', required: true },
        { 
            label: 'Tipo de Movimiento', 
            name: 'tipo_movimiento', 
            type: 'select', 
            options: [
                { id: 1, label: 'Compra (Entrada)' },
                { id: 2, label: 'Producción (Salida)' },
                { id: 3, label: 'Ajuste Positivo' },
                { id: 4, label: 'Daño / Baja (Salida)' }
            ], 
            required: true 
        },
        { label: 'Cantidad', name: 'cantidad', type: 'number', required: true, min: 0.01, step: '0.01' },
        { label: 'Observaciones', name: 'observaciones', type: 'textarea', required: false, placeholder: 'Ej: Ingreso por compra lote 2024...' }
    ];
};

// --- OBJETO CONTROLADOR PRINCIPAL ---
window.MatPrimController = {
    // Estado interno encapsulado
    state: {
        currentStatusFilter: 'true',      // Habilitadas/Inhabilitadas (Categorías)
        currentStatusFilterItems: 'true', // Habilitadas/Inhabilitadas (Materias)
        currentCategory: null,            // ID de la categoría seleccionada
        categoriasData: [],
        materiasData: [],
        allMateriasSimple: []             // Lista plana para el modal de movimientos
    },

    /**
     * MÉTODO: injectStyles
     * PROPÓSITO: Agrega las animaciones CSS necesarias para la experiencia visual.
     */
    injectStyles: function() {
        if (document.getElementById('matprim-styles-atomic')) return;
        const style = document.createElement('style');
        style.id = 'matprim-styles-atomic';
        style.textContent = `
            @keyframes matPrimSlideInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
            @keyframes matPrimFadeIn { from { opacity: 0; } to { opacity: 1; } }
            .mat-prim-slide-up { animation: matPrimSlideInUp 0.4s ease-out backwards; }
            .mat-prim-fade { animation: matPrimFadeIn 0.3s ease-out; }
            .mat-card:hover { transform: translateY(-5px); box-shadow: 0 10px 25px rgba(0,0,0,0.15) !important; }
        `;
        document.head.appendChild(style);
    },

    /**
     * MÉTODO: loadView
     * PROPÓSITO: Carga la interfaz principal de Materia Prima (Vista de Categorías).
     */
    loadView: async function (container = null) {
        this.injectStyles();
        
        // RESET DE ESTADO: Limpiar filtros y datos locales para evitar contaminación en modales globales
        this.state.currentCategory = null;
        this.state.materiasData = [];

        const contentArea = container || document.getElementById('dynamic-view') || document.querySelector('.a2');
        if (!contentArea) return;

        contentArea.innerHTML = `
            <div id="materia-prima-root" class="mat-prim-slide-up" style="padding: 20px; min-height: calc(100vh - 70px); background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid #087d4e; padding-bottom:10px; margin-bottom:20px;">
                    <div style="display: flex; align-items: center; gap: 20px;">
                        <h2 style="color: var(--welcome-blue); margin:0;"><i class="fa-solid fa-boxes-stacked"></i> Materia Prima</h2>
                        <div class="status-filters" style="display: flex; background: var(--bg-secondary); padding: 4px; border-radius: 20px; gap: 4px; border: 1px solid var(--border-color);">
                            <button onclick="window.MatPrimController.toggleStatusFilter('true')" id="mat-filter-btn-hab" 
                                style="padding: 6px 15px; border: none; border-radius: 15px; cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.3s;">
                                Habilitadas
                            </button>
                            <button onclick="window.MatPrimController.toggleStatusFilter('false')" id="mat-filter-btn-inhab" 
                                style="padding: 6px 15px; border: none; border-radius: 15px; cursor: pointer; font-size: 0.85rem; font-weight: 600; transition: all 0.3s;">
                                Inhabilitadas
                            </button>
                        </div>
                    </div>
                    <div style="display:flex; gap:10px;">
                        <button onclick="window.MatPrimController.abrirModalCategorias()" style="background: var(--header-blue); color:white; border:none; padding:10px 20px; border-radius:5px; cursor:pointer; font-weight:bold; box-shadow: 0 4px 10px rgba(0,0,0,0.2);">
                            <i class="fa-solid fa-layer-group"></i> Administrar Categorías
                        </button>
                        <button onclick="window.MatPrimController.abrirModalMovimiento()" style="background:#087d4e; color:white; border:none; padding:10px 20px; border-radius:5px; cursor:pointer; font-weight:bold; box-shadow: 0 4px 10px rgba(8,125,78,0.2);">
                            <i class="fa-solid fa-right-left"></i> Registrar Movimiento
                        </button>
                    </div>
                </div>
                <div id="materia-prima-container" style="display:grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap:25px; padding:10px;"></div>
            </div>
        `;

        this.updateButtonsUI('mat-filter-btn-hab', 'mat-filter-btn-inhab', this.state.currentStatusFilter);
        await this.init();
        this.cacheAllMaterias(); // Precargar para el modal de movimientos
    },

    /**
     * MÉTODO: cacheAllMaterias
     * PROPÓSITO: Carga una lista simple de todas las materias para el selector de movimientos.
     */
    cacheAllMaterias: async function() {
        try {
            const res = await window.ApiService.fetchApiGestion('read', 'materias_primas_list');
            this.state.allMateriasSimple = res.data || [];
        } catch (e) {
            console.error("Error al cachear materias:", e);
        }
    },

    /**
     * MÉTODO: init
     * PROPÓSITO: Inicializa la carga de categorías desde la BD.
     */
    init: async function() {
        try {
            const response = await window.ApiService.fetchApiGestion('read', `categorias_materia&estado=${this.state.currentStatusFilter}`);
            this.state.categoriasData = response.data || [];
            this.renderCategoryCards(this.state.categoriasData);
        } catch (e) {
            console.error(e);
            const container = document.getElementById('materia-prima-container');
            if (container) container.innerHTML = `<p style="color:red; text-align:center;">Error: ${e.message}</p>`;
        }
    },

    toggleStatusFilter: function(estado) {
        if (this.state.currentStatusFilter === estado) return;
        this.state.currentStatusFilter = estado;
        this.updateButtonsUI('mat-filter-btn-hab', 'mat-filter-btn-inhab', estado);
        this.init();
    },

    /**
     * MÉTODO: renderCategoryCards
     * PROPÓSITO: Dibuja las categorías en formato tarjeta.
     */
    renderCategoryCards: function(data) {
        const container = document.getElementById('materia-prima-container');
        if (!container) return;
        container.innerHTML = '';

        data.forEach(cat => {
            const isInactive = cat.ind_vivo === false || cat.ind_vivo === 0 || cat.ind_vivo === 'f';
            const card = document.createElement('div');
            card.style.cssText = `background: var(--bg-secondary); border-radius:15px; box-shadow:0 10px 30px var(--card-shadow); padding:20px; text-align:center; cursor:pointer; border:1px solid var(--border-color); transition:all 0.3s; position:relative; color: var(--text-main);`;
            
            if (isInactive) card.style.opacity = '0.7';

            card.innerHTML = `
                ${isInactive ? '<span style="position:absolute; top:10px; right:10px; background:#dc3545; color:white; padding:2px 8px; border-radius:10px; font-size:0.7rem;">INACTIVO</span>' : ''}
                <div style="font-size:3rem; color:#087d4e; margin-bottom:15px;"><i class="fa-solid fa-boxes-stacked"></i></div>
                <h3 style="margin:0; color: var(--text-main);">${cat.nom_categoria}</h3>
                ${isInactive ? `
                    <button onclick="event.stopPropagation(); window.MatPrimController.performRestore('categorias_materia', ${cat.id_cat_mat})" 
                        style="margin-top:15px; background: rgba(54, 73, 143, 0.1); color: var(--welcome-blue); border: 1px solid var(--border-color); padding:5px 15px; border-radius:15px; cursor:pointer; font-weight:bold;">
                        <i class="fa-solid fa-trash-can-arrow-up"></i> Restaurar
                    </button>
                ` : ''}
            `;
            
            if (!isInactive) {
                card.onclick = () => this.loadManagementView(cat.id_cat_mat, cat.nom_categoria);
            }
            container.appendChild(card);
        });
    },

    /**
     * MÉTODO: loadManagementView
     * PROPÓSITO: Carga la vista de gestión interna de una categoría (Lista de Materias Primas).
     */
    loadManagementView: async function(categoryId, categoryName) {
        this.state.currentCategory = categoryId;
        this.state.currentStatusFilterItems = 'true';

        const contentArea = document.getElementById('dynamic-view') || document.querySelector('.a2');
        contentArea.innerHTML = `
            <div id="materia-management-root" class="mat-prim-slide-up" style="padding: 20px; background: var(--bg-primary); min-height: 100%;">
                <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid var(--border-color); padding-bottom:10px; margin-bottom:20px;">
                    <div style="display:flex; align-items:center; gap:15px;">
                        <button onclick="window.MatPrimController.loadView()" style="background:none; border:none; cursor:pointer; color: var(--text-muted); font-size:1.1rem; transition: color 0.2s;" onmouseover="this.style.color='var(--welcome-blue)'" onmouseout="this.style.color='var(--text-muted)'">
                            <i class="fa-solid fa-arrow-left"></i> Volver
                        </button>
                        <h2 style="color: var(--welcome-blue); margin:0; font-family: 'Segoe UI', sans-serif;">${categoryName}</h2>
                    </div>
                    <div style="display:flex; gap:15px; align-items:center;">
                        <div class="status-filters" style="display: flex; background: var(--bg-secondary); padding: 4px; border-radius: 20px; gap: 4px; border: 1px solid var(--border-color);">
                            <button onclick="window.MatPrimController.toggleStatusFilterItems('true')" id="mat-item-btn-hab" style="padding:6px 15px; border:none; border-radius:15px; cursor:pointer;">Habilitadas</button>
                            <button onclick="window.MatPrimController.toggleStatusFilterItems('false')" id="mat-item-btn-inhab" style="padding:6px 15px; border:none; border-radius:15px; cursor:pointer;">Inhabilitadas</button>
                        </div>
                        <button onclick="window.MatPrimController.openAddMateriaModal(${categoryId})" style="background:#087d4e; color:white; border:none; padding:10px 20px; border-radius:20px; cursor:pointer; font-weight:bold; box-shadow: 0 4px 10px rgba(8,125,78,0.2);">
                            <i class="fa-solid fa-plus"></i> Nueva Materia
                        </button>
                    </div>
                </div>
                <div id="materias-grid" style="display:grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap:25px;"></div>
            </div>
        `;

        this.updateButtonsUI('mat-item-btn-hab', 'mat-item-btn-inhab', this.state.currentStatusFilterItems);
        await this.fetchAndRenderGrid();
    },

    toggleStatusFilterItems: function(estado) {
        if (this.state.currentStatusFilterItems === estado) return;
        this.state.currentStatusFilterItems = estado;
        this.updateButtonsUI('mat-item-btn-hab', 'mat-item-btn-inhab', estado);
        this.fetchAndRenderGrid();
    },

    fetchAndRenderGrid: async function() {
        try {
            const response = await window.ApiService.fetchApiGestion('read', `materias_x_cat&id=${this.state.currentCategory}&estado=${this.state.currentStatusFilterItems}`);
            this.state.materiasData = response.data || [];
            this.renderItemCards(this.state.materiasData);
        } catch (e) {
            console.error(e);
            document.getElementById('materias-grid').innerHTML = `<p style="color:red;">Error al cargar materias.</p>`;
        }
    },

    renderItemCards: function(data) {
        const grid = document.getElementById('materias-grid');
        if (!grid) return;
        grid.innerHTML = '';

        data.forEach(item => {
            const isInactive = item.ind_vivo === false || item.ind_vivo === 'f';
            const stockActual = item.cant_mat_prima || 0;
            const stockMin = item.stock_min || 0;
            const outOfStock = stockActual <= stockMin;
            
            const card = document.createElement('div');
            card.className = 'mat-card mat-prim-fade' + (isInactive ? ' inactive-card' : '');
            
            const headerColor = outOfStock ? '#dc3545' : 'var(--welcome-blue)';

            card.style.cssText = `
                background: var(--bg-secondary); border-radius:12px; 
                box-shadow: 0 10px 25px var(--card-shadow); 
                overflow:hidden; border:1px solid ${outOfStock ? '#dc3545' : 'var(--border-color)'}; 
                display:flex; flex-direction:column; transition: all 0.2s;
                ${isInactive ? 'opacity: 0.75; filter: grayscale(0.5);' : ''}
            `;
            
            card.innerHTML = `
                <div style="height:150px; background: var(--bg-primary); position:relative; overflow:hidden;">
                    <img src="${item.img_url || '../../images/no-image.png'}" style="width:100%; height:100%; object-fit:contain; padding:10px; cursor:pointer;" onclick="window.MatPrimController.openDetailModal(${item.id_mat_prima})">
                    ${outOfStock ? '<div style="position:absolute; top:10px; right:10px; background:#dc3545; color:white; padding:4px 10px; border-radius:12px; font-size:0.75rem; font-weight:bold; box-shadow:0 2px 5px rgba(0,0,0,0.2);">BAJO STOCK</div>' : ''}
                    ${isInactive ? '<div style="position:absolute; top:10px; left:10px; background:#666; color:white; padding:2px 10px; border-radius:10px; font-size:0.7rem;">INACTIVO</div>' : ''}
                </div>
                <div style="padding:15px; flex-grow:1; display:flex; flex-direction:column; justify-content:space-between;">
                    <div>
                        <h4 style="margin:0; color:${headerColor}; font-size:1.1rem;">${item.nom_materia_prima}</h4>
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-top:8px;">
                            <span style="color: var(--text-muted); font-size:0.9rem;">Disp: <strong style="${outOfStock ? 'color:#dc3545' : 'color: var(--text-main)'}">${stockActual}</strong></span>
                            <span style="color: var(--text-muted); font-size:0.8rem;">Min: ${stockMin}</span>
                        </div>
                    </div>
                    <div style="margin-top:15px; display:flex; gap:10px; justify-content:flex-end; border-top:1px solid var(--border-color); padding-top:10px;">
                        ${!isInactive ? `
                            <button onclick="window.MatPrimController.openEditMateriaModal(${item.id_mat_prima})" style="border:none; background:none; color: var(--welcome-blue); cursor:pointer; font-size:1.1rem; padding: 5px;" title="Editar"><i class="fa-solid fa-pen-to-square"></i></button>
                            <button onclick="window.MatPrimController.openDetailModal(${item.id_mat_prima})" style="border:none; background:none; color:#087d4e; cursor:pointer; font-size:1.1rem; padding: 5px;" title="Ver Detalle"><i class="fa-solid fa-eye"></i></button>
                            <button onclick="window.MatPrimController.performDelete('materias_primas', ${item.id_mat_prima})" style="background: #dc3545; border: 1px solid #000; color: white; cursor: pointer; width: 30px; height: 30px; border-radius: 6px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s;" title="Eliminar">
                                <i class="fa-solid fa-trash-can" style="font-size: 0.85rem;"></i>
                            </button>
                        ` : `
                            <button onclick="window.MatPrimController.performRestore('materias_primas', ${item.id_mat_prima})" style="background: #28a745; border: 1px solid #000; color: white; cursor: pointer; height: 30px; padding: 0 12px; border-radius: 6px; display: flex; align-items: center; gap: 8px; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s; font-weight: bold; font-size: 0.8rem;">
                                <i class="fa-solid fa-trash-can-arrow-up"></i> Restaurar
                            </button>
                        `}
                    </div>
                </div>
            `;
            grid.appendChild(card);
        });
    },

    // --- ACCIONES CRUD ---

    performDelete: async function(tabla, id) {
        const isCat = tabla === 'categorias_materia';
        const msg = isCat ? 'Se inhabilitarán todas las materias primas de esta categoría.' : 'La materia prima pasará a la papelera.';
        
        const result = await Swal.fire({
            title: isCat ? '¿Eliminar Categoría?' : '¿Eliminar Materia Prima?',
            text: msg,
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Sí, inhabilitar',
            cancelButtonText: 'Cancelar'
        });

        if (result.isConfirmed) {
            try {
                const response = await window.ApiService.fetchApiGestion('delete', tabla, null, id);
                if (response.success) {
                    await Swal.fire('Éxito', 'Registro inhabilitado correctamente.', 'success');
                    
                    // Si estamos en el modal de categorías, refrescarlo
                    const modalGestion = document.getElementById('modalGestion');
                    if (modalGestion && modalGestion.style.display === 'block') {
                        this.abrirModalCategorias();
                    }
                    
                    this.loadView();
                } else throw new Error(response.error);
            } catch (err) {
                Swal.fire('Error', err.message, 'error');
            }
        }
    },

    performRestore: async function(tabla, id) {
        const result = await Swal.fire({
            title: '¿Restaurar registro?',
            text: 'El registro volverá a estar disponible en el inventario activo.',
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: '#28a745',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Sí, restaurar',
            cancelButtonText: 'Cancelar'
        });

        if (result.isConfirmed) {
            try {
                const response = await window.ApiService.fetchApiGestion('restore', tabla, null, id);
                if (response.success) {
                    await Swal.fire('Éxito', 'Registro restaurado correctamente.', 'success');
                    this.loadView();
                } else throw new Error(response.error);
            } catch (err) {
                Swal.fire('Error', err.message, 'error');
            }
        }
    },

    // --- AUXILIARES UI ---

    updateButtonsUI: function(idHab, idInhab, estado) {
        const btnHab = document.getElementById(idHab);
        const btnInhab = document.getElementById(idInhab);
        if (!btnHab || !btnInhab) return;

        if (estado === 'true') {
            btnHab.style.background = '#36498f'; btnHab.style.color = 'white';
            btnInhab.style.background = 'transparent'; btnInhab.style.color = '#666';
        } else {
            btnInhab.style.background = '#dc3545'; btnInhab.style.color = 'white';
            btnHab.style.background = 'transparent'; btnHab.style.color = '#666';
        }
    },

    abrirModalCategorias: async function() {
        const modal = document.getElementById('modalGestion');
        const modalTitle = document.getElementById('modalGestionTitle');
        const modalBody = document.getElementById('modalGestionBody');
        const btnNuevo = document.getElementById('btnNuevoRegistro');

        if (!modal || !modalBody) return;

        modalTitle.innerText = "Administrar Categorías de Materia Prima";
        modalBody.innerHTML = '<div style="text-align:center; padding:20px;"><i class="fa-solid fa-spinner fa-spin"></i> Cargando...</div>';
        modal.style.display = 'block';

        // Configurar botón "Nuevo"
        btnNuevo.style.display = 'flex';
        btnNuevo.onclick = () => {
            this.mostrarFormularioLocal('categorias_materia', 'create');
        };

        try {
            const res = await window.ApiService.fetchApiGestion('read', 'categorias_materia&estado=true');
            const data = res.data || [];
            
            let html = `
                <table class="tabla-gestion" style="width:100%; border-collapse:collapse; color: var(--text-main);">
                    <thead>
                        <tr style="background: var(--bg-primary); text-align:left;">
                            <th style="padding:12px; border-bottom:2px solid var(--welcome-blue); color: var(--welcome-blue);">ID</th>
                            <th style="padding:12px; border-bottom:2px solid var(--welcome-blue); color: var(--welcome-blue);">Nombre Categoría</th>
                            <th style="padding:12px; border-bottom:2px solid var(--welcome-blue); color: var(--welcome-blue); text-align:right;">Acciones</th>
                        </tr>
                    </thead>
                    <tbody>
            `;

            data.forEach(cat => {
                html += `
                    <tr style="border-bottom:1px solid var(--border-color);">
                        <td style="padding:10px;">${cat.id_cat_mat}</td>
                        <td style="padding:10px;"><strong style="color: var(--text-main);">${cat.nom_categoria}</strong></td>
                        <td style="padding:10px; text-align:right;">
                            <button onclick="window.MatPrimController.mostrarFormularioLocal('categorias_materia', 'update', {id_cat_mat:${cat.id_cat_mat}, nom_categoria:'${cat.nom_categoria}'})" 
                                style="border:none; background:none; color: var(--welcome-blue); cursor:pointer; margin-right:10px; font-size: 1rem;"><i class="fa-solid fa-pen"></i></button>
                            <button onclick="window.MatPrimController.performDelete('categorias_materia', ${cat.id_cat_mat})" 
                                style="background: #dc3545; border: 1px solid #000; color: white; cursor: pointer; width: 30px; height: 30px; border-radius: 6px; display: inline-flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s;">
                                <i class="fa-solid fa-trash-can" style="font-size: 0.85rem;"></i>
                            </button>
                        </td>
                    </tr>
                `;
            });

            html += `</tbody></table>`;
            modalBody.innerHTML = data.length > 0 ? html : '<p style="text-align:center; padding:20px; color: var(--text-muted);">No hay categorías registradas.</p>';

        } catch (e) {
            modalBody.innerHTML = `<p style="color:red; padding:20px;">Error: ${e.message}</p>`;
        }
    },

    abrirModalMovimiento: async function() {
        const modal = document.getElementById('modalMovimientoGlobal');
        const modalTitle = document.getElementById('modalGlobalMovTitle');
        const modalBody = document.getElementById('modalGlobalMovBody');

        if (!modal || !modalBody) return;

        // Cargar categorías si no están en el estado
        if (this.state.categoriasData.length === 0) {
            try {
                const response = await window.ApiService.fetchApiGestion('read', 'categorias_materia&estado=true');
                this.state.categoriasData = response.data || [];
            } catch (e) { console.error("Error cargando categorías", e); }
        }

        // Lazy load auxiliares si no están (para los proveedores)
        if (!window.auxiliares || Object.keys(window.auxiliares).length === 0) {
            modalTitle.innerText = "Cargando...";
            modalBody.innerHTML = '<div style="text-align:center; padding:30px;"><i class="fas fa-spinner fa-spin fa-2x"></i><p>Cargando datos auxiliares...</p></div>';
            modal.style.display = 'block';
            await window.cargaAuxiliares();
        }

        modalTitle.innerHTML = '<i class="fa-solid fa-right-left"></i> Registrar Movimiento de Materia Prima';
        modal.style.display = 'block';

        this.renderFormMovimiento(modalBody);
    },

    renderFormMovimiento: function(container) {
        const cats = this.state.categoriasData;
        const provs = (window.auxiliares.proveedores || []).map(p => ({ id: p.id || p.id_prov, label: p.label || p.nom_prov }));

        let html = `
            <form id="form-mov-kardex-local" style="display:flex; flex-direction:column; gap:15px; color: var(--text-main);">
                <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                    <label style="font-weight:600; color: var(--text-main);">Categoría</label>
                    <select id="mov-cat-select" required style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                        <option value="">-- Seleccione Categoría --</option>
                        ${cats.map(c => `<option value="${c.id_cat_mat}">${c.nom_categoria}</option>`).join('')}
                    </select>
                </div>

                <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                    <label style="font-weight:600; color: var(--text-main);">Materia Prima</label>
                    <select name="id_materia" id="mov-mat-select" required disabled style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                        <option value="">-- Seleccione Categoría Primero --</option>
                    </select>
                </div>

                <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                    <label style="font-weight:600; color: var(--text-main);">Proveedor (Auto)</label>
                    <select id="mov-prov-select-display" disabled style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-secondary); color: var(--text-main); opacity: 0.9; cursor:not-allowed;">
                        <option value="">-- Seleccione Materia Prima --</option>
                        ${provs.map(p => `<option value="${p.id}">${p.label}</option>`).join('')}
                    </select>
                    <input type="hidden" name="id_proveedor" id="mov-prov-hidden">
                </div>

                <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                    <label style="font-weight:600; color: var(--text-main);">Tipo de Movimiento</label>
                    <select name="tipo_movimiento" required style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                        <option value="">-- Seleccione --</option>
                        <option value="1">Compra (Entrada)</option>
                        <option value="2">Producción (Salida)</option>
                        <option value="3">Ajuste Positivo</option>
                        <option value="4">Daño / Baja (Salida)</option>
                    </select>
                </div>

                <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                    <label style="font-weight:600; color: var(--text-main);">Cantidad</label>
                    <input type="number" name="cantidad" required step="0.01" min="0.01" style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main);">
                </div>

                <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                    <label style="font-weight:600; color: var(--text-main);">Observaciones</label>
                    <textarea name="observaciones" placeholder="Ej: Ingreso por compra lote 2024..." style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main); min-height:80px;"></textarea>
                </div>

                <div style="margin-top:20px; text-align:right; border-top:1px solid var(--border-color); padding-top:15px; display: flex; justify-content: flex-end; gap: 10px;">
                    <button type="button" onclick="document.getElementById('modalMovimientoGlobal').style.display='none'" style="padding:10px 25px; border:1px solid var(--border-color); background: #6c757d; color: white; border-radius:8px; cursor:pointer; font-weight: bold;">Cancelar</button>
                    <button type="submit" style="padding:10px 25px; background:#087d4e; color:white; border:none; border-radius:8px; cursor:pointer; font-weight:bold; box-shadow: 0 4px 10px rgba(8,125,78,0.2);">Registrar Movimiento</button>
                </div>
            </form>
        `;

        container.innerHTML = html;

        const catSelect = document.getElementById('mov-cat-select');
        const matSelect = document.getElementById('mov-mat-select');
        const provSelect = document.getElementById('mov-prov-select-display');
        const provHidden = document.getElementById('mov-prov-hidden');
        let currentMaterias = [];

        catSelect.onchange = async () => {
            const catId = catSelect.value;
            matSelect.innerHTML = '<option value="">-- Cargando materias... --</option>';
            matSelect.disabled = true;
            provSelect.value = "";
            provHidden.value = "";

            if (!catId) {
                matSelect.innerHTML = '<option value="">-- Seleccione Categoría Primero --</option>';
                return;
            }

            try {
                const res = await window.ApiService.fetchApiGestion('read', `materias_x_cat&id=${catId}&estado=true`);
                currentMaterias = res.data || [];
                
                if (currentMaterias.length > 0) {
                    matSelect.innerHTML = '<option value="">-- Seleccione Materia Prima --</option>' + 
                        currentMaterias.map(m => `<option value="${m.id_mat_prima}">${m.nom_materia_prima}</option>`).join('');
                    matSelect.disabled = false;
                } else {
                    matSelect.innerHTML = '<option value="">No hay materias en esta categoría</option>';
                }
            } catch (e) {
                console.error(e);
                matSelect.innerHTML = '<option value="">Error al cargar materias</option>';
            }
        };

        matSelect.onchange = () => {
            const matId = matSelect.value;
            const mat = currentMaterias.find(m => m.id_mat_prima == matId);
            if (mat && mat.id_prov) {
                provSelect.value = mat.id_prov;
                provHidden.value = mat.id_prov;
            } else {
                provSelect.value = "";
                provHidden.value = "";
            }
        };

        const form = document.getElementById('form-mov-kardex-local');
        form.onsubmit = async (e) => {
            e.preventDefault();
            const formData = new FormData(form);
            const data = Object.fromEntries(formData.entries());
            
            // Normalizar opcionales vacíos a 'N/A'
            if (!data.observaciones || data.observaciones.trim() === '') data.observaciones = 'N/A';
            if (data.lote === '') data.lote = 'N/A';
            if (data.tipo_mat_prima === '') data.tipo_mat_prima = 'N/A';

            try {
                const res = await window.ApiService.fetchApiGestion('create', 'movimiento_materia', data);
                if (res.success) {
                    await Swal.fire('Éxito', 'Movimiento registrado correctamente', 'success');
                    window.location.reload();
                } else throw new Error(res.error);
            } catch (err) {
                Swal.fire('Error', err.message, 'error');
            }
        };
    },

    mostrarFormularioLocal: function(tipo, accion, data = {}) {
        // Versión simplificada de mostrarFormulario para evitar globales
        const modal = document.createElement('div');
        modal.style.cssText = `position:fixed; z-index:3000; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.7); display:flex; align-items:center; justify-content:center;`;
        
        let schema = [];
        if (tipo === 'categorias_materia') {
            schema = [
                { label: 'Nombre de la Categoría', name: 'nom_categoria', type: 'text', value: data.nom_categoria || '', required: true }
            ];
        }

        modal.innerHTML = `
            <div class="mat-prim-slide-up" style="background: var(--bg-secondary); padding:25px; border-radius:12px; width:90%; max-width:400px; box-shadow:0 20px 50px rgba(0,0,0,0.5); border: 1px solid var(--border-color);">
                <h3 style="margin-top:0; color: var(--welcome-blue);">${accion === 'create' ? 'Nueva' : 'Editar'} Categoría</h3>
                <form id="form-local-mp-cat" style="display:flex; flex-direction:column; gap:15px;">
                    ${schema.map(f => `
                        <div class="form-group" style="display:flex; flex-direction:column; gap:5px; padding:0;">
                            <label style="font-weight:600; color: var(--text-main);">${f.label}</label>
                            <input type="${f.type}" name="${f.name}" value="${f.value}" required 
                                style="padding:12px; border-radius:8px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main); outline:none;">
                        </div>
                    `).join('')}
                    <div style="text-align:right; margin-top:10px; gap:10px; display:flex; justify-content:flex-end;">
                        <button type="button" id="btn-cancel-local-mp" style="padding:10px 20px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main); border-radius:8px; cursor:pointer;">Cancelar</button>
                        <button type="submit" style="padding:10px 25px; background: var(--welcome-blue); color:white; border:none; border-radius:8px; cursor:pointer; font-weight:bold;">Guardar</button>
                    </div>
                </form>
            </div>
        `;

        document.body.appendChild(modal);

        modal.querySelector('#btn-cancel-local-mp').onclick = () => modal.remove();
        
        modal.querySelector('form').onsubmit = async (e) => {
            e.preventDefault();
            const formData = new FormData(e.target);
            const payload = Object.fromEntries(formData.entries());
            
            try {
                const res = await window.ApiService.fetchApiGestion(accion, tipo, payload, data.id_cat_mat);
                if (res.success) {
                    modal.remove();
                    this.abrirModalCategorias(); // Recargar tabla
                    this.init(); // Recargar cards de fondo
                } else throw new Error(res.error);
            } catch (err) {
                Swal.fire('Error', err.message, 'error');
            }
        };
    },

    openAddMateriaModal: function(catId) {
        if (typeof window.mostrarFormulario === 'function') {
            window.mostrarFormulario('materias_primas', 'create', { id_cat_mat: catId }, 'local_materia');
        }
    },

    openEditMateriaModal: function(id) {
        const mat = this.state.materiasData.find(m => m.id_mat_prima == id);
        if (mat && typeof window.mostrarFormulario === 'function') {
            window.mostrarFormulario('materias_primas', 'update', mat, 'local_materia');
        }
    },

    /**
     * MÉTODO: openDetailModal
     * PROPÓSITO: Muestra la información extendida y el historial de precios.
     */
    openDetailModal: async function(id) {
        const meta = this.state.materiasData.find(m => m.id_mat_prima == id);
        if (!meta) return;

        const isInactive = meta.ind_vivo === false || meta.ind_vivo === 'f';
        const stockActual = meta.cant_mat_prima || 0;
        const stockMin = meta.stock_min || 0;
        const stockColor = stockActual <= stockMin ? '#dc3545' : '#087d4e';

        let modalInfo = document.getElementById('modal-info-atomic');
        if (!modalInfo) {
            modalInfo = document.createElement('div');
            modalInfo.id = 'modal-info-atomic';
            modalInfo.style.cssText = `display:none; position:fixed; z-index:2100; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.6); overflow-y:auto; padding:20px; font-family:'Segoe UI', sans-serif;`;
            document.body.appendChild(modalInfo);
        }

        modalInfo.innerHTML = `
            <div class="mat-prim-slide-up" style="background: var(--bg-primary); margin: 5% auto; width: 95%; max-width: 650px; border-radius: 15px; box-shadow: 0 20px 60px rgba(0,0,0,0.5); overflow: hidden; border: 1px solid var(--border-color);">
                <div style="background: var(--bg-secondary); padding:20px; border-bottom:3px solid var(--welcome-blue); display:flex; justify-content:space-between; align-items:center;">
                    <h2 style="margin:0; color: var(--welcome-blue);"><i class="fa-solid fa-circle-info"></i> Detalle: ${meta.nom_materia_prima}</h2>
                    <span id="close-detail-atomic" style="font-size:30px; cursor:pointer; color: var(--text-muted);">&times;</span>
                </div>
                <div style="padding:25px;">
                    <div style="display:flex; gap:25px; flex-wrap:wrap;">
                        <div style="flex:1; min-width:200px; background: var(--bg-secondary); padding:15px; border-radius:10px; border:1px solid var(--border-color); text-align:center;">
                            <img src="${meta.img_url || '../../images/no-image.png'}" style="max-width:100%; max-height:220px; object-fit:contain;">
                        </div>
                        <div style="flex:1.5; min-width:250px; background: var(--bg-secondary); padding:20px; border-radius:10px; border:1px solid var(--border-color); color: var(--text-main);">
                            <p style="margin:0 0 12px 0;"><strong>ID Registro:</strong> <span style="color: var(--text-muted);">#${meta.id_mat_prima}</span></p>
                            <p style="margin:0 0 12px 0;"><strong>Proveedor:</strong> <span style="color: var(--text-muted);">${meta.proveedor || 'No asignado'}</span></p>
                            <p style="margin:0 0 12px 0;"><strong>Precio Actual:</strong> <span style="color:#087d4e; font-weight:bold;">${meta.precio_actual ? new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(meta.precio_actual) : 'N/A'}</span></p>
                            <p style="margin:0 0 12px 0;"><strong>Disponible:</strong> <span style="color:${stockColor}; font-weight:bold; font-size:1.2rem;">${stockActual} ${meta.medida_mat_prima || ''}</span></p>
                            <p style="margin:0 0 12px 0;"><strong>Stock Mínimo:</strong> ${stockMin}</p>
                            <p style="margin:0 0 12px 0;"><strong>Stock Máximo:</strong> ${meta.stock_max || 'N/A'}</p>
                            <p style="margin:0 0 12px 0;"><strong>Valor Medida:</strong> ${meta.valor_medida || 0} ${meta.medida_mat_prima || ''}</p>
                        </div>
                    </div>
                </div>
                <div style="background: var(--bg-secondary); padding:20px; text-align:right; border-top:1px solid var(--border-color); display:flex; justify-content:flex-end; gap:12px;">
                    <button id="btn-close-at" style="padding:10px 20px; border:1px solid var(--border-color); background: var(--bg-primary); color: var(--text-main); cursor:pointer; border-radius:8px;">Cerrar</button>
                    ${!isInactive ? `
                        <button onclick="window.MatPrimController.openPriceHistory(${meta.id_mat_prima}, '${meta.nom_materia_prima}')" style="padding:10px 20px; background: var(--welcome-blue); color: #fff; border:none; cursor:pointer; border-radius:8px; display:flex; align-items:center; gap:8px; box-shadow: 0 4px 10px rgba(100,181,246,0.3); font-weight: bold; transition: all 0.2s;">
                            <i class="fa-solid fa-clock-rotate-left"></i> Ver Histórico
                        </button>
                    ` : ''}
                </div>
            </div>
        `;

        modalInfo.style.display = 'block';
        const closeFn = () => { modalInfo.style.display = 'none'; };
        const closeIcon = document.getElementById('close-detail-atomic');
        const closeBtn = document.getElementById('btn-close-at');
        if (closeIcon) closeIcon.onclick = closeFn;
        if (closeBtn) closeBtn.onclick = closeFn;
    },

    /**
     * MÉTODO: openPriceHistory
     * PROPÓSITO: Consulta el historial de variaciones de precio en el Kardex.
     */
    openPriceHistory: async function(id, nombre) {
        try {
            const response = await fetch(`../php/api_gestion.php?tipo=historico_precios&id=${id}&t=${new Date().getTime()}`);
            const result = await response.json();
            if(!result.success) throw new Error(result.error);

            const fmt = new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });
            let modalHist = document.getElementById('modal-price-history-at');
            if (!modalHist) {
                modalHist = document.createElement('div');
                modalHist.id = 'modal-price-history-at';
                modalHist.style.cssText = `position:fixed; z-index:2200; left:0; top:0; width:100%; height:100%; background:rgba(0,0,0,0.75); display:flex; align-items:center; justify-content:center; padding:20px;`;
                document.body.appendChild(modalHist);
            }

            const rows = (result.data || []).map(h => `
                    <td style="padding:12px; font-size:0.85rem;">${h.fecha_formateada}</td>
                    <td style="padding:12px; font-weight:bold; color:#087d4e;">${fmt.format(h.precio_nuevo)}</td>
                    <td style="padding:12px; color:#c62828;">${fmt.format(h.precio_anterior)}</td>
                    <td style="padding:12px; font-size:0.85rem; color: var(--text-main);">${h.motivo || 'N/A'}</td>
                </tr>
            `).join('');

            modalHist.innerHTML = `
                <div class="mat-prim-slide-up" style="background: var(--bg-secondary); width:100%; max-width:750px; border-radius:15px; overflow:hidden; display:flex; flex-direction:column; max-height:80vh; border: 1px solid var(--border-color); box-shadow: 0 30px 70px rgba(0,0,0,0.6);">
                    <div style="background: var(--modal-header-grad); color:white; padding:20px; display:flex; justify-content:space-between; align-items:center;">
                        <h3 style="margin:0; color: white;"><i class="fa-solid fa-clock-rotate-left"></i> Historial de Precios: ${nombre}</h3>
                        <span id="close-hist-at" style="cursor:pointer; font-size:24px; color: white;">&times;</span>
                    </div>
                    <div style="padding:20px; overflow-y:auto; flex:1; background: var(--bg-secondary);">
                        <table style="width:100%; border-collapse:collapse; color: var(--text-main);">
                            <thead>
                                <tr style="background: var(--bg-primary); text-align:left; border-bottom:2px solid var(--welcome-blue);">
                                    <th style="padding:12px; color: var(--welcome-blue);">Fecha</th>
                                    <th style="padding:12px; color: var(--welcome-blue);">P. Nuevo</th>
                                    <th style="padding:12px; color: var(--welcome-blue);">P. Anterior</th>
                                    <th style="padding:12px; color: var(--welcome-blue);">Motivo</th>
                                </tr>
                            </thead>
                            <tbody>${rows || `<tr><td colspan="4" style="text-align:center; padding:40px; color: var(--text-muted);">No hay registros de cambios de precio.</td></tr>`}</tbody>
                        </table>
                    </div>
                    <div style="padding:15px; background: var(--bg-primary); text-align:right; border-top: 1px solid var(--border-color);">
                        <button id="btn-close-hist-at" style="padding:10px 25px; background: var(--welcome-blue); color: #fff; border:none; border-radius:8px; cursor:pointer; font-weight:900; box-shadow: 0 4px 12px rgba(100,181,246,0.4);">Entendido</button>
                    </div>
                </div>
            `;
            modalHist.style.display = 'flex';
            const closeFn = () => { modalHist.style.display = 'none'; };
            const closeIcon = document.getElementById('close-hist-at');
            const closeBtn = document.getElementById('btn-close-hist-at');
            if (closeIcon) closeIcon.onclick = closeFn;
            if (closeBtn) closeBtn.onclick = closeFn;

        } catch (e) {
            Swal.fire('Error', 'No se pudo cargar el historial: ' + e.message, 'error');
        }
    }
};

// --- COMPATIBILIDAD ---
window.loadMateriaPrimaView = (container) => window.MatPrimController.loadView(container);
