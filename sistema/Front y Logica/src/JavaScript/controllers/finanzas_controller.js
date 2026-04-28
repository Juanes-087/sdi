
/**
 * ============================================================
 * CONTROLADOR DE FINANZAS Y REPORTES
 * ============================================================
 * 
 * PROPÓSITO:
 * Gestionar la visualización de métricas financieras, estadísticas
 * por especialidad y previsiones de compra de materia prima.
 * 
 * FUNCIONALIDADES:
 * 1. Visualización de KPIs (Ingresos, Tasa de Retorno, Ticket Promedio).
 * 2. Gráficos dinámicos con CSS/SVG.
 * 3. Exportación a PDF mediante la función nativa de impresión.
 * ============================================================
 */

window.loadFinanzasView = async function (container) {
    if (!container) return;

    // Obtener mes y año actual por defecto
    const now = new Date();
    let currentMes = now.getMonth() + 1;
    let currentAnio = now.getFullYear();

    // Estructura básica
    container.innerHTML = `
        <div class="finanzas-container" style="padding: 30px; animation: fadeIn 0.5s; background: var(--bg-primary);">
            <div class="finanzas-header" style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px;">
                <div>
                    <h1 style="color: var(--welcome-blue); font-size: 1.8rem; margin: 0;">Análisis Financiero y Reportes</h1>
                    <p style="color: var(--text-main); margin: 5px 0 0 0; opacity: 0.8;">Visualiza el rendimiento de tu negocio y previsiones de stock</p>
                </div>
                <div class="finanzas-actions" style="display: flex; gap: 15px; align-items: center;">
                    <div class="filter-group" style="display: flex; gap: 10px; background: var(--bg-secondary); padding: 5px 15px; border-radius: 30px; box-shadow: 0 4px 15px var(--card-shadow); border: 1px solid var(--border-color);">
                        <select id="fin-mes" class="fin-select" style="border: none; padding: 8px; outline: none; font-weight: 600; color: var(--welcome-blue); cursor: pointer; background: transparent;">
                            <option value="0" ${currentMes === 0 ? 'selected' : ''}>Todo el año</option>
                            ${Array.from({ length: 12 }, (_, i) => `<option value="${i + 1}" ${currentMes === i + 1 ? 'selected' : ''}>${new Intl.DateTimeFormat('es-ES', { month: 'long' }).format(new Date(2000, i))}</option>`).join('')}
                        </select>
                        <select id="fin-anio" class="fin-select" style="border: none; padding: 8px; outline: none; font-weight: 600; color: var(--welcome-blue); cursor: pointer; background: transparent;">
                            ${[2023, 2024, 2025, 2026].map(y => `<option value="${y}" ${currentAnio === y ? 'selected' : ''}>${y}</option>`).join('')}
                        </select>
                    </div>
                    <button onclick="window.exportarReporteExcel(event)" class="btn-primary" style="padding: 10px 25px; border-radius: 30px; display: flex; align-items: center; gap: 10px; cursor: pointer; border: none; background: #087d4e; color: white; font-weight: bold; box-shadow: 0 4px 10px rgba(8,125,78,0.2);">
                        <i class="fa-solid fa-file-excel"></i> Exportar Excel
                    </button>
                </div>
            </div>

            <div id="finanzas-content">
                <div class="loading-spinner" style="text-align: center; padding: 50px;">
                    <i class="fa-solid fa-spinner fa-spin fa-3x" style="color: var(--welcome-blue);"></i>
                    <p style="margin-top: 15px; color: var(--text-muted);">Cargando métricas...</p>
                </div>
            </div>
        </div>
    `;

    // Listeners para filtros
    const mesSel = document.getElementById('fin-mes');
    const anioSel = document.getElementById('fin-anio');

    const reload = () => {
        renderFinanzasData(mesSel.value, anioSel.value);
    };

    mesSel.addEventListener('change', reload);
    anioSel.addEventListener('change', reload);

    // Carga inicial
    reload();
};

