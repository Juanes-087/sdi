/**
 * JavaScript/controllers/productos_controller.js
 * CONTROLADOR ATÓMICO: Gestión del Inventario de Ventas (Productos)
 * 
 * Este archivo gestiona la visualización y edición de productos vinculados
 * a instrumentos o kits. Se dispara al hacer clic en "Productos" del Sidebar.
 * Lógica asíncrona mediante ProductosController.loadView().
 */

window.FormSchemas = window.FormSchemas || {};

// Esquema de formulario para la creación/edición de productos
window.FormSchemas['productos'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};

    const mapOptionsLocal = (list) => {
        if (!list) return [];
        return list.map(item => {
            if (typeof item === 'object' && item !== null) {
                if (item.label) return item;
                const id = item.id_instrumento || item.id_kit || item.id;
                const label = item.nom_instrumento || item.nom_kit || item.nombre || item.label;
                if (id && label) return { id, label };
            }
            return { id: item, label: item };
        });
    };

    const isCreate = !d.id;
    const currentTipo = d.tipo || d.discriminador || (d.id_instrumento ? 'instrumento' : (d.id_kit ? 'kit' : 'instrumento'));

    return [
        { 
            label: 'Nombre del Producto', 
            name: 'nombre_producto', 
            type: 'text', 
            value: d.nombre_producto || d.nombre || '', 
            required: true, 
            fullWidth: true, 
            maxLength: 35, 
            helpText: 'Nombre comercial (Máx 35 caracteres).' 
        },
        { 
            label: 'Precio de Venta', 
            name: 'precio_producto', 
            type: 'number', 
            value: d.precio_producto || d.precio || '', 
            required: true, 
            placeholder: 'Ej: 150000', 
            helpText: 'Precio final para el cliente (Máx 999.999).' 
        },
        { 
            label: 'Imagen del Producto', 
            name: 'img_url', 
            type: 'file', 
            accept: '.jpg, .png', 
            required: false, 
            fullWidth: true,
            helpText: isCreate ? 'Si se deja vacío, usará la imagen del kit o instrumento seleccionado.' : 'Dejar vacío para mantener la actual.'
        },
        { 
            label: 'Tipo de Item', 
            name: 'discriminador', 
            type: 'select', 
            options: [
                { id: 'instrumento', label: 'Individual (Instrumento)' },
                { id: 'kit', label: 'Kit (Conjunto)' }
            ],
            value: currentTipo,
            required: true,
            onchange: (e) => {
                const val = e.target.value;
                const groupInst = document.querySelector('[name="display_id_instrumento"]')?.closest('.form-group');
                const groupKit = document.querySelector('[name="display_id_kit"]')?.closest('.form-group');
                if (groupInst) groupInst.style.display = val === 'instrumento' ? 'block' : 'none';
                if (groupKit) groupKit.style.display = val === 'kit' ? 'block' : 'none';
            }
        },
        { 
            label: 'Buscar Instrumento', 
            name: 'id_instrumento', 
            type: 'datalist', 
            options: mapOptionsLocal(aux.instrumentos || []), 
            value: d.id_instrumento,
            initialText: d.id_instrumento ? d.nombre_origen : '',
            required: false,
            hidden: currentTipo !== 'instrumento'
        },
        { 
            label: 'Buscar Kit', 
            name: 'id_kit', 
            type: 'datalist', 
            options: mapOptionsLocal(aux.kits || []), 
            value: d.id_kit,
            initialText: d.id_kit ? d.nombre_origen : '',
            required: false,
            hidden: currentTipo !== 'kit'
        }
    ];
};

