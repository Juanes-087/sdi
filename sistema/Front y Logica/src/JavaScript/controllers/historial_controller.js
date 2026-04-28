// JavaScript/historial_movimientos.js

(function () {
    // Variable para almacenar la data original de movimientos
    let historialCompleto = [];
    let currentVentasFilter = 'all';

    // Inyectar Estilos Específicos para el Historial (Protección por Namespacing)
    if (document.getElementById('kardex-historial-styles')) return;

    const style = document.createElement('style');
    style.id = 'kardex-historial-styles';
    style.innerHTML = `
        .kardex-toolbar {
            display: flex;
            gap: 20px;
            background: var(--bg-secondary);
            padding: 20px;
            border-radius: 12px;
            margin-bottom: 25px;
            box-shadow: 0 10px 30px var(--card-shadow);
            flex-wrap: wrap;
            align-items: flex-end;
            border-left: 5px solid var(--welcome-blue);
            border: 1px solid var(--border-color);
        }
        .kardex-filter-group {
            display: flex;
            flex-direction: column;
            gap: 5px;
            flex: 1;
            min-width: 200px;
        }
        .kardex-filter-group label {
            font-size: 0.85rem;
            font-weight: bold;
            color: var(--text-main);
            text-transform: uppercase;
            opacity: 0.8;
        }
        .kardex-filter-input {
            padding: 10px;
            border: 1px solid var(--border-color);
            border-radius: 8px;
            font-size: 0.95rem;
            outline: none;
            transition: border-color 0.3s;
            background: var(--bg-primary);
            color: var(--text-main);
        }
        .kardex-filter-input:focus {
            border-color: var(--welcome-blue);
        }
        
        .kardex-timeline-scroll {
            flex: 1;
            overflow-y: auto;
            max-height: calc(100vh - 280px);
            padding-right: 15px;
            margin-top: 10px;
        }

        .kardex-timeline-container {
            display: flex;
            flex-direction: column;
            gap: 15px;
            padding: 10px;
            position: relative;
        }
        .kardex-timeline-container::before {
            content: '';
            position: absolute;
            left: 31px; /* Ajustado para alinear con los iconos circularmente */
            top: 20px;
            bottom: 20px;
            width: 2px;
            background: var(--text-muted);
            opacity: 0.3;
            z-index: 0;
        }

        .kardex-card {
            display: flex;
            background: var(--bg-secondary);
            border-radius: 12px;
            padding: 18px;
            box-shadow: 0 10px 30px var(--card-shadow);
            border: 1px solid var(--border-color);
            transition: transform 0.2s, box-shadow 0.2s;
            position: relative;
            z-index: 1;
            margin-left: 20px;
            animation: kardexSlideInUp 0.4s ease-out backwards;
        }
        .kardex-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.1);
        }

        @keyframes kardexFadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }

        @keyframes kardexSlideInRight {
            from { opacity: 0; transform: translateX(30px); }
            to { opacity: 1; transform: translateX(0); }
        }

        .kardex-fade-in { animation: kardexFadeIn 0.5s ease; }
        .kardex-slide-in-right { animation: kardexSlideInRight 0.5s ease; }
        .kardex-slide-in-up { animation: kardexSlideInUp 0.5s ease-out; }

        @keyframes kardexSlideInUp {
            from { opacity: 0; transform: translateY(30px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .kardex-icon {
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 1.5rem;
            flex-shrink: 0;
            margin-right: 20px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }

        .kardex-body {
            flex-grow: 1;
            display: flex;
            flex-direction: column;
            gap: 5px;
            word-break: break-word;
            overflow-wrap: break-word;
            min-width: 0; /* Ensures flex child can shrink below min content */
        }

        .kardex-header {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
            flex-wrap: wrap;
            gap: 10px;
        }
        .kardex-title {
            font-size: 1.15rem;
            font-weight: bold;
            color: var(--text-main);
            margin: 0;
            word-break: break-word;
            overflow-wrap: break-word;
        }
        .kardex-badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.75rem;
            font-weight: bold;
            text-transform: uppercase;
        }

        .kardex-details {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 5px;
        }
        .kardex-detail-item {
            font-size: 0.9rem;
            color: var(--text-muted);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .kardex-detail-item i {
            color: var(--welcome-blue);
            width: 16px;
        }

        .kardex-measure {
            background: var(--bg-primary);
            padding: 6px 12px;
            border-radius: 6px;
            font-weight: bold;
            color: var(--welcome-blue);
            display: inline-block;
            margin-top: 10px;
            font-size: 0.95rem;
            border: 1px solid var(--border-color);
        }

        .kardex-footer {
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px dashed var(--border-color);
            font-size: 0.85rem;
            color: var(--text-main);
            font-style: italic;
            opacity: 0.9;
        }

        /* Tipos de Movimiento (Namespaced) */
        .kardex-type-in { background: #e8f5e9; color: #2e7d32; }
        .kardex-type-out { background: #fff3e0; color: #ef6c00; }
        .kardex-type-adj { background: #e3f2fd; color: #1565c0; }
        .kardex-type-dmg { background: #ffebee; color: #c62828; }

        .kardex-icon-in { background: #087d4e; color: white; }
        .kardex-icon-out { background: #ff9800; color: white; }
        .kardex-icon-adj { background: #2196f3; color: white; }
        .kardex-icon-dmg { background: #f44336; color: white; }
    `;
    document.head.appendChild(style);

    // Función Principal: Cargar la Vista de Selección
    window.loadHistorialView = async function (container) {
        const contentArea = container || document.getElementById('dynamic-view');

        // Limpiar FAB por si venimos de Materia Prima
        const fab = document.getElementById('fab-admin-categorias');
        if (fab) fab.remove();

        contentArea.innerHTML = `
            <div id="historial-root" class="kardex-slide-in-up" style="padding: 20px; padding-top: 30px; min-height: 100vh; background: var(--bg-primary);">
                <div style="margin-bottom:40px; border-bottom:2px solid var(--welcome-blue); padding-bottom:15px;">
                    <h2 style="color: var(--welcome-blue); margin:0; font-family: 'Segoe UI', sans-serif;">
                        <i class="fa-solid fa-clock-rotate-left"></i> Historial de Movimientos
                    </h2>
                    <p style="color: var(--text-main); margin-top:5px; opacity: 0.8;">Seleccione el tipo de historial que desea consultar.</p>
                </div>

                <div id="historial-selection-grid" style="display:grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap:30px;">
                                      <!-- Tarjeta: BODEGA (Materia Prima en espera) -->
                    <div class="card-materia" onclick="loadBodegaView()" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid #868788; position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: #868788; margin-bottom: 15px;">
                            <i class="fa-solid fa-boxes-stacked"></i>
                        </div>
                        <h3 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px;">Bodega Inicial</h3>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Materia prima recién ingresada en espera.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 20%); pointer-events: none;">
                            <i class="fa-solid fa-boxes-stacked"></i>
                        </div>
                    </div>

                    <!-- Tarjeta: PRODUCCIÓN (En proceso) -->
                    <div class="card-materia" onclick="loadProduccionView()" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid #087d4e; position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: #087d4e; margin-bottom: 15px;">
                            <i class="fa-solid fa-industry"></i>
                        </div>
                        <h3 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px;">Línea Producción</h3>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Materia prima enviada a preparación de piezas.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 20%); pointer-events: none;">
                            <i class="fa-solid fa-industry"></i>
                        </div>
                    </div>

                    <!-- Tarjeta Principal: Kardex Materia Prima -->
                    <div class="card-materia" onclick="loadKardexTimelineView()" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid var(--welcome-blue); position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: var(--welcome-blue); margin-bottom: 15px;">
                            <i class="fa-solid fa-clipboard-list"></i>
                        </div>
                        <h3 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px;">Kardex Insumos</h3>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Audite entradas, salidas y ajustes de materias primas.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 20%); pointer-events: none;">
                            <i class="fa-solid fa-clipboard-list"></i>
                        </div>
                    </div>

                    <!-- Tarjeta: FABRICACIÓN INSTRUMENTAL -->
                    <div class="card-materia" onclick="loadHistorialInstrumentalView()" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid #f59e0b; position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: #f59e0b; margin-bottom: 15px;">
                            <i class="fa-solid fa-hammer"></i>
                        </div>
                        <h3 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px;">Fabricación Piezas</h3>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Historial de instrumentos elaborados.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 20%); pointer-events: none;">
                            <i class="fa-solid fa-hammer"></i>
                        </div>
                    </div>

                    <!-- Tarjeta: ENSAMBLAJE FINAL -->
                    <div class="card-materia" onclick="loadHistorialProductosView()" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid #8b5cf6; position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: #8b5cf6; margin-bottom: 15px;">
                            <i class="fa-solid fa-cubes"></i>
                        </div>
                        <h3 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px;">Ensamblaje Cajas</h3>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Historial de creación de Kits / Productos caja cerrada.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 20%); pointer-events: none;">
                            <i class="fa-solid fa-cubes"></i>
                        </div>
                    </div>

                    <!-- Tarjeta: VENTAS (NUEVO) -->
                    <div class="card-materia" onclick="loadHistorialVentasDevolucionesView('venta')" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid #10b981; position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: #10b981; margin-bottom: 15px;">
                            <i class="fa-solid fa-cart-shopping"></i>
                        </div>
                        <h2 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px; font-weight:700;">Historial Ventas</h2>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Productos vendidos a clientes.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 15%); pointer-events: none;">
                            <i class="fa-solid fa-cart-shopping"></i>
                        </div>
                    </div>

                    <!-- Tarjeta: DEVOLUCIONES (NUEVO) -->
                    <div class="card-materia" onclick="loadHistorialVentasDevolucionesView('devolucion')" style="
                        background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow);
                        padding: 30px; text-align: center; cursor: pointer; transition: all 0.3s;
                        border-bottom: 5px solid #ef4444; position: relative; overflow: hidden; border-top: 1px solid var(--border-color); border-left: 1px solid var(--border-color); border-right: 1px solid var(--border-color);">
                        <div style="font-size: 3rem; color: #ef4444; margin-bottom: 15px;">
                            <i class="fa-solid fa-arrow-rotate-left"></i>
                        </div>
                        <h2 style="color: var(--text-main); font-size: 1.3rem; margin-bottom: 5px; font-weight:700;">Devoluciones</h2>
                        <p style="color: var(--text-muted); font-size: 0.9rem;">Productos que regresaron a inventario.</p>
                        <div style="position:absolute; bottom:0; right:0; padding:10px; color:rgba(255,255,255,0.05); font-size:4rem; z-index:0; transform: translate(10%, 15%); pointer-events: none;">
                            <i class="fa-solid fa-arrow-rotate-left"></i>
                        </div>
                    </div>      </div>

                </div>
            </div>
        `;
    };

    // Función: Cargar Línea de Tiempo de Kardex
    window.loadKardexTimelineView = async function () {
        const contentArea = document.getElementById('dynamic-view');

        contentArea.innerHTML = `
            <div id="historial-root" class="kardex-slide-in-up" style="padding: 20px; padding-top: 30px; min-height: 100vh; display:flex; flex-direction:column; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid var(--welcome-blue); padding-bottom:10px;">
                    <div style="display:flex; align-items:center; gap:15px;">
                        <button onclick="loadHistorialView()" style="background:linear-gradient(135deg, var(--welcome-blue) 0%, #087d4e 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 40px; height: 40px; border-radius: 50%; box-shadow: 0 4px 10px rgba(0,0,0,0.2); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                        <h2 style="color: var(--welcome-blue); margin:0;"><i class="fa-solid fa-clipboard-list"></i> Kardex de Insumos</h2>
                    </div>
                    <span id="historial-count" style="background: var(--welcome-blue); color: white; padding:5px 15px; border-radius:20px; font-size:0.9rem; font-weight:bold;">Cargando...</span>
                </div>

                <!-- Toolbar de Filtros -->
                <div class="kardex-toolbar">
                    <div class="kardex-filter-group" style="flex:2;">
                        <label>Buscar Materia o Proveedor</label>
                        <input type="text" id="hist-search" class="kardex-filter-input" placeholder="Ej: Alambre, Aceros S.A...">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Mes (Año Actual)</label>
                        <select id="hist-month" class="kardex-filter-input">
                            <option value="">-- Todos los Meses --</option>
                            <option value="0">Enero</option>
                            <option value="1">Febrero</option>
                            <option value="2">Marzo</option>
                            <option value="3">Abril</option>
                            <option value="4">Mayo</option>
                            <option value="5">Junio</option>
                            <option value="6">Julio</option>
                            <option value="7">Agosto</option>
                            <option value="8">Septiembre</option>
                            <option value="9">Octubre</option>
                            <option value="10">Noviembre</option>
                            <option value="11">Diciembre</option>
                        </select>
                    </div>
                    <div class="kardex-filter-group">
                        <label>Desde</label>
                        <input type="date" id="hist-start" class="kardex-filter-input">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Hasta</label>
                        <input type="date" id="hist-end" class="kardex-filter-input">
                    </div>
                </div>

                <!-- Wrapper con SCROLL habilitado -->
                <div class="kardex-timeline-scroll">
                    <div id="historial-timeline" class="kardex-timeline-container">
                        <div style="text-align:center; padding:100px; color:#aaa;">
                            <i class="fas fa-spinner fa-spin fa-4x"></i>
                            <p style="margin-top:20px; font-size:1.2rem;">Recuperando bitácora de movimientos...</p>
                        </div>
                    </div>
                </div>
            </div>
        `;

        // Event Listeners para Filtros
        document.getElementById('hist-search').addEventListener('input', aplicarFiltrosHistorial);
        document.getElementById('hist-month').addEventListener('change', aplicarFiltrosHistorial);
        document.getElementById('hist-start').addEventListener('change', aplicarFiltrosHistorial);
        document.getElementById('hist-end').addEventListener('change', aplicarFiltrosHistorial);

        // Cargar Data
        try {
            const res = await fetch(`../php/api_gestion.php?tipo=listar_historial_kardex&t=${new Date().getTime()}`);
            const result = await res.json();

            if (result.success && Array.isArray(result.data)) {
                // Ordenar explícitamente por fecha descendente (Más nuevos arriba)
                historialCompleto = result.data.sort((a, b) => {
                    const dateA = new Date((a.fecha_movimiento || a.fec_insert || "").replace(" ", "T"));
                    const dateB = new Date((b.fecha_movimiento || b.fec_insert || "").replace(" ", "T"));
                    return dateB - dateA;
                });
                renderHistorialTimeline(historialCompleto);
            } else {
                throw new Error(result.error || "No se pudo cargar el historial.");
            }
        } catch (e) {
            console.error(e);
            const timeline = document.getElementById('historial-timeline');
            if (timeline) {
                timeline.innerHTML = `
                    <div style="text-align:center; padding:50px; color:#c62828;">
                        <i class="fa-solid fa-triangle-exclamation fa-4x"></i>
                        <p style="margin-top:20px;">Error al cargar bitácora: ${e.message}</p>
                    </div>
                `;
            }
        }
    };

    function renderHistorialTimeline(data) {
        const container = document.getElementById('historial-timeline');
        if (!container) return;

        // Limpiar el FAB si existe (por seguridad)
        const fab = document.getElementById('fab-admin-categorias');
        if (fab) fab.remove();

        if (data.length === 0) {
            container.innerHTML = `
                <div style="text-align:center; padding:50px; color:#666;">
                    <i class="fa-solid fa-folder-open fa-3x" style="opacity:0.3; margin-bottom:15px;"></i>
                    <p>No se encontraron movimientos con los filtros seleccionados.</p>
                </div>
            `;
            return;
        }

        const countSpan = document.getElementById('historial-count');
        if (countSpan) {
            countSpan.textContent = `${data.length} Registro${data.length > 1 ? 's' : ''}`;
        }

        container.innerHTML = data.map((mov, index) => {
            const config = getTipoConfig(mov.tipo_movimiento);
            const fechaValida = mov.fecha_movimiento || mov.fec_insert;
            const fechaLegible = formatearFecha(fechaValida);

            // Mapping namespaced classes for badges and icons
            const badgeClass = config.badgeClass.replace('type-', 'kardex-type-');
            const iconClass = config.iconClass.replace('icon-', 'kardex-icon-');

            // Parsing robusto de la observación (Formato DB: "Proveedor: X | Obs: Y")
            let proveedor = "No especificado";
            let observacion = mov.observaciones || "Sin detalles adicionales.";

            const obsStr = mov.observaciones || "";
            if (obsStr.toLowerCase().includes("proveedor:")) {
                // Dividir por | o por saltos de línea comunes
                const parts = obsStr.split(/\||\n/);
                const provPart = parts.find(p => p.toLowerCase().includes("proveedor:"));
                if (provPart) {
                    proveedor = provPart.split(/proveedor:/i)[1].trim();
                }

                // Limpiar la observación del prefijo de proveedor para el cuerpo
                const remainingParts = parts.filter(p => !p.toLowerCase().includes("proveedor:"));
                if (remainingParts.length > 0) {
                    observacion = remainingParts.join(" | ").replace(/obs:/i, "").trim();
                    if (observacion === "") observacion = "Sin observación adicional.";
                }
            } else if (mov.nom_prov) {
                proveedor = mov.nom_prov;
            }


            return `
                <div class="kardex-card" style="animation-delay: ${index * 0.02}s;">
                    <div class="kardex-icon ${iconClass}">
                        <i class="fa-solid ${config.icon}"></i>
                    </div>
                    <div class="kardex-body">
                        <div class="kardex-header">
                            <h3 class="kardex-title">${mov.nom_materia_prima}</h3>
                            <span class="kardex-badge ${badgeClass}">${config.label}</span>
                        </div>
                        
                        <div class="kardex-details">
                            <div class="kardex-detail-item">
                                <i class="fa-solid fa-truck"></i>
                                <span><b>Proveedor:</b> ${proveedor}</span>
                            </div>
                            <div class="kardex-detail-item">
                                <i class="fa-solid fa-calendar-alt"></i>
                                <span>${fechaLegible}</span>
                            </div>
                        </div>

                        <div class="kardex-measure">
                            <i class="fa-solid fa-layer-group"></i> 
                            ${mov.cantidad} x ${mov.valor_medida} ${mov.nom_unidad || 'Unidades'}
                        </div>

                        <div class="kardex-footer" title="${observacion}">
                            <i class="fa-solid fa-quote-left"></i> ${observacion}
                        </div>
                    </div>
                </div>
            `;
        }).join('');
    }

    function aplicarFiltrosHistorial() {
        const searchInput = document.getElementById('hist-search');
        const monthInput = document.getElementById('hist-month');
        const startInput = document.getElementById('hist-start');
        const endInput = document.getElementById('hist-end');

        if (!searchInput || !monthInput) return;

        const search = searchInput.value.toLowerCase();
        const month = monthInput.value;
        const start = startInput.value;
        const end = endInput.value;

        const filtered = historialCompleto.filter(mov => {
            // Filtro Texto (Materia, Proveedor o Obs)
            const matchText = (mov.nom_materia_prima || "").toLowerCase().includes(search) ||
                (mov.nom_prov || "").toLowerCase().includes(search) ||
                (mov.observaciones || "").toLowerCase().includes(search);

            // Determinar fecha de referencia para filtros
            const rawDate = mov.fecha_movimiento || mov.fec_insert || "";
            const safeDateStr = rawDate.replace(" ", "T");
            const dateObj = new Date(safeDateStr);
            const now = new Date();

            // Si la fecha es inválida, no filtrar por tiempo a menos que el filtro esté vacío
            const isInvalidDate = isNaN(dateObj.getTime());

            // Filtro Mes (del año actual)
            let matchMonth = true;
            if (month !== "") {
                matchMonth = !isInvalidDate && (dateObj.getMonth() == parseInt(month) && dateObj.getFullYear() == now.getFullYear());
            }

            // Filtro Rango
            let matchRange = true;
            if (start || end) {
                if (isInvalidDate) {
                    matchRange = false;
                } else {
                    const movTimestamp = dateObj.getTime();
                    if (start) {
                        const startTimestamp = new Date(start + "T00:00:00").getTime();
                        if (movTimestamp < startTimestamp) matchRange = false;
                    }
                    if (end) {
                        const endTimestamp = new Date(end + "T23:59:59").getTime();
                        if (movTimestamp > endTimestamp) matchRange = false;
                    }
                }
            }

            return matchText && matchMonth && matchRange;
        });

        renderHistorialTimeline(filtered);
    }

    function getTipoConfig(tipo) {
        const t = parseInt(tipo);
        switch (t) {
            case 1: return { label: 'Entrada (Compra)', iconClass: 'icon-in', badgeClass: 'type-in', icon: 'fa-cart-plus' };
            case 2: return { label: 'Salida (Consumo)', iconClass: 'icon-out', badgeClass: 'type-out', icon: 'fa-dolly' };
            case 3: return { label: 'Ajuste Stock', iconClass: 'icon-adj', badgeClass: 'type-adj', icon: 'fa-sliders' };
            case 4: return { label: 'Daño / Baja', iconClass: 'icon-dmg', badgeClass: 'type-dmg', icon: 'fa-trash-can' };
            default: return { label: 'Movimiento', iconClass: 'icon-adj', badgeClass: 'type-adj', icon: 'fa-right-left' };
        }
    }

    function formatearFecha(isoString) {
        if (!isoString) return "Fecha desconocida";

        // Fix para PostgreSQL TIMESTAMP strings que a veces fallan en Safari o navegadores estrictos
        // Reemplazar espacio por T para formato ISO estricto si es necesario
        const safeString = isoString.includes(" ") ? isoString.replace(" ", "T") : isoString;
        const date = new Date(safeString);

        if (isNaN(date.getTime())) {
            // Intento de parseo manual si falla el constructor
            return isoString;
        }

        return date.toLocaleDateString('es-ES', {
            day: '2-digit',
            month: 'long',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }
    // Variable para almacenar la data de ventas/devoluciones y poder filtrar
    let historialVentasCompleto = [];

    // --- 3. HISTORIAL DE VENTAS Y DEVOLUCIONES (NUEVO) ---
    window.loadHistorialVentasDevolucionesView = function (filtroInicial = 'all') {
        currentVentasFilter = filtroInicial;
        const contentArea = document.getElementById('dynamic-view');
        const colorTema = filtroInicial === 'devolucion' ? '#ff4d4d' : (filtroInicial === 'venta' ? '#00e676' : 'var(--welcome-blue)');
        const tituloVista = filtroInicial === 'devolucion' ? 'Historial de Devoluciones' : (filtroInicial === 'venta' ? 'Historial de Ventas' : 'Historial Comercial');
        const iconoVista = filtroInicial === 'devolucion' ? 'fa-arrow-rotate-left' : (filtroInicial === 'venta' ? 'fa-cart-shopping' : 'fa-receipt');

        contentArea.innerHTML = `
            <div id="historial-root" class="kardex-slide-in-up" style="padding: 20px; padding-top: 30px; min-height: 100vh; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid ${colorTema}; padding-bottom:10px;">
                    <div style="display:flex; align-items:center; gap:20px;">
                        <button onclick="loadHistorialView()" style="background:linear-gradient(135deg, ${colorTema} 0%, var(--welcome-blue) 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 45px; height: 45px; border-radius: 50%; box-shadow: 0 6px 12px rgba(0,0,0,0.1); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                        <h2 style="color: ${colorTema}; margin:0; font-family: 'Segoe UI', sans-serif;">
                            <i class="fa-solid ${iconoVista}"></i> ${tituloVista}
                        </h2>
                    </div>
                    ${filtroInicial === 'devolucion' ? `
                        <button onclick="loadGestionarDevolucionesView()" style="background:#ef4444; color:white; border:none; padding:10px 20px; border-radius:12px; font-weight:bold; cursor:pointer; font-size:0.95rem; box-shadow: 0 4px 15px rgba(239, 68, 68, 0.3); transition: all 0.3s; display: flex; align-items: center; gap: 8px;" onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 6px 20px rgba(239, 68, 68, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(239, 68, 68, 0.3)'">
                            <i class="fa-solid fa-boxes-packing"></i> Gestionar Productos
                        </button>
                    ` : ''}
                </div>
                
                <!-- Toolbar de Filtros (Profesional) -->
                <div class="kardex-toolbar" style="border-left-color: ${colorTema}; margin-bottom: 20px;">
                    <div class="kardex-filter-group" style="flex:2;">
                        <label>Buscar Producto, N° Factura u Observación</label>
                        <input type="text" id="ventas-search" class="kardex-filter-input" placeholder="Ej: Bisturí, 1025...">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Mes</label>
                        <select id="ventas-month" class="kardex-filter-input">
                            <option value="">-- Todos --</option>
                            <option value="0">Enero</option>
                            <option value="1">Febrero</option>
                            <option value="2">Marzo</option>
                            <option value="3">Abril</option>
                            <option value="4">Mayo</option>
                            <option value="5">Junio</option>
                            <option value="6">Julio</option>
                            <option value="7">Agosto</option>
                            <option value="8">Septiembre</option>
                            <option value="9">Octubre</option>
                            <option value="10">Noviembre</option>
                            <option value="11">Diciembre</option>
                        </select>
                    </div>
                    <div class="kardex-filter-group">
                        <label>Desde</label>
                        <input type="date" id="ventas-start" class="kardex-filter-input">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Hasta</label>
                        <input type="date" id="ventas-end" class="kardex-filter-input">
                    </div>
                </div>

                <div class="table-wrapper" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow); overflow: hidden; border: 1px solid var(--border-color); animation: kardexFadeIn 0.6s ease;">
                    <div class="table-scroll" style="max-height: 55vh; overflow-y: auto; overflow-x: auto;">
                        <table class="data-table" style="width: 100%; border-collapse: separate; border-spacing: 0;">
                            <thead style="position: sticky; top: 0; z-index: 100;">
                                <tr style="text-align: left;">
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Fecha / Hora</th>
                                    <th style="padding: 15px; width: 130px; white-space: nowrap; cursor: pointer; user-select: none; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);" id="ventas-sort-factura" title="Ordenar por N° Factura">
                                        N° Factura <i id="ventas-sort-icon" class="fa-solid fa-sort" style="margin-left:5px; opacity:0.6;"></i>
                                    </th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Producto</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Categoría</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Cant.</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Observaciones</th>
                                    <th style="padding: 15px; text-align: center; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Acciones</th>
                                </tr>
                            </thead>
                            <tbody id="historial-ventas-tbody">
                                <tr><td colspan="7" style="text-align: center; padding: 40px; color: var(--text-muted);">
                                    <i class="fas fa-spinner fa-spin fa-2x"></i><br>Cargando historial comercial...
                                </td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;

        // Asignar eventos de los filtros inmediatamente
        const searchInput = document.getElementById('ventas-search');
        const monthInput = document.getElementById('ventas-month');
        const startInput = document.getElementById('ventas-start');
        const endInput = document.getElementById('ventas-end');
        const sortBtn = document.getElementById('ventas-sort-factura');

        if (searchInput) searchInput.addEventListener('input', aplicarFiltrosVentas);
        if (monthInput) monthInput.addEventListener('change', aplicarFiltrosVentas);
        if (startInput) startInput.addEventListener('change', aplicarFiltrosVentas);
        if (endInput) endInput.addEventListener('change', aplicarFiltrosVentas);
        if (sortBtn) sortBtn.addEventListener('click', toggleSortFactura);

        fetch('../php/api_gestion.php?tipo=listar_historial_ventas_devoluciones&t=' + new Date().getTime())
            .then(res => res.json())
            .then(result => {
                const tbody = document.getElementById('historial-ventas-tbody');
                if (result.success && Array.isArray(result.data)) {
                    historialVentasCompleto = result.data.sort((a, b) => {
                        const dA = new Date((a.fecha_movimiento || "").replace(" ", "T"));
                        const dB = new Date((b.fecha_movimiento || "").replace(" ", "T"));
                        return dB - dA;
                    });

                    // Aplicar filtro inicial si se especificó
                    let dataFiltrada = historialVentasCompleto;
                    if (filtroInicial === 'venta') {
                        dataFiltrada = historialVentasCompleto.filter(item => item.tipo_movimiento == 2);
                    } else if (filtroInicial === 'devolucion') {
                        dataFiltrada = historialVentasCompleto.filter(item => item.tipo_movimiento == 5);
                    }

                    renderTablaVentas(dataFiltrada);
                } else {
                    tbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: #ef4444; padding: 20px;">
                        <i class="fa-solid fa-circle-exclamation"></i> Error: ${result.error || 'No se pudo cargar'}
                    </td></tr>`;
                }
            })
            .catch(err => {
                console.error(err);
                if (document.getElementById('historial-ventas-tbody')) {
                    document.getElementById('historial-ventas-tbody').innerHTML = '<tr><td colspan="7" style="text-align: center; color: #ef4444; padding: 20px;">Error de comunicación con el servidor</td></tr>';
                }
            });
    };

    function renderTablaVentas(data) {
        const tbody = document.getElementById('historial-ventas-tbody');
        if (!tbody) return;

        if (data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" style="text-align: center; padding:40px; color:#666;"><i class="fa-solid fa-search fa-2x" style="opacity:0.3; margin-bottom:10px;"></i><br>No se encontraron registros de ventas o devoluciones con los filtros aplicados.</td></tr>';
            return;
        }

        tbody.innerHTML = data.map(item => {
            const isVenta = item.tipo_movimiento == 2;
            const badgeColor = isVenta ? '#10b981' : (item.estado_gestion === 'PENDIENTE' ? '#f59e0b' : '#ef4444');
            const badgeText = isVenta ? 'VENTA' : 'DEVOLUCIÓN';
            
            // Lógica de impacto en stock
            let stockImpactPrefix = isVenta ? '-' : '+';
            let stockText = isVenta ? 'Salida' : 'Ingreso';
            let impactColor = isVenta ? '#ef4444' : '#10b981';

            if (!isVenta) {
                if (item.estado_gestion === 'PENDIENTE') {
                    stockImpactPrefix = '+0';
                    stockText = 'Pendiente';
                    impactColor = '#f59e0b';
                } else if (item.observaciones && item.observaciones.includes('Desechado')) {
                    stockImpactPrefix = '+0';
                    stockText = 'Desecho';
                    impactColor = '#6b7280';
                }
            }

            let msgObs = item.observaciones || 'Sin observaciones';
            const plusIdx = msgObs.indexOf(' + ');
            if (plusIdx !== -1) {
                msgObs = msgObs.substring(plusIdx + 3).trim();
            } else if (/^Factura #\d+$/.test(msgObs.trim())) {
                msgObs = 'Sin mensaje añadido';
            }

            return `
                <tr style="border-bottom: 1px solid var(--border-color); transition: background 0.2s; color: var(--text-main);" onmouseover="this.style.background='var(--bg-primary)'" onmouseout="this.style.background='transparent'">
                    <td style="padding: 15px;">
                        <div style="font-size: 0.85rem; color: var(--text-muted); font-weight: 500;">
                            <i class="fa-regular fa-clock"></i> ${item.fecha_movimiento || 'Sin fecha'}
                        </div>
                    </td>
                    <td style="padding: 15px; white-space: nowrap;">
                        <span style="font-weight: bold; color: #d97706; font-size: 1.05rem;">
                            <i class="fa-solid fa-hashtag" style="font-size:0.8rem;"></i> ${item.id_factura_ref || '---'}
                        </span>
                    </td>
                    <td style="padding: 15px;">
                        <div style="font-weight: 700; color: var(--welcome-blue); font-size: 1.05rem;">${item.producto_nombre || 'Sin nombre'}</div>
                        <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 2px;">ID: ${item.id_instrumento || item.id_kit || '---'}</div>
                    </td>
                    <td style="padding: 15px;">
                        <div style="display: flex; flex-direction: column; gap: 4px;">
                            <span style="font-weight:600; font-size:0.85rem; color: var(--text-main);">${item.producto_tipo}</span>
                            <div style="display: flex; align-items: center; gap: 6px;">
                                <div style="width: 8px; height: 8px; border-radius: 50%; background: ${badgeColor};"></div>
                                <span style="color: ${badgeColor}; font-size: 0.75rem; font-weight: 800; letter-spacing: 0.5px;">${badgeText}</span>
                            </div>
                            ${item.estado_gestion === 'PENDIENTE' ? `
                                <div style="display: inline-block; background: #fef3c7; color: #92400e; padding: 2px 8px; border-radius: 10px; font-size: 0.65rem; font-weight: 700; margin-top: 4px; border: 1px solid #f59e0b; text-align:center;">
                                    <i class="fa-solid fa-hourglass-half"></i> PENDIENTE
                                </div>
                            ` : ''}
                        </div>
                    </td>
                    <td style="padding: 15px; text-align: center;">
                        <strong style="font-size: 1.15rem; color: ${impactColor};">${stockImpactPrefix}${Math.abs(item.cantidad)}</strong>
                        <div style="font-size: 0.7rem; color: var(--text-muted);">${stockText}</div>
                    </td>
                    <td style="padding: 15px;">
                        <div style="font-size: 0.9rem; color: var(--text-main); background: var(--bg-primary); padding: 10px; border-radius: 8px; font-style: italic; border: 1px solid var(--border-color);">
                            ${msgObs}
                        </div>
                    </td>
                    <td style="padding: 15px; text-align: center;">
                        ${item.id_factura_ref ? `
                            <button onclick="window.open('../php/imprimir_factura.php?id=${item.id_factura_ref}', '_blank')" 
                                    class="btn-action-view" 
                                    title="Ver Factura"
                                    style="background: #087d4e; color: white; border: none; padding: 8px 12px; border-radius: 6px; cursor: pointer; transition: all 0.2s; font-size: 0.85rem;">
                                <i class="fa-solid fa-file-invoice"></i> Ver Factura
                            </button>
                        ` : '<span style="color:#aaa; font-size:0.8rem;">---</span>'}
                    </td>
                </tr>
            `;
        }).join('');
    }

    let ventasSortAsc = false;
    function toggleSortFactura() {
        ventasSortAsc = !ventasSortAsc;
        const icon = document.getElementById('ventas-sort-icon');
        if (icon) {
            icon.className = ventasSortAsc ? 'fa-solid fa-sort-up' : 'fa-solid fa-sort-down';
            icon.style.opacity = '1';
        }

        historialVentasCompleto.sort((a, b) => {
            const numA = parseInt(a.id_factura_ref) || 0;
            const numB = parseInt(b.id_factura_ref) || 0;
            return ventasSortAsc ? (numA - numB) : (numB - numA);
        });

        // Re-aplicar filtros para re-renderizar la tabla manteniendo la búsqueda actual
        aplicarFiltrosVentas();
    }

    function aplicarFiltrosVentas() {
        const searchInput = document.getElementById('ventas-search');
        const monthInput = document.getElementById('ventas-month');
        const startInput = document.getElementById('ventas-start');
        const endInput = document.getElementById('ventas-end');

        if (!searchInput) return;

        const search = searchInput.value.toLowerCase();
        const month = monthInput.value;
        const start = startInput.value;
        const end = endInput.value;

        const filtered = historialVentasCompleto.filter(item => {
            // Filtro por tipo de movimiento (Venta = 2, Devolución = 5)
            if (currentVentasFilter === 'venta' && item.tipo_movimiento != 2) return false;
            if (currentVentasFilter === 'devolucion' && item.tipo_movimiento != 5) return false;

            const matchText = (item.producto_nombre || "").toLowerCase().includes(search) ||
                (item.observaciones || "").toLowerCase().includes(search) ||
                (item.id_factura_ref || "").toLowerCase().includes(search);

            const rawDate = item.fecha_movimiento || "";
            const safeDateStr = rawDate.replace(" ", "T");
            const dateObj = new Date(safeDateStr);
            const now = new Date();
            const isInvalidDate = isNaN(dateObj.getTime());

            let matchMonth = true;
            if (month !== "") {
                matchMonth = !isInvalidDate && (dateObj.getMonth() == parseInt(month) && dateObj.getFullYear() == now.getFullYear());
            }

            let matchRange = true;
            if (start || end) {
                if (isInvalidDate) {
                    matchRange = false;
                } else {
                    const ts = dateObj.getTime();
                    if (start) {
                        const startTimestamp = new Date(start + "T00:00:00").getTime();
                        if (ts < startTimestamp) matchRange = false;
                    }
                    if (end) {
                        const endTimestamp = new Date(end + "T23:59:59").getTime();
                        if (ts > endTimestamp) matchRange = false;
                    }
                }
            }

            return matchText && matchMonth && matchRange;
        });

        renderTablaVentas(filtered);
    }


    // --- 4. HISTORIAL DE FABRICACIÓN (INSTRUMENTAL) ---
    window.loadHistorialInstrumentalView = function () {
        const contentArea = document.getElementById('dynamic-view');
        contentArea.innerHTML = `
            <div class="kardex-slide-in-up" style="padding: 20px; padding-top: 30px; min-height: 100vh; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid #f59e0b; padding-bottom:10px;">
                    <div style="display:flex; align-items:center; gap:15px;">
                        <button onclick="loadHistorialView()" style="background:linear-gradient(135deg, #f59e0b 0%, #b45309 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 40px; height: 40px; border-radius: 50%; box-shadow: 0 4px 10px rgba(0,0,0,0.2); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                        <h2 style="color: #f59e0b; margin:0;"><i class="fa-solid fa-hammer"></i> Historial de Fabricación (Instrumental)</h2>
                    </div>
                </div>

                <!-- Toolbar de Filtros -->
                <div class="kardex-toolbar" style="border-left-color: #f59e0b; margin-bottom: 20px;">
                    <div class="kardex-filter-group" style="flex:2;">
                        <label>Buscar Instrumento, Lote u Observación</label>
                        <input type="text" id="fab-search" class="kardex-filter-input" placeholder="Ej: Pinza, L-2025...">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Mes</label>
                        <select id="fab-month" class="kardex-filter-input">
                            <option value="">-- Todos --</option>
                            <option value="0">Enero</option>
                            <option value="1">Febrero</option>
                            <option value="2">Marzo</option>
                            <option value="3">Abril</option>
                            <option value="4">Mayo</option>
                            <option value="5">Junio</option>
                            <option value="6">Julio</option>
                            <option value="7">Agosto</option>
                            <option value="8">Septiembre</option>
                            <option value="9">Octubre</option>
                            <option value="10">Noviembre</option>
                            <option value="11">Diciembre</option>
                        </select>
                    </div>
                    <div class="kardex-filter-group">
                        <label>Desde</label>
                        <input type="date" id="fab-start" class="kardex-filter-input">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Hasta</label>
                        <input type="date" id="fab-end" class="kardex-filter-input">
                    </div>
                </div>

                <div class="table-wrapper" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow); overflow: hidden; border: 1px solid var(--border-color); animation: kardexFadeIn 0.6s ease;">
                    <div class="table-scroll" style="max-height: 55vh; overflow-y: auto; overflow-x: auto;">
                        <table class="data-table" style="width: 100%; border-collapse: separate; border-spacing: 0;">
                            <thead style="position: sticky; top: 0; z-index: 100;">
                                <tr style="text-align: left;">
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Fecha de Fabricación</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Instrumento</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Especialización</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Detalle Lote / Registro</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Unidades Fabricadas</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Observaciones</th>
                                </tr>
                            </thead>
                            <tbody id="historial-instrumento-tbody">
                                <tr><td colspan="6" style="text-align: center; padding: 30px;">Cargando historial...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;

        fetch('../php/controllers/api_bodega_produccion.php?action=get_kardex_instrumentos')
            .then(response => response.json())
            .then(data => {
                const tbody = document.getElementById('historial-instrumento-tbody');
                if (data.status === 'success') {
                    rawFabData = data.data;
                    renderFilasFabricacion(rawFabData);
                } else {
                    const tbody = document.getElementById('historial-instrumento-tbody');
                    if (tbody) tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: red;">Error: ${data.message}</td></tr>`;
                }
            })
            .then(() => {
                // Asignar eventos de filtros
                document.getElementById('fab-search').addEventListener('input', filtrarTablaFabricacion);
                document.getElementById('fab-month').addEventListener('change', filtrarTablaFabricacion);
                document.getElementById('fab-start').addEventListener('change', filtrarTablaFabricacion);
                document.getElementById('fab-end').addEventListener('change', filtrarTablaFabricacion);
            })
            .catch(err => {
                const tbody = document.getElementById('historial-instrumento-tbody');
                if (tbody) tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: red;">Error de conexión.</td></tr>`;
                console.error(err);
            });
    };

    // --- 5. HISTORIAL DE ENSAMBLAJE (KITS) ---
    window.loadHistorialProductosView = function () {
        const contentArea = document.getElementById('dynamic-view');
        contentArea.innerHTML = `
            <div class="kardex-slide-in-up" style="padding: 20px; padding-top: 30px; min-height: 100vh; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid #8b5cf6; padding-bottom:10px;">
                    <div style="display:flex; align-items:center; gap:15px;">
                        <button onclick="loadHistorialView()" style="background:linear-gradient(135deg, #8b5cf6 0%, #5b21b6 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 40px; height: 40px; border-radius: 50%; box-shadow: 0 4px 10px rgba(0,0,0,0.2); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                        <h2 style="color: #8b5cf6; margin:0;"><i class="fa-solid fa-cubes"></i> Historial de Ensamblaje / Empaque de Kits</h2>
                    </div>
                </div>

                <!-- Toolbar de Filtros -->
                <div class="kardex-toolbar" style="border-left-color: #8b5cf6; margin-bottom: 20px;">
                    <div class="kardex-filter-group" style="flex:2;">
                        <label>Buscar Kit u Observación</label>
                        <input type="text" id="ens-search" class="kardex-filter-input" placeholder="Ej: Kit Cirugía, Empaque...">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Mes</label>
                        <select id="ens-month" class="kardex-filter-input">
                            <option value="">-- Todos --</option>
                            <option value="0">Enero</option>
                            <option value="1">Febrero</option>
                            <option value="2">Marzo</option>
                            <option value="3">Abril</option>
                            <option value="4">Mayo</option>
                            <option value="5">Junio</option>
                            <option value="6">Julio</option>
                            <option value="7">Agosto</option>
                            <option value="8">Septiembre</option>
                            <option value="9">Octubre</option>
                            <option value="10">Noviembre</option>
                            <option value="11">Diciembre</option>
                        </select>
                    </div>
                    <div class="kardex-filter-group">
                        <label>Desde</label>
                        <input type="date" id="ens-start" class="kardex-filter-input">
                    </div>
                    <div class="kardex-filter-group">
                        <label>Hasta</label>
                        <input type="date" id="ens-end" class="kardex-filter-input">
                    </div>
                </div>

                <div class="table-wrapper" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow); overflow: hidden; border: 1px solid var(--border-color); animation: kardexFadeIn 0.6s ease;">
                    <div class="table-scroll" style="max-height: 55vh; overflow-y: auto; overflow-x: auto;">
                        <table class="data-table" style="width: 100%; border-collapse: separate; border-spacing: 0;">
                            <thead style="position: sticky; top: 0; z-index: 100;">
                                <tr style="text-align: left;">
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Fecha de Ensamblaje</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Kit Finalizado</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Especialización Requerida</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Cajas Preparadas</th>
                                    <th style="padding: 15px; background: #fff; color: #000; position: sticky; top: 0; z-index: 101; border-bottom: 2px solid rgba(0,0,0,0.1);">Observaciones</th>
                                </tr>
                            </thead>
                            <tbody id="historial-kits-tbody">
                                <tr><td colspan="5" style="text-align: center; padding: 30px;">Cargando historial de empaque...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;

        fetch('../php/controllers/api_bodega_produccion.php?action=get_kardex_kits')
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    rawEnsamblajeData = data.data;
                    renderFilasEnsamblaje(rawEnsamblajeData);
                } else {
                    const tbody = document.getElementById('historial-kits-tbody');
                    if (tbody) tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: red;">Error: ${data.message}</td></tr>`;
                }
            })
            .then(() => {
                // Asignar eventos de filtros
                document.getElementById('ens-search').addEventListener('input', () => filtrarTablaEnsamblaje(rawEnsamblajeData));
                document.getElementById('ens-month').addEventListener('change', () => filtrarTablaEnsamblaje(rawEnsamblajeData));
                document.getElementById('ens-start').addEventListener('change', () => filtrarTablaEnsamblaje(rawEnsamblajeData));
                document.getElementById('ens-end').addEventListener('change', () => filtrarTablaEnsamblaje(rawEnsamblajeData));
            })
            .catch(err => {
                const tbody = document.getElementById('historial-kits-tbody');
                if (tbody) tbody.innerHTML = `<tr><td colspan="5" style="text-align: center; color: red;">Error de conexión.</td></tr>`;
                console.error(err);
            });
    };

    let rawFabData = [];
    let rawEnsamblajeData = [];

    function renderFilasFabricacion(data) {
        const tbody = document.getElementById('historial-instrumento-tbody');
        if (!tbody) return;
        if (data.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="6" style="text-align:center; padding:80px 20px; color:var(--text-muted);">
                        <div style="font-size: 3.5rem; opacity: 0.2; margin-bottom: 20px;">
                            <i class="fa-solid fa-folder-open"></i>
                        </div>
                        <div style="font-size: 1.1rem; font-weight: 500;">No se encontraron registros de fabricación</div>
                        <div style="font-size: 0.9rem; opacity: 0.7; margin-top: 5px;">Intente ajustar los filtros de búsqueda o fechas.</div>
                    </td>
                </tr>
            `;
            return;
        }

        let html = '';
        data.forEach(item => {
            let imgTag = '';
            if (item.img_url && item.img_url.trim() !== '') {
                let finalUrl = item.img_url.startsWith('.') ? item.img_url : '..' + item.img_url;
                imgTag = `<img src="${finalUrl}" style="width: 30px; height: 30px; border-radius: 4px; object-fit: cover;" onerror="this.style.display='none'">`;
            } else {
                imgTag = `<div style="width: 30px; height: 30px; border-radius: 4px; background: #eee; display:flex; align-items:center; justify-content:center;"><i class="fa-solid fa-wrench" style="font-size:12px; color:#aaa;"></i></div>`;
            }

            html += `
                <tr style="color: var(--text-main); border-bottom: 1px solid var(--border-color); transition: background 0.2s;" onmouseover="this.style.background='var(--bg-primary)'" onmouseout="this.style.background='transparent'">
                    <td style="padding: 15px;"><span style="color: var(--text-muted); font-size: 0.9em; font-weight: 500;"><i class="fa-regular fa-calendar"></i> ${item.fecha_movimiento || 'N/D'}</span></td>
                    <td style="padding: 15px;">
                        <div style="display: flex; align-items: center; gap: 12px; font-weight: 700; color: #d97706;">
                            ${imgTag}
                            ${item.nom_instrumento || 'Sin nombre'}
                        </div>
                    </td>
                    <td style="padding: 15px; color: var(--text-main); font-weight: 500;">${item.especializacion || 'General'}</td>
                    <td style="padding: 15px;">
                        <div style="font-size: 0.9em; margin-bottom: 2px;"><span style="color: var(--text-muted); font-weight: 600;">Lote:</span> <span style="color: var(--text-main);">${item.lote || '-'}</span></div>
                        <div style="font-size: 0.8em; color: var(--text-muted); opacity: 0.8;"><span style="font-weight: 600;">INVIMA:</span> ${item.registro_invima || '-'}</div>
                    </td>
                    <td style="padding: 15px;"><strong style="color: #087d4e; font-size: 1.15em;">+${item.cantidad || 0}</strong> <span style="font-size: 0.8em; color: var(--text-muted);">Unds.</span></td>
                    <td style="padding: 15px; color: var(--text-main); font-style: italic; font-size: 0.9em; opacity: 0.9; max-width: 200px;">
                        <div style="background: var(--bg-primary); padding: 8px; border-radius: 6px; border: 1px solid var(--border-color);">${item.observaciones || '---'}</div>
                    </td>
                </tr>
            `;
        });
        tbody.innerHTML = html;
    }

    function filtrarTablaFabricacion() {
        const search = document.getElementById('fab-search').value.toLowerCase();
        const month = document.getElementById('fab-month').value;
        const start = document.getElementById('fab-start').value;
        const end = document.getElementById('fab-end').value;

        const filtered = rawFabData.filter(item => {
            const matchText = (item.nom_instrumento || "").toLowerCase().includes(search) ||
                (item.lote || "").toLowerCase().includes(search) ||
                (item.observaciones || "").toLowerCase().includes(search);

            const dateObj = new Date((item.fecha_movimiento || "").replace(" ", "T"));
            const isInvalidDate = isNaN(dateObj.getTime());

            let matchMonth = true;
            if (month !== "") {
                matchMonth = !isInvalidDate && (dateObj.getMonth() == parseInt(month));
            }

            let matchRange = true;
            if (start || end) {
                if (isInvalidDate) matchRange = false;
                else {
                    const ts = dateObj.getTime();
                    if (start && ts < new Date(start + "T00:00:00").getTime()) matchRange = false;
                    if (end && ts > new Date(end + "T23:59:59").getTime()) matchRange = false;
                }
            }
            return matchText && matchMonth && matchRange;
        });
        renderFilasFabricacion(filtered);
    }

    function renderFilasEnsamblaje(data) {
        const tbody = document.getElementById('historial-kits-tbody');
        if (!tbody) return;
        if (data.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5" style="text-align:center; padding:80px 20px; color:var(--text-muted);">
                        <div style="font-size: 3.5rem; opacity: 0.2; margin-bottom: 20px;">
                            <i class="fa-solid fa-box-open"></i>
                        </div>
                        <div style="font-size: 1.1rem; font-weight: 500;">No hay historial de ensamblaje en este periodo</div>
                        <div style="font-size: 0.9rem; opacity: 0.7; margin-top: 5px;">Asegúrese de haber completado procesos de empaque en Producción.</div>
                    </td>
                </tr>
            `;
            return;
        }

        let html = '';
        data.forEach(item => {
            let imgTag = '';
            if (item.img_url && item.img_url.trim() !== '') {
                let finalUrl = item.img_url.startsWith('.') ? item.img_url : '..' + item.img_url;
                imgTag = `<img src="${finalUrl}" style="width: 30px; height: 30px; border-radius: 4px; object-fit: cover;" onerror="this.style.display='none'">`;
            } else {
                imgTag = `<div style="width: 30px; height: 30px; border-radius: 4px; background: #eee; display:flex; align-items:center; justify-content:center;"><i class="fa-solid fa-box-open" style="font-size:12px; color:#aaa;"></i></div>`;
            }

            html += `
                <tr style="color: var(--text-main); border-bottom: 1px solid var(--border-color); transition: background 0.2s;" onmouseover="this.style.background='var(--bg-primary)'" onmouseout="this.style.background='transparent'">
                    <td style="padding: 15px;"><span style="color: var(--text-muted); font-size: 0.9em; font-weight: 500;"><i class="fa-regular fa-clock"></i> ${item.fecha_movimiento || 'N/D'}</span></td>
                    <td style="padding: 15px;">
                        <div style="display: flex; align-items: center; gap: 12px; font-weight: 700; color: #8b5cf6;">
                            ${imgTag}
                            ${item.nom_kit || 'Sin nombre'}
                        </div>
                    </td>
                    <td style="padding: 15px; color: var(--text-main); font-weight: 500;">${item.especializacion || 'General'}</td>
                    <td style="padding: 15px;"><strong style="color: #5b21b6; font-size: 1.15em;">+${item.cantidad || 0}</strong> <span style="font-size: 0.85em; color: var(--text-muted);">Kits</span></td>
                    <td style="padding: 15px; color: var(--text-main); font-style: italic; font-size: 0.9em; opacity: 0.9; max-width: 200px;">
                        <div style="background: var(--bg-primary); padding: 8px; border-radius: 6px; border: 1px solid var(--border-color);">${item.observaciones || '---'}</div>
                    </td>
                </tr>
            `;
        });
        tbody.innerHTML = html;
    }

    function filtrarTablaEnsamblaje() {
        const search = document.getElementById('ens-search').value.toLowerCase();
        const month = document.getElementById('ens-month').value;
        const start = document.getElementById('ens-start').value;
        const end = document.getElementById('ens-end').value;

        const filtered = rawEnsamblajeData.filter(item => {
            const matchText = (item.nom_kit || "").toLowerCase().includes(search) ||
                (item.observaciones || "").toLowerCase().includes(search);

            const dateObj = new Date((item.fecha_movimiento || "").replace(" ", "T"));
            const isInvalidDate = isNaN(dateObj.getTime());

            let matchMonth = true;
            if (month !== "") {
                matchMonth = !isInvalidDate && (dateObj.getMonth() == parseInt(month));
            }

            let matchRange = true;
            if (start || end) {
                if (isInvalidDate) matchRange = false;
                else {
                    const ts = dateObj.getTime();
                    if (start && ts < new Date(start + "T00:00:00").getTime()) matchRange = false;
                    if (end && ts > new Date(end + "T23:59:59").getTime()) matchRange = false;
                }
            }
            return matchText && matchMonth && matchRange;
        });
        renderFilasEnsamblaje(filtered);
    }

    // --- 6. GESTIÓN DE PRODUCTOS PENDIENTES (DEVOLUCIONES) ---
    window.loadGestionarDevolucionesView = async function () {
        const contentArea = document.getElementById('dynamic-view');
        
        contentArea.innerHTML = `
            <div id="gestion-root" class="kardex-slide-in-up" style="padding: 20px; padding-top: 30px; min-height: 100vh; background: var(--bg-primary);">
                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid #ef4444; padding-bottom:10px;">
                    <div style="display:flex; align-items:center; gap:20px;">
                        <button onclick="loadHistorialVentasDevolucionesView('devolucion')" style="background:linear-gradient(135deg, #ef4444 0%, var(--welcome-blue) 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 45px; height: 45px; border-radius: 50%; box-shadow: 0 6px 12px rgba(0,0,0,0.1); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                        <h2 style="color: #ef4444; margin:0; font-family: 'Segoe UI', sans-serif;">
                            <i class="fa-solid fa-boxes-packing"></i> Gestión de Productos Pendientes
                        </h2>
                    </div>
                </div>

                <div class="table-wrapper" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow); overflow: hidden; border: 1px solid var(--border-color);">
                    <div class="table-scroll" style="max-height: 65vh; overflow-y: auto;">
                        <table class="data-table" style="width: 100%; border-collapse: separate; border-spacing: 0;">
                            <thead>
                                <tr style="text-align: left; background: #fff;">
                                    <th style="padding: 15px; border-bottom: 2px solid rgba(0,0,0,0.1); color: #000;">Fecha Dev.</th>
                                    <th style="padding: 15px; border-bottom: 2px solid rgba(0,0,0,0.1); color: #000;">Factura</th>
                                    <th style="padding: 15px; border-bottom: 2px solid rgba(0,0,0,0.1); color: #000;">Producto</th>
                                    <th style="padding: 15px; text-align:center; border-bottom: 2px solid rgba(0,0,0,0.1); color: #000;">Cantidad</th>
                                    <th style="padding: 15px; text-align:center; border-bottom: 2px solid rgba(0,0,0,0.1); color: #000;">Acciones de Resolución</th>
                                </tr>
                            </thead>
                            <tbody id="gestionar-dev-tbody">
                                <tr><td colspan="5" style="text-align: center; padding: 40px; color: var(--text-muted);">
                                    <i class="fas fa-spinner fa-spin fa-2x"></i><br>Consultando pendientes...
                                </td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `;

        try {
            const res = await window.ApiService.fetchApiGestion('read', 'listar_devoluciones_pendientes');
            renderTablaGestionar(res.data || []);
        } catch (e) {
            console.error(e);
            document.getElementById('gestionar-dev-tbody').innerHTML = `<tr><td colspan="5" style="text-align:center; color:red; padding:20px;">Error: ${e.message}</td></tr>`;
        }
    };

    function renderTablaGestionar(data) {
        const tbody = document.getElementById('gestionar-dev-tbody');
        if (!tbody) return;

        if (data.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" style="text-align:center; padding:50px; color:#666;"><i class="fa-solid fa-check-circle fa-3x" style="color:#10b981; opacity:0.5; margin-bottom:15px;"></i><br>¡Todo al día! No hay productos pendientes de revisión.</td></tr>';
            return;
        }

        tbody.innerHTML = data.map(item => `
            <tr style="border-bottom: 1px solid var(--border-color);">
                <td style="padding: 15px; font-size: 0.9rem; color: var(--text-muted);">${item.fecha_devolucion}</td>
                <td style="padding: 15px; font-weight:700; color: #d97706;">#${item.id_factura}</td>
                <td style="padding: 15px;">
                    <div style="display:flex; align-items:center; gap:10px;">
                        <img src="${item.img_url || '../images/placeholder.png'}" style="width:40px; height:40px; border-radius:8px; object-fit:cover; border:1px solid var(--border-color);">
                        <span style="font-weight:600; color: var(--text-main);">${item.nombre_producto}</span>
                    </div>
                </td>
                <td style="padding: 15px; text-align:center;"><strong style="font-size:1.1rem;">${Math.abs(item.cantidad)}</strong></td>
                <td style="padding: 15px; text-align:center;">
                    <div style="display:flex; justify-content:center; gap:10px;">
                        <button onclick="resolverDevolucion(${item.id_devol_reparable}, 2)" 
                                style="background:#10b981; color:white; border:none; padding:8px 15px; border-radius:8px; cursor:pointer; font-weight:600; font-size:0.85rem; display:flex; align-items:center; gap:5px;">
                            <i class="fa-solid fa-wrench"></i> Reparado
                        </button>
                        <button onclick="resolverDevolucion(${item.id_devol_reparable}, 3)" 
                                style="background:#6b7280; color:white; border:none; padding:8px 15px; border-radius:8px; cursor:pointer; font-weight:600; font-size:0.85rem; display:flex; align-items:center; gap:5px;">
                            <i class="fa-solid fa-trash-can"></i> Desechar
                        </button>
                    </div>
                </td>
            </tr>
        `).join('');
    }

    window.resolverDevolucion = async function (id, nuevoEstado) {
        const esReparado = nuevoEstado === 2;
        const confirmResult = await Swal.fire({
            title: esReparado ? '¿Confirmar Reparación?' : '¿Confirmar Desecho?',
            text: esReparado ? 'El producto se reintegrará al stock disponible.' : 'El producto se marcará como desecho definitivo.',
            icon: 'question',
            showCancelButton: true,
            confirmButtonColor: esReparado ? '#10b981' : '#6b7280',
            cancelButtonColor: '#d33',
            confirmButtonText: esReparado ? 'Sí, reintegrar' : 'Sí, desechar',
            cancelButtonText: 'Cancelar'
        });

        if (!confirmResult.isConfirmed) return;

        try {
            // Se pasa 'id' como 4to argumento para que api_gestion.php lo reconozca correctamente
            const res = await window.ApiService.fetchApiGestion('update', 'resolver_devolucion', { id_nuevo_estado: nuevoEstado }, id);
            
            if (res.success || res.result === true || (res.result && res.result.result)) {
                Swal.fire({
                    icon: 'success',
                    title: '¡Logrado!',
                    text: esReparado ? 'Producto reintegrado al stock correctamente.' : 'Producto marcado como desecho.',
                    timer: 2000,
                    showConfirmButton: false
                });
                loadGestionarDevolucionesView(); // Recargar vista de pendientes
            } else {
                throw new Error(res.error || 'No se pudo procesar la resolución.');
            }
        } catch (e) {
            Swal.fire('Error', e.message, 'error');
        }
    };
})();