async function renderFinanzasData(mes, anio) {
    const content = document.getElementById('finanzas-content');
    if (!content) return;

    try {
        const response = await fetch(`./api_gestion.php?tipo=finanzas&mes=${mes}&anio=${anio}`);
        const result = await response.json();

        if (!result.success) throw new Error("Error al cargar datos");

        const { stats, tickets, alertas } = result.data;

        // Formatear moneda
        const fmt = new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 });

        content.innerHTML = `
            <!-- Fila 1: KPIs -->
            <div class="kpi-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 20px; margin-bottom: 30px;">
                <div class="stat-card stat-card-primary" style="cursor: default !important;">
                    <div class="stat-icon"><i class="fa-solid fa-hand-holding-dollar"></i></div>
                    <div class="stat-info">
                        <span class="stat-label">Ingresos Mensuales</span>
                        <span class="stat-value">${fmt.format(stats.total_ingresos)}</span>
                    </div>
                </div>
                <div class="stat-card stat-card-success" style="cursor: help !important;" title="Ganancia real después de restar el costo de los materiales consumidos del total de ingresos mensuales (Margen de utilidad bruta).">
                    <div class="stat-icon"><i class="fa-solid fa-chart-line"></i></div>
                    <div class="stat-info">
                        <span class="stat-label">Utilidad Neta del Mes</span>
                        <span class="stat-value">${fmt.format(stats.rentabilidad.utilidad)}</span>
                        <span class="stat-hint" style="font-weight: 600;">
                            Margen: ${stats.rentabilidad.margen}% 
                            <i class="fa-solid ${stats.rentabilidad.margen >= 30 ? 'fa-circle-check' : (stats.rentabilidad.margen >= 15 ? 'fa-circle-info' : 'fa-triangle-exclamation')}" 
                               style="margin-left: 5px; color: ${stats.rentabilidad.margen >= 30 ? '#087d4e' : (stats.rentabilidad.margen >= 15 ? '#f59e0b' : '#dc3545')}"></i>
                        </span>
                    </div>
                </div>
                <div class="stat-card stat-card-warning" style="cursor: help !important;" title="Porcentaje de ventas que resultaron en devoluciones. Un valor bajo indica mayor satisfacción del cliente y calidad en producción.">
                    <div class="stat-icon"><i class="fa-solid fa-rotate-left"></i></div>
                    <div class="stat-info">
                        <span class="stat-label">Tasa de Retorno</span>
                        <span class="stat-value">${((stats.devoluciones.total_dev / (stats.devoluciones.total_fact || 1)) * 100).toFixed(1)}%</span>
                        <span class="stat-hint">${stats.devoluciones.total_dev} devoluciones de ${stats.devoluciones.total_fact} ventas</span>
                    </div>
                </div>
                <div class="stat-card stat-card-info" style="cursor: default !important;">
                    <div class="stat-icon"><i class="fa-solid fa-truck-ramp-box"></i></div>
                    <div class="stat-info">
                        <span class="stat-label">Alertas de Reabastecimiento</span>
                        <span class="stat-value">${alertas.length}</span>
                        <span class="stat-hint">Materias primas bajas</span>
                    </div>
                </div>
            </div>

            <div class="charts-row" style="display: grid; grid-template-columns: 1.5fr 1fr; gap: 30px; margin-bottom: 30px;">
                <!-- Gráfico de Especialidades -->
                <div class="chart-box" style="background: var(--bg-secondary); padding: 25px; border-radius: 20px; box-shadow: 0 10px 30px var(--card-shadow); border: 1px solid var(--border-color);">
                    <h3 style="color: var(--text-main); margin-bottom: 20px; font-size: 1.1rem; border-left: 4px solid var(--welcome-blue); padding-left: 15px;">Ticket Promedio por Especialidad</h3>
                    <div id="bar-chart-container" style="display: flex; flex-direction: column; gap: 15px; margin-top: 20px;">
                        ${renderSpecialtyBars(tickets, fmt)}
                    </div>
                </div>

                <!-- Gráfico de Medios de Pago -->
                <div class="chart-box" style="background: var(--bg-secondary); padding: 25px; border-radius: 20px; box-shadow: 0 10px 30px var(--card-shadow); display: flex; flex-direction: column; align-items: center; border: 1px solid var(--border-color);">
                    <h3 style="color: var(--text-main); margin-bottom: 20px; font-size: 1.1rem; border-left: 4px solid #087d4e; padding-left: 15px; width: 100%;">Medios de Pago</h3>
                    <div id="donut-chart" style="width: 200px; height: 200px; border-radius: 50%; background: ${renderDonutGradient(stats.medios_pago)}; position: relative; display: flex; align-items: center; justify-content: center; margin: 20px 0;">
                        <div style="width: 140px; height: 140px; background: var(--bg-secondary); border-radius: 50%; display: flex; flex-direction: column; align-items: center; justify-content: center; box-shadow: inset 0 0 10px rgba(0,0,0,0.2);">
                            <span style="font-weight: 700; color: var(--text-main); font-size: 1.2rem;">${stats.devoluciones.total_fact}</span>
                            <span style="font-size: 0.7rem; color: var(--text-muted); text-transform: uppercase;">Ventas Totales</span>
                        </div>
                    </div>
                    <div class="donut-legend" style="width: 100%; display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 20px;">
                        <div style="display: flex; align-items: center; gap: 8px; font-size: 0.85rem; color: var(--text-muted);"><span style="width: 12px; height: 12px; border-radius: 3px; background: #36498f;"></span> Efectivo</div>
                        <div style="display: flex; align-items: center; gap: 8px; font-size: 0.85rem; color: var(--text-muted);"><span style="width: 12px; height: 12px; border-radius: 3px; background: #087d4e;"></span> Transf.</div>
                        <div style="display: flex; align-items: center; gap: 8px; font-size: 0.85rem; color: var(--text-muted);"><span style="width: 12px; height: 12px; border-radius: 3px; background: #f59e0b;"></span> Tarjeta</div>
                    </div>
                </div>
            </div>

            <!-- Previsiones de Compra -->
            <div class="alertas-section" style="background: var(--bg-secondary); padding: 25px; border-radius: 20px; box-shadow: 0 10px 30px var(--card-shadow); border: 1px solid var(--border-color);">
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px;">
                    <h3 style="color: var(--text-main); font-size: 1.1rem; border-left: 4px solid #e74c3c; padding-left: 15px;">Previsiones de Compra (Stock Crítico)</h3>
                    ${alertas.length > 0 ? `<span class="badge" style="background: rgba(231, 76, 60, 0.1); color: #e74c3c; padding: 5px 12px; border-radius: 20px; font-size: 0.85rem; border: 1px solid rgba(231, 76, 60, 0.3);">${alertas.length} materiales requieren atención</span>` : ''}
                </div>
                
                ${alertas.length === 0 ? `
                    <div style="text-align: center; padding: 40px; color: var(--text-muted);">
                        <i class="fa-solid fa-check-circle fa-3x" style="color: #087d4e; opacity: 0.3; margin-bottom: 15px;"></i>
                        <p>Todo el inventario de materia prima está en niveles óptimos.</p>
                    </div>
                ` : `
                    <div class="alertas-grid" style="display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 15px;">
                        ${alertas.map(a => `
                            <div class="alerta-card" style="border: 1px solid var(--border-color); background: var(--bg-primary); padding: 15px; border-radius: 12px; display: flex; justify-content: space-between; align-items: center; transition: all 0.3s ease;">
                                <div>
                                    <strong style="display: block; color: var(--text-main); margin-bottom: 5px;">${a.material}</strong>
                                    <div style="font-size: 0.8rem; color: var(--text-muted);">
                                        Stock: <span style="color: #e74c3c; font-weight: bold;">${a.stock_actual}</span> / Mín: ${a.stock_min}
                                    </div>
                                    <div style="font-size: 0.8rem; color: var(--text-muted); opacity: 0.8; margin-top: 4px;">Prov: ${a.proveedor}</div>
                                </div>
                                <a href="https://wa.me/57${a.telefono}?text=Hola+${encodeURIComponent(a.proveedor)},+necesito+reabastecer+${encodeURIComponent(a.material)}" target="_blank" class="wa-btn" style="background: #25d366; color: white; width: 40px; height: 40px; border-radius: 50%; display: flex; align-items: center; justify-content: center; text-decoration: none; box-shadow: 0 4px 10px rgba(37, 211, 102, 0.3);">
                                    <i class="fa-brands fa-whatsapp fa-xl"></i>
                                </a>
                            </div>
                        `).join('')}
                    </div>
                `}
            </div>
        `;

    } catch (e) {
        console.error(e);
        content.innerHTML = `<p style="color: red; text-align: center;">Error al cargar datos financieros.</p>`;
    }
}

