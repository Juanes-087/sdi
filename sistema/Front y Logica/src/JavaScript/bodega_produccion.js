/* Funciones para renderizar Bodega y Produccion */

let rawBodegaData = [];
let rawProduccionData = [];

function loadBodegaView(container) {
    if (!container) container = document.getElementById('dynamic-view');
    
    container.innerHTML = `
        <div id="bodega-root" class="mat-prim-slide-up" style="padding: 20px; padding-top: 30px; background: var(--bg-primary); min-height: 100vh;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid var(--welcome-blue); padding-bottom:10px;">
                <div style="display:flex; align-items:center; gap:15px;">
                    <button onclick="loadHistorialView()" style="background:linear-gradient(135deg, var(--welcome-blue) 0%, #087d4e 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 40px; height: 40px; border-radius: 50%; box-shadow: 0 4px 10px rgba(0,0,0,0.2); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                    <h2 style="color: var(--welcome-blue); margin:0;"><i class="fa-solid fa-boxes-stacked"></i> Gestión de Bodega Inicial</h2>
                </div>
            </div>
            
            <!-- Toolbar de Filtros -->
            <div class="kardex-toolbar" style="margin-bottom: 20px; border-left-color: var(--welcome-blue);">
                <div class="kardex-filter-group" style="flex:2;">
                    <label>Buscar Material o Proveedor</label>
                    <input type="text" id="bodega-search" class="kardex-filter-input" placeholder="Ej: Alambre, Aceros S.A...">
                </div>
                <div class="kardex-filter-group">
                    <label>Mes</label>
                    <select id="bodega-month" class="kardex-filter-input">
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
                    <input type="date" id="bodega-start" class="kardex-filter-input">
                </div>
                <div class="kardex-filter-group">
                    <label>Hasta</label>
                    <input type="date" id="bodega-end" class="kardex-filter-input">
                </div>
            </div> <!-- Cierre Toolbar -->
            <div class="table-wrapper" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow); overflow: hidden; border: 1px solid var(--border-color); animation: kardexFadeIn 0.6s ease;">
            <div class="table-scroll" style="max-height: 60vh; overflow-y: auto;">
                <table class="data-table" style="width: 100%; border-collapse: separate; border-spacing: 0;">
                    <thead style="position: sticky; top: 0; z-index: 100;">
                        <tr style="text-align: left;">
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Ingreso</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Material</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Proveedor</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Lote</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Tipo</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Cantidad Disponible</th>
                        </tr>
                    </thead>
                    <tbody id="bodega-tbody">
                        <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 40px;">
                            <i class="fas fa-spinner fa-spin fa-2x"></i><br>Cargando inventario de bodega...
                        </td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    `;

    fetch('../php/controllers/api_bodega_produccion.php?action=get_bodega')
        .then(response => response.json())
        .then(data => {
            if (data.status === 'success') {
                rawBodegaData = data.data;
                renderFilasBodega(rawBodegaData);
            } else {
                document.getElementById('bodega-tbody').innerHTML = `<tr><td colspan="6" style="text-align: center; color: red;">Error: ${data.message}</td></tr>`;
            }
        })
        .then(() => {
            document.getElementById('bodega-search').addEventListener('input', filtrarBodega);
            document.getElementById('bodega-month').addEventListener('change', filtrarBodega);
            document.getElementById('bodega-start').addEventListener('change', filtrarBodega);
            document.getElementById('bodega-end').addEventListener('change', filtrarBodega);
        })
        .catch(err => {
            document.getElementById('bodega-tbody').innerHTML = `<tr><td colspan="6" style="text-align: center; color: red;">Error de conexión.</td></tr>`;
            console.error(err);
        });
}