// --- OBJETO CONTROLADOR PRINCIPAL ---
window.ProductosController = {
    // Estado interno del módulo (Encapsulado para evitar colisiones)
    state: {
        localData: [],
        currentStatusFilter: 'true', // 'true' = Habilitados, 'false' = Inhabilitados
        currentCategoryFilter: null  // 'instrumento' o 'kit'
    },

    /**
     * MÉTODO: loadView
     * PROPÓSITO: Construye la interfaz del Inventario de Ventas.
     * DISPARADOR: Se ejecuta al hacer clic en "Productos" en el Sidebar.
     * FLUJO:
     *   1. Define el HTML base (Buscador, Filtros Habilitado/Inhabilitado, Filtros por Categoría).
     *   2. Llama a fetchAndRender() para consultar la BD.
     */
    injectStyles: function() {
        if (document.getElementById('productos-styles-atomic')) return;
        const style = document.createElement('style');
        style.id = 'productos-styles-atomic';
        style.textContent = `
            @keyframes prodSlideInUp { from { opacity: 0; transform: translateY(30px); } to { opacity: 1; transform: translateY(0); } }
            @keyframes prodFadeIn { from { opacity: 0; } to { opacity: 1; } }
            .prod-slide-up { animation: prodSlideInUp 0.5s ease-out backwards; }
            .prod-fade { animation: prodFadeIn 0.3s ease-out; }
        `;
        document.head.appendChild(style);
    },

    loadView: async function (container = null) {
        this.injectStyles();
        const contentArea = container || document.getElementById('dynamic-view') || document.querySelector('.a2');
        if (!contentArea) return;

        contentArea.innerHTML = `
            <div id="productos-root" class="prod-slide-up" style="padding: 20px; height: calc(100vh - 80px); display: flex; flex-direction: column; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; border-bottom:2px solid var(--welcome-blue); padding-bottom:10px; margin-bottom:20px; flex-shrink: 0;">
                    <h2 style="color: var(--welcome-blue); margin:0; font-family: 'Segoe UI', sans-serif;"><i class="fa-solid fa-boxes-stacked"></i> Inventario de Productos</h2>
                </div>

                <div class="controls-bar" style="display: flex; flex-direction: column; gap: 15px; margin-bottom: 20px; flex-shrink: 0;">
                    <!-- Barra de Búsqueda y Botón Nuevo: Fondo estándar -->
                    <div style="display: flex; gap: 15px; width: 100%; background: var(--bg-secondary); padding: 18px; border-radius: 15px; border: 1px solid var(--border-color); box-shadow: 0 4px 15px var(--card-shadow); align-items: center;">
                        <div class="search-wrapper" style="flex: 1; position: relative;">
                            <i class="fa-solid fa-search" style="position: absolute; left: 15px; top: 50%; transform: translateY(-50%); color: var(--text-muted);"></i>
                            <input type="text" id="search-productos" placeholder="Buscar productos por nombre o referencia..." 
                                style="width: 100%; padding: 12px 12px 12px 45px; border: 1px solid var(--border-color); border-radius: 25px; outline: none; font-size: 1rem; transition: border-color 0.3s; background: var(--bg-primary); color: var(--text-main); box-shadow: inset 0 2px 4px rgba(0,0,0,0.05);">
                        </div>
                        <button onclick="window.ProductosController.openAddModal()" style="background: linear-gradient(135deg, #36498f 0%, #2a3b7a 100%); color: white; border: none; padding: 12px 30px; border-radius: 25px; cursor: pointer; display: flex; align-items: center; gap: 10px; font-weight: bold; box-shadow: 0 4px 10px rgba(54,73,143,0.3); transition: all 0.3s;">
                            <i class="fa-solid fa-plus-circle"></i> Agregar Nuevo
                        </button>
                    </div>
                    
                    <!-- Area de Filtros: Fondo Adaptativo (Oscuro en dark-mode, Claro en light-mode) -->
                    <div class="filter-buttons" style="display: flex; gap: 12px; padding: 12px 20px; align-items: center; background: var(--bg-secondary); border-radius: 15px; border: 1px solid var(--border-color); box-shadow: 0 10px 25px var(--card-shadow);">
                        <div style="display: flex; gap: 8px; border-right: 1px solid rgba(255,255,255,0.2); padding-right: 15px; margin-right: 5px;">
                            <button id="filter-btn-hab" onclick="window.ProductosController.toggleStatusFilter('true')" 
                                style="padding: 8px 15px; border-radius: 20px; border: 2px solid #36498f; background: #36498f; color: white; cursor: pointer; font-weight: 600; transition: all 0.3s; font-size: 0.9rem;">
                                <i class="fa-solid fa-check-circle"></i> Habilitados
                            </button>
                            <button id="filter-btn-inhab" onclick="window.ProductosController.toggleStatusFilter('false')" 
                                style="padding: 8px 15px; border-radius: 20px; border: 2px solid #dc3545; background: rgba(0,0,0,0.05); color: #dc3545; cursor: pointer; font-weight: 600; transition: all 0.3s; font-size: 0.9rem;">
                                <i class="fa-solid fa-ban"></i> Inhabilitados
                            </button>
                        </div>

                        <button id="filter-btn-instrumento" onclick="window.ProductosController.toggleCategoryFilter('instrumento')" 
                            style="padding: 8px 20px; border-radius: 20px; border: 2px solid #36498f; background: rgba(0,0,0,0.05); color: #36498f; cursor: pointer; font-weight: 600; transition: all 0.3s; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-tooth"></i> Instrumentos
                        </button>
                        <button id="filter-btn-kit" onclick="window.ProductosController.toggleCategoryFilter('kit')" 
                            style="padding: 8px 20px; border-radius: 20px; border: 2px solid #087d4e; background: rgba(0,0,0,0.05); color: #087d4e; cursor: pointer; font-weight: 600; transition: all 0.3s; display: flex; align-items: center; gap: 8px;">
                            <i class="fa-solid fa-kit-medical"></i> Kits
                        </button>
                        <span id="active-filter-label" style="margin-left: auto; color: #999; font-size: 0.9rem; align-self: center; display: none;">
                            Filtrando por: <strong id="current-filter-name" style="color: #00e676;">Ninguno</strong>
                            <i class="fa-solid fa-circle-xmark" style="cursor: pointer; margin-left: 8px; color: #ff4d4d;" onclick="window.ProductosController.toggleCategoryFilter(null)"></i>
                        </span>
                    </div>
                </div>

                <div id="productos-grid-container" style="flex: 1; overflow-y: auto; padding-right: 5px;">
                    <div id="productos-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 25px; padding-bottom: 30px; transition: opacity 0.3s ease-in-out;">
                        <div style="text-align:center; padding:50px; grid-column: 1 / -1;">
                            <i class="fas fa-spinner fa-spin fa-3x" style="color: var(--welcome-blue);"></i>
                            <p style="margin-top:15px; color: var(--text-muted);">Cargando inventario...</p>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Suscribir evento de búsqueda al campo de texto
        const searchInput = document.getElementById('search-productos');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => this.filterData(e.target.value));
            searchInput.focus();
        }

        // Cargar datos iniciales
        await this.fetchAndRender();
    },

    /**
     * MÉTODO: toggleStatusFilter
     * PROPÓSITO: Alterna entre productos habilitados e inhabilitados (recicladora).
     * PARÁMETRO: 'true' para Activos, 'false' para Inactivos.
     */
    toggleStatusFilter: function(estado) {
        this.state.currentStatusFilter = estado;
        // Reset de filtros secundarios para evitar confusiones de datos
        this.state.currentCategoryFilter = null;
        const searchInput = document.getElementById('search-productos');
        if (searchInput) searchInput.value = '';

        // Reset visual de botones de categoría
        const btnInstr = document.getElementById('filter-btn-instrumento');
        const btnKit = document.getElementById('filter-btn-kit');
        const label = document.getElementById('active-filter-label');
        if (btnInstr) { btnInstr.style.background = 'rgba(255,255,255,0.05)'; btnInstr.style.color = '#36498f'; btnInstr.style.borderColor = '#36498f'; }
        if (btnKit) { btnKit.style.background = 'rgba(255,255,255,0.05)'; btnKit.style.color = '#087d4e'; btnKit.style.borderColor = '#087d4e'; }
        if (label) label.style.display = 'none';

        // Actualización de estilos de botones de estado
        const btnHab = document.getElementById('filter-btn-hab');
        const btnInhab = document.getElementById('filter-btn-inhab');
        const isDark = document.body.classList.contains('dark-mode');
        const inactiveBg = isDark ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.05)';

        if (estado === 'true') {
            if (btnHab) { btnHab.style.background = '#36498f'; btnHab.style.color = 'white'; }
            if (btnInhab) { btnInhab.style.background = inactiveBg; btnInhab.style.color = '#dc3545'; btnInhab.style.borderColor = '#dc3545'; }
        } else {
            if (btnInhab) { btnInhab.style.background = '#dc3545'; btnInhab.style.color = 'white'; }
            if (btnHab) { btnHab.style.background = inactiveBg; btnHab.style.color = '#36498f'; btnHab.style.borderColor = '#36498f'; }
        }

        this.fetchAndRender(); // Recarga atómica
    },

    /**
     * MÉTODO: toggleCategoryFilter
     * PROPÓSITO: Sub-filtro para ver solo Instrumentos o solo Kits.
     */
    toggleCategoryFilter: function(category) {
        const btnInstr = document.getElementById('filter-btn-instrumento');
        const btnKit = document.getElementById('filter-btn-kit');
        const label = document.getElementById('active-filter-label');
        const filterName = document.getElementById('current-filter-name');
        
        if (this.state.currentCategoryFilter === category || category === null) {
            this.state.currentCategoryFilter = null;
            if (btnInstr) { btnInstr.style.background = 'rgba(255,255,255,0.05)'; btnInstr.style.color = '#36498f'; }
            if (btnKit) { btnKit.style.background = 'rgba(255,255,255,0.05)'; btnKit.style.color = '#087d4e'; }
            if (label) label.style.display = 'none';
        } else {
            this.state.currentCategoryFilter = category;
            if (category === 'instrumento') {
                if (btnInstr) { btnInstr.style.background = '#36498f'; btnInstr.style.color = 'white'; }
                if (btnKit) { btnKit.style.background = 'rgba(255,255,255,0.05)'; btnKit.style.color = '#087d4e'; }
                if (filterName) filterName.textContent = 'Instrumentos';
            } else {
                if (btnKit) { btnKit.style.background = '#087d4e'; btnKit.style.color = 'white'; }
                if (btnInstr) { btnInstr.style.background = 'rgba(255,255,255,0.05)'; btnInstr.style.color = '#36498f'; }
                if (filterName) filterName.textContent = 'Kits';
            }
            if (label) label.style.display = 'block';
        }
        this.filterData(document.getElementById('search-productos')?.value || '');
    },

    /**
     * MÉTODO: fetchAndRender (Asíncrono)
     * PROPÓSITO: Consulta la API y delega el dibujado de tarjetas.
     * DISPARADOR: Carga inicial o cambio en el filtro de Habilitados/Inhabilitados.
     * LLAMADO A: api_productos_controller.php (vía ApiService)
     */
    fetchAndRender: async function() {
        try {
            // Llamada al controlador PHP específico: api_productos_controller.php
            const response = await window.ApiService.fetchApiGestion('read', `productos&estado=${this.state.currentStatusFilter}`);
            this.state.localData = response.data || [];
            
            // Ordenar alfabéticamente por nombre
            this.state.localData.sort((a, b) => (a.nombre || "").localeCompare(b.nombre || ""));
            
            this.renderCards(this.state.localData);
        } catch (e) {
            console.error(e);
            const grid = document.getElementById('productos-grid');
            if (grid) grid.innerHTML = `<div style="color:red; grid-column:1/-1;">Error de conexión: ${e.message}</div>`;
        }
    },

    /**
     * MÉTODO: renderCards
     * PROPÓSITO: Dibuja las tarjetas de producto en el contenedor GRID.
     */
    renderCards: function(data) {
        const grid = document.getElementById('productos-grid');
        if (!grid) return;
        
        // Efecto de fade suave
        grid.style.opacity = '0';
        
        setTimeout(() => {
            grid.innerHTML = '';

            if (!data || data.length === 0) {
                grid.innerHTML = `<div style="text-align:center; grid-column:1/-1; color: var(--text-muted); padding:40px;">No hay productos para mostrar.</div>`;
                grid.style.opacity = '1';
                return;
            }

            data.forEach(item => {
            const isInactive = item.ind_vivo === false || item.ind_vivo === 'f';
            const card = document.createElement('div');
            card.className = 'producto-card mat-prim-fade' + (isInactive ? ' inactive-card' : '');
            
            const priceFormatted = new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(item.precio || 0);

            card.style.cssText = `
                background: var(--bg-secondary); border-radius: 15px; 
                box-shadow: 0 10px 30px var(--card-shadow); 
                overflow: hidden; border: 1px solid var(--border-color); 
                display: flex; flex-direction: column; transition: all 0.2s;
                ${isInactive ? 'opacity: 0.75; filter: grayscale(0.5);' : ''}
            `;

            card.innerHTML = `
                <div style="height: 180px; overflow: hidden; position: relative; display: flex; align-items: center; justify-content: center; padding: 10px;">
                    <img src="${item.img_url || '../../images/no-image.png'}" style="max-width: 100%; max-height: 100%; object-fit: contain; transition: transform 0.3s;" onmouseover="this.style.transform='scale(1.05)'" onmouseout="this.style.transform='scale(1)'">
                    <div style="position: absolute; bottom: 10px; right: 10px; background: #36498f; color: white; padding: 4px 12px; border-radius: 20px; font-weight: bold; font-size: 0.9rem; box-shadow: 0 2px 8px rgba(0,0,0,0.2);">
                        ${priceFormatted}
                    </div>
                    ${isInactive ? '<div style="position:absolute; top:10px; left:10px; background:#dc3545; color:white; padding:2px 10px; border-radius:10px; font-size:0.7rem; font-weight:bold;">INACTIVO</div>' : ''}
                </div>
                <div style="padding:15px; flex-grow:1; display:flex; flex-direction:column; justify-content:space-between;">
                    <div>
                        <h3 style="margin:0; font-size:1.1rem; color: var(--text-main);">${item.nombre}</h3>
                        <p style="margin:5px 0; color: var(--text-muted); font-size:0.85rem;">Tipo: ${item.tipo}</p>
                        <p style="color: var(--text-muted); font-size:0.8rem; opacity: 0.7;">Ref: ${item.nombre_origen || 'N/A'}</p>
                    </div>
                    <div style="margin-top:15px; display:flex; gap:12px; justify-content:flex-end; border-top:1px solid var(--border-color); padding-top:10px;">
                        ${!isInactive ? `
                            <button onclick="window.ProductosController.openEditModal(${item.id})" style="background:none; border:none; color:#36498f; cursor:pointer; padding: 5px;"><i class="fa-solid fa-pencil"></i></button>
                            <button onclick="window.ProductosController.performDelete(${item.id})" style="background: #dc3545; border: 1px solid #000; color: white; cursor: pointer; width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s;"><i class="fa-solid fa-trash-can" style="font-size: 0.9rem;"></i></button>
                        ` : `
                            <button onclick="window.ProductosController.performRestore(${item.id})" style="background: #28a745; border: 1px solid #000; color: white; cursor: pointer; width: 32px; height: 32px; border-radius: 6px; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 5px rgba(0,0,0,0.2); transition: all 0.2s;"><i class="fa-solid fa-trash-can-arrow-up" style="font-size: 1rem;"></i></button>
                        `}
                    </div>
                </div>
            `;
            grid.appendChild(card);
        });
        
        grid.style.opacity = '1';
        }, 150);
    },

    /**
     * MÉTODO: filterData
     * PROPÓSITO: Aplica filtros de texto y categoría localmente sin recargar de la BD.
     */
    filterData: function(query) {
        const q = query.toLowerCase();
        const filtered = this.state.localData.filter(p => {
            const matchesSearch = p.nombre.toLowerCase().includes(q) || (p.nombre_origen && p.nombre_origen.toLowerCase().includes(q));
            const matchesCategory = !this.state.currentCategoryFilter || p.tipo === this.state.currentCategoryFilter;
            return matchesSearch && matchesCategory;
        });
        this.renderCards(filtered);
    },

    // --- ACCIONES CRUD ---

    openAddModal: function() {
        if (typeof window.mostrarFormulario === 'function') {
            document.getElementById('modalGestion').style.display = 'block';
            window.mostrarFormulario('productos', 'create', null, 'local_productos');
        }
    },

    openEditModal: function(id) {
        const prod = this.state.localData.find(p => p.id == id);
        if (prod && typeof window.mostrarFormulario === 'function') {
            document.getElementById('modalGestion').style.display = 'block';
            window.mostrarFormulario('productos', 'update', prod, 'local_productos');
        }
    },

    performDelete: async function(id) {
        const result = await Swal.fire({
            title: '¿Inhabilitar producto?',
            text: "El producto pasará a la papelera de inactivos.",
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Sí, borrar',
            cancelButtonText: 'Cancelar'
        });

        if (result.isConfirmed) {
            try {
                const response = await window.ApiService.fetchApiGestion('delete', 'productos', null, id);
                if (response.success) {
                    await Swal.fire('Éxito', 'Producto inhabilitado.', 'success');
                    window.location.reload();
                } else throw new Error(response.error);
            } catch (err) {
                Swal.fire('Error', err.message, 'error');
            }
        }
    },

    performRestore: async function(id) {
        const result = await Swal.fire({
            title: '¿Restaurar producto?',
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: '#28a745',
            cancelButtonColor: '#6c757d',
            confirmButtonText: 'Sí, restaurar',
            cancelButtonText: 'Cancelar'
        });

        if (result.isConfirmed) {
            try {
                const response = await window.ApiService.fetchApiGestion('restore', 'productos', null, id);
                if (response.success) {
                    await Swal.fire('Éxito', 'Producto reactivado correctamente.', 'success');
                    window.location.reload();
                } else throw new Error(response.error);
            } catch (err) {
                Swal.fire('Error', err.message, 'error');
            }
        }
    }
};

// --- MANTENIMIENTO DE COMPATIBILIDAD ---
// Sobrescribimos el llamado global para que use la instancia atómica
window.loadProductosView = (container) => window.ProductosController.loadView(container);