// Generador de Barras CSS
function renderSpecialtyBars(tickets, fmt) {
    if (tickets.length === 0) return '<p style="color: #999; text-align: center;">No hay ventas registradas en este periodo.</p>';

    // Encontrar el máximo para escalar
    const max = Math.max(...tickets.map(t => parseFloat(t.ticket_promedio)));

    return tickets.map(t => {
        const percentage = (parseFloat(t.ticket_promedio) / max) * 100;
        return `
            <div class="bar-item">
                <div style="display: flex; justify-content: space-between; margin-bottom: 5px; font-size: 0.85rem;">
                    <span style="font-weight: 600; color: var(--text-main);">${t.especialidad}</span>
                    <span style="color: var(--welcome-blue); font-weight: 700;">${fmt.format(t.ticket_promedio)}</span>
                </div>
                <div style="width: 100%; height: 12px; background: var(--bg-primary); border-radius: 10px; overflow: hidden; position: relative; border: 1px solid var(--border-color);">
                    <div style="width: ${percentage}%; height: 100%; background: linear-gradient(90deg, #36498f, #087d4e); border-radius: 10px; transition: width 1s cubic-bezier(0.175, 0.885, 0.32, 1.275);"></div>
                </div>
                <div style="font-size: 0.7rem; color: var(--text-muted); text-align: right; margin-top: 2px;">${t.volumen_ventas} ventas registradas</div>
            </div>
        `;
    }).join('');
}