function renderFilasBodega(data) {
    const tbody = document.getElementById('bodega-tbody');
    if (!tbody) return;
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;">No se encontraron materiales en bodega.</td></tr>';
        return;
    }
    
    let html = '';
    data.forEach(item => {
        let imgTag = '';
        if (item.img_url && item.img_url.trim() !== '') {
            let finalUrl = item.img_url.startsWith('.') ? item.img_url : '..' + item.img_url;
            imgTag = `<img src="${finalUrl}" style="width: 30px; height: 30px; border-radius: 4px; object-fit: cover;" onerror="this.style.display='none'">`;
        } else {
            imgTag = `<div style="width: 30px; height: 30px; border-radius: 4px; background: #eee; display:flex; align-items:center; justify-content:center;"><i class="fa-solid fa-box" style="font-size:12px; color:#aaa;"></i></div>`;
        }

        html += `
            <tr style="color: var(--text-main); border-bottom: 1px solid var(--border-color); transition: background 0.2s;" onmouseover="this.style.background='var(--bg-primary)'" onmouseout="this.style.background='transparent'">
                <td style="padding: 15px;"><span style="color: var(--text-muted); font-size: 0.9em; font-weight: 500;"><i class="fa-regular fa-clock"></i> ${item.fec_ingreso || 'N/D'}</span></td>
                <td style="padding: 15px;">
                    <div style="display: flex; align-items: center; gap: 12px; font-weight: 700; color: var(--welcome-blue);">
                        ${imgTag}
                        ${item.nom_materia_prima || 'Sin nombre'}
                    </div>
                </td>
                <td style="padding: 15px; color: var(--text-main);">${item.proveedor || 'No especificado'}</td>
                <td style="padding: 15px;"><span style="background: var(--bg-primary); color: var(--text-main); padding: 4px 10px; border-radius: 6px; font-size: 0.85em; border: 1px solid var(--border-color); font-weight: bold;">${item.lote || '-'}</span></td>
                <td style="padding: 15px; color: var(--text-main); font-weight: 500;">${item.tipo_mat_prima || '-'}</td>
                <td style="padding: 15px;">
                    <div style="display: flex; flex-direction: column; align-items: flex-start;">
                        <strong style="color: var(--text-main); font-size: 1.15em;">${item.cantidad_disponible || 0} Unds.</strong>
                        <div style="font-size: 0.75em; color: var(--text-muted); opacity: 0.8; margin-top: 2px; background: rgba(54,73,143,0.05); padding: 2px 6px; border-radius: 4px;">
                            ${item.valor_medida || 0} ${item.nom_unidad || ''}
                        </div>
                    </div>
                </td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
}

function filtrarBodega() {
    const search = document.getElementById('bodega-search').value.toLowerCase();
    const month = document.getElementById('bodega-month').value;
    const start = document.getElementById('bodega-start').value;
    const end = document.getElementById('bodega-end').value;

    const filtered = rawBodegaData.filter(item => {
        const matchText = (item.nom_materia_prima || "").toLowerCase().includes(search) ||
            (item.proveedor || "").toLowerCase().includes(search) ||
            (item.lote || "").toLowerCase().includes(search);

        const dateObj = new Date((item.fec_ingreso || "").replace(" ", "T"));
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
    renderFilasBodega(filtered);
}


function loadProduccionView(container) {
    if (!container) container = document.getElementById('dynamic-view');
    
    container.innerHTML = `
        <div id="produccion-root" class="mat-prim-slide-up" style="padding: 20px; padding-top: 30px; background: var(--bg-primary); min-height: 100vh;">
            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; border-bottom: 2px solid #087d4e; padding-bottom:10px;">
                <div style="display:flex; align-items:center; gap:15px;">
                    <button onclick="loadHistorialView()" style="background:linear-gradient(135deg, #087d4e 0%, var(--welcome-blue) 100%); border:none; color:white; font-size:1.2rem; cursor:pointer; width: 40px; height: 40px; border-radius: 50%; box-shadow: 0 4px 10px rgba(0,0,0,0.2); transition: transform 0.2s;"><i class="fa-solid fa-arrow-left"></i></button>
                    <h2 style="color: #087d4e; margin:0;"><i class="fa-solid fa-industry"></i> Línea de Producción</h2>
                </div>
            </div>

            <!-- Toolbar de Filtros -->
            <div class="kardex-toolbar" style="margin-bottom: 20px; border-left-color: #087d4e;">
                <div class="kardex-filter-group" style="flex:2;">
                    <label>Buscar Material o Proveedor</label>
                    <input type="text" id="prod-search" class="kardex-filter-input" placeholder="Ej: Alambre, Aceros S.A...">
                </div>
                <div class="kardex-filter-group">
                    <label>Mes</label>
                    <select id="prod-month" class="kardex-filter-input">
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
                    <input type="date" id="prod-start" class="kardex-filter-input">
                </div>
                <div class="kardex-filter-group">
                    <label>Hasta</label>
                    <input type="date" id="prod-end" class="kardex-filter-input">
                </div>
            </div> <!-- Cierre Toolbar -->
            <div class="table-wrapper" style="background: var(--bg-secondary); border-radius: 15px; box-shadow: 0 10px 30px var(--card-shadow); overflow: hidden; border: 1px solid var(--border-color); animation: kardexFadeIn 0.6s ease;">
            <div class="table-scroll" style="max-height: 60vh; overflow-y: auto;">
                <table class="data-table" style="width: 100%; border-collapse: separate; border-spacing: 0;">
                    <thead style="position: sticky; top: 0; z-index: 100;">
                        <tr style="text-align: left;">
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Ingreso a Producción</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Material</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Proveedor</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Lote</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Cantidad en Línea</th>
                            <th style="padding: 15px; background: #fff; color: #000; border-bottom: 2px solid rgba(0,0,0,0.1);">Agregado de Bodega en</th>
                        </tr>
                    </thead>
                    <tbody id="produccion-tbody">
                        <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 40px;">
                            <i class="fas fa-spinner fa-spin fa-2x"></i><br>Cargando línea de producción...
                        </td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
    `;

    fetch('../php/controllers/api_bodega_produccion.php?action=get_produccion')
        .then(response => response.json())
        .then(data => {
            if (data.status === 'success') {
                rawProduccionData = data.data;
                renderFilasProduccion(rawProduccionData);
            } else {
                document.getElementById('produccion-tbody').innerHTML = `<tr><td colspan="6" style="text-align: center; color: red;">Error: ${data.message}</td></tr>`;
            }
        })
        .then(() => {
            document.getElementById('prod-search').addEventListener('input', filtrarProduccion);
            document.getElementById('prod-month').addEventListener('change', filtrarProduccion);
            document.getElementById('prod-start').addEventListener('change', filtrarProduccion);
            document.getElementById('prod-end').addEventListener('change', filtrarProduccion);
        })
        .catch(err => {
            document.getElementById('produccion-tbody').innerHTML = `<tr><td colspan="6" style="text-align: center; color: red;">Error de conexión.</td></tr>`;
            console.error(err);
        });
}

function renderFilasProduccion(data) {
    const tbody = document.getElementById('produccion-tbody');
    if (!tbody) return;
    if (data.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" style="text-align: center; padding: 40px;">No hay material actualmente en producción.</td></tr>';
        return;
    }
    
    let html = '';
    data.forEach(item => {
        let imgTag = '';
        if (item.img_url && item.img_url.trim() !== '') {
            let finalUrl = item.img_url.startsWith('.') ? item.img_url : '..' + item.img_url;
            imgTag = `<img src="${finalUrl}" style="width: 30px; height: 30px; border-radius: 4px; object-fit: cover;" onerror="this.style.display='none'">`;
        } else {
            imgTag = `<div style="width: 30px; height: 30px; border-radius: 4px; background: #eee; display:flex; align-items:center; justify-content:center;"><i class="fa-solid fa-box" style="font-size:12px; color:#aaa;"></i></div>`;
        }

        html += `
            <tr style="color: var(--text-main); border-bottom: 1px solid var(--border-color); transition: background 0.2s;" onmouseover="this.style.background='var(--bg-primary)'" onmouseout="this.style.background='transparent'">
                <td style="padding: 15px;"><span style="color: #087d4e; font-weight: 700;"><i class="fa-regular fa-clock"></i> ${item.fecha_produccion || 'N/D'}</span></td>
                <td style="padding: 15px;">
                    <div style="display: flex; align-items: center; gap: 12px; font-weight: 700; color: #087d4e;">
                        ${imgTag}
                        ${item.nom_materia_prima || 'Sin nombre'}
                    </div>
                </td>
                <td style="padding: 15px; color: var(--text-main);">${item.proveedor || '-'}</td>
                <td style="padding: 15px;"><span style="background: var(--bg-primary); color: var(--text-main); padding: 4px 10px; border-radius: 6px; font-size: 0.85em; border: 1px solid var(--border-color); font-weight: bold;">${item.lote || '-'}</span></td>
                <td style="padding: 15px;">
                    <div style="display: flex; flex-direction: column; align-items: flex-start;">
                        <strong style="color: var(--text-main); font-size: 1.15em;">${item.cantidad_disponible || 0} Unds.</strong>
                        <div style="font-size: 0.75em; color: var(--text-muted); opacity: 0.8; margin-top: 2px; background: rgba(8,125,78,0.05); padding: 2px 6px; border-radius: 4px;">
                            (En proceso)
                        </div>
                    </div>
                </td>
                <td style="padding: 15px; color: var(--text-muted); font-size: 0.9em;"><i class="fa-regular fa-calendar-check" style="margin-right: 5px;"></i>${item.fecha_bodega || 'Desconocido'}</td>
            </tr>
        `;
    });
    tbody.innerHTML = html;
}

function filtrarProduccion() {
    const search = document.getElementById('prod-search').value.toLowerCase();
    const month = document.getElementById('prod-month').value;
    const start = document.getElementById('prod-start').value;
    const end = document.getElementById('prod-end').value;

    const filtered = rawProduccionData.filter(item => {
        const matchText = (item.nom_materia_prima || "").toLowerCase().includes(search) ||
            (item.proveedor || "").toLowerCase().includes(search) ||
            (item.lote || "").toLowerCase().includes(search);

        const dateObj = new Date((item.fecha_produccion || "").replace(" ", "T"));
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
    renderFilasProduccion(filtered);
}