// Generador de Gradiente de Dona CSS
function renderDonutGradient(medios) {
    if (medios.length === 0) return '#eee';

    const total = medios.reduce((acc, m) => acc + parseInt(m.cantidad), 0);
    let cumulative = 0;
    const colors = {
        '1': '#36498f', // Efectivo
        '2': '#087d4e', // Transf
        '3': '#f59e0b'  // Tarjeta
    };

    const slices = medios.map(m => {
        const p = (parseInt(m.cantidad) / total) * 100;
        const start = cumulative;
        cumulative += p;
        return `${colors[m.ind_forma_pago] || '#ccc'} ${start}% ${cumulative}%`;
    });

    return `conic-gradient(${slices.join(', ')})`;
}

// Exportación a EXCEL detallada
window.exportarReporteExcel = async function (e) {
    const mes = document.getElementById('fin-mes').value;
    const anio = document.getElementById('fin-anio').value;
    const mesNombre = document.getElementById('fin-mes').selectedOptions[0].text;

    // Mostrar feedback al usuario
    const btn = e ? e.currentTarget : null;
    const originalContent = btn.innerHTML;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Generando...';
    btn.disabled = true;

    try {
        const response = await fetch(`./api_gestion.php?tipo=finanzas_reporte&mes=${mes}&anio=${anio}`);
        const result = await response.json();

        if (!result.success || !result.data || result.data.length === 0) {
            Swal.fire('Atención', 'No hay datos detallados para el periodo seleccionado.', 'info');
            return;
        }

        // Crear libro y hoja de cálculo
        const worksheet = XLSX.utils.json_to_sheet(result.data);
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, "Reporte Financiero");

        // Ajustar anchos de columna (opcional pero recomendado)
        // Ajustar anchos de columna (opcional pero recomendado)
        const wscols = [
            { wch: 12 }, // ID Factura
            { wch: 20 }, // Fecha
            { wch: 12 }, // Mes
            { wch: 40 }, // Productos Comprados
            { wch: 30 }, // Cliente
            { wch: 15 }, // Total
            { wch: 15 }  // Medio Pago
        ];
        worksheet['!cols'] = wscols;

        // Descargar archivo
        XLSX.writeFile(workbook, `Reporte_Financiero_SDI_${mesNombre}_${anio}.xlsx`);

    } catch (e) {
        console.error(e);
        Swal.fire('Error', 'No se pudo generar el reporte Excel.', 'error');
    } finally {
        btn.innerHTML = originalContent;
        btn.disabled = false;
    }
};
