document.addEventListener('DOMContentLoaded', function () {
    // Referencias DOM
    const sidebar = document.querySelector('.contenedor_menus');
    const dashboardView = document.getElementById('dashboard-view');
    const dynamicView = document.getElementById('dynamic-view');
    const menuItems = document.querySelectorAll('.menu');

    // IDs de los botones del sidebar
    const btnInstrumental = document.getElementById('btn-instrumental');
    const btnMateriaPrima = document.getElementById('btn-materia-prima');
    const btnProductos = document.getElementById('btn-productos');
    const btnHistorial = document.getElementById('btn-historial');
    const btnFinanzas = document.getElementById('btn-finanzas');
    const logo = document.querySelector('.logo'); // Referencia al logo para volver al inicio

    // === EVENT LISTENERS ===

    if (btnInstrumental) {
        btnInstrumental.addEventListener('click', (e) => {
            e.preventDefault();
            const menuDiv = btnInstrumental.querySelector('.menu');
            if (menuDiv && menuDiv.classList.contains('active-menu')) {
                returnToDashboard();
            } else {
                activateMenu(btnInstrumental);
                loadView('instrumental');
            }
        });
    }

    if (btnMateriaPrima) {
        btnMateriaPrima.addEventListener('click', (e) => {
            e.preventDefault();
            const menuDiv = btnMateriaPrima.querySelector('.menu');
            if (menuDiv && menuDiv.classList.contains('active-menu')) {
                returnToDashboard();
            } else {
                activateMenu(btnMateriaPrima);
                loadView('materia-prima');
            }
        });
    }

    if (btnProductos) {
        btnProductos.addEventListener('click', (e) => {
            e.preventDefault();
            const menuDiv = btnProductos.querySelector('.menu');
            if (menuDiv && menuDiv.classList.contains('active-menu')) {
                returnToDashboard();
            } else {
                activateMenu(btnProductos);
                loadView('productos');
            }
        });
    }

    if (btnHistorial) {
        btnHistorial.addEventListener('click', (e) => {
            e.preventDefault();
            const menuDiv = btnHistorial.querySelector('.menu');
            if (menuDiv && menuDiv.classList.contains('active-menu')) {
                returnToDashboard();
            } else {
                activateMenu(btnHistorial);
                loadView('historial');
            }
        });
    }

    if (btnFinanzas) {
        btnFinanzas.addEventListener('click', (e) => {
            e.preventDefault();
            const menuDiv = btnFinanzas.querySelector('.menu');
            if (menuDiv && menuDiv.classList.contains('active-menu')) {
                returnToDashboard();
            } else {
                activateMenu(btnFinanzas);
                loadView('finanzas');
            }
        });
    }




    // === RESPONSIVE MOBILE MENU LOGIC ===
    const mobileProfileBtn = document.getElementById('mobileProfileBtn');
    const rightSidebar = document.querySelector('.a3');

    if (mobileProfileBtn && rightSidebar) {
        mobileProfileBtn.addEventListener('click', (e) => {
            e.stopPropagation();
            rightSidebar.classList.toggle('active-mobile-profile');
            mobileProfileBtn.classList.toggle('active');

            const icon = mobileProfileBtn.querySelector('i');
            if (rightSidebar.classList.contains('active-mobile-profile')) {
                icon.classList.remove('fa-bars');
                icon.classList.add('fa-times');
            } else {
                icon.classList.remove('fa-times');
                icon.classList.add('fa-bars');
            }
        });

        document.addEventListener('click', (e) => {
            if (rightSidebar.classList.contains('active-mobile-profile')) {
                if (!rightSidebar.contains(e.target) && e.target !== mobileProfileBtn) {
                    rightSidebar.classList.remove('active-mobile-profile');
                    mobileProfileBtn.classList.remove('active');
                    const icon = mobileProfileBtn.querySelector('i');
                    if (icon) {
                        icon.classList.remove('fa-times');
                        icon.classList.add('fa-bars');
                    }
                }
            }
        });

        const profileOptions = rightSidebar.querySelectorAll('.opcion-perfil');
        profileOptions.forEach(opt => {
            opt.addEventListener('click', () => {
                rightSidebar.classList.remove('active-mobile-profile');
                mobileProfileBtn.classList.remove('active');
                const icon = mobileProfileBtn.querySelector('i');
                if (icon) {
                    icon.classList.remove('fa-times');
                    icon.classList.add('fa-bars');
                }
            });
        });
    }

    // === FUNCIONES ===

    function activateMenu(element) {
        // Remover clase active de todos
        menuItems.forEach(item => {
            item.classList.remove('active-menu');
        });

        // Activar el seleccionado
        const menuDiv = element.querySelector('.menu');
        if (menuDiv) {
            menuDiv.classList.add('active-menu');
        }
    }

    function loadView(viewName) {
        // 1. Ocultar Dashboard
        dashboardView.style.display = 'none';

        // 2. Mostrar Contenedor Dinámico
        dynamicView.style.display = 'block';
        dynamicView.innerHTML = ''; // Limpiar previo

        // Clean up any FABs from other views (like Materia Prima)
        const fab = document.getElementById('fab-admin-categorias');
        if (fab) fab.remove();

        // 3. (Eliminado: Bloqueo de Sidebar)

        // 4. Expandir contenido (Ocultar panel derecho .a3)
        document.body.classList.add('expand-content');

        // 5. Cargar Contenido Específico
        if (viewName === 'instrumental') {
            // Usar lógica existente de instrumental.js si es posible
            if (typeof loadSelectionView === 'function') {
                // Modificar instrumental.js para que targetee dynamicView es lo ideal
                // O inyectar aquí manualmente si no se puede
                loadSelectionView(dynamicView);
            } else {
                // Fallback manual si instrumental.js no está expuesto globalmente
                renderInstrumentalSelection(dynamicView);
            }
        } else if (viewName === 'materia-prima') {
            if (typeof loadMateriaPrimaView === 'function') {
                loadMateriaPrimaView(dynamicView);
            } else {
                console.error("loadMateriaPrimaView no está definida");
                renderPlaceholder(dynamicView, viewName); // Fallback
            }
        } else if (viewName === 'historial') {
            if (typeof loadHistorialView === 'function') {
                loadHistorialView(dynamicView);
            } else {
                console.error("loadHistorialView no está definida");
                renderPlaceholder(dynamicView, viewName);
            }
        } else if (viewName === 'productos') {
            if (typeof loadProductosView === 'function') {
                loadProductosView(dynamicView);
            } else {
                console.error("loadProductosView no está definida");
                renderPlaceholder(dynamicView, viewName);
            }
        } else if (viewName === 'finanzas') {
            if (typeof loadFinanzasView === 'function') {
                loadFinanzasView(dynamicView);
            } else {
                console.error("loadFinanzasView no está definida");
                renderPlaceholder(dynamicView, viewName);
            }
        } else {
            // Vistas placeholder para otros menus
            renderPlaceholder(dynamicView, viewName);
        }

        // (Eliminado: Agregar Botón Volver global)
    }

    // === FUNCIONES GLOBALES (Expuestas) ===

    window.returnToDashboard = function () {
        const dashboardRef = document.getElementById('dashboard-view');
        const dynamicRef = document.getElementById('dynamic-view');

        // Clean up any FABs from other views (like Materia Prima)
        const fab = document.getElementById('fab-admin-categorias');
        if (fab) fab.remove();

        if (dynamicRef) {
            dynamicRef.style.display = 'none';
            dynamicRef.innerHTML = '';
        }

        if (dashboardRef) {
            dashboardRef.style.display = 'block';
            dashboardRef.classList.remove('fade-in'); // Reset animation
            void dashboardRef.offsetWidth; // Trigger reflow
            dashboardRef.classList.add('fade-in'); // Start animation
        }

        // Limpiar el estado activo de todos los menús
        const menuItemsRef = document.querySelectorAll('.menu');
        menuItemsRef.forEach(item => {
            item.classList.remove('active-menu');
        });

        // Mostrar panel derecho de nuevo
        document.body.classList.remove('expand-content');
        const rightSidebar = document.querySelector('.a3');
        if (rightSidebar) {
            rightSidebar.classList.remove('slide-in-right');
            void rightSidebar.offsetWidth; // Trigger reflow
            rightSidebar.classList.add('slide-in-right');
        }
    }

    function renderPlaceholder(container, title) {
        container.innerHTML = `
            <div style="padding: 50px; text-align: center; animation: fadeIn 0.5s;">
                <h2 style="color: #36498f; text-transform: capitalize;">${title.replace('-', ' ')}</h2>
                <p style="color: #666; margin-top: 20px;">Esta sección está en construcción o no tiene contenido asignado aún.</p>
                <div style="font-size: 5rem; color: #ddd; margin-top: 30px;">
                    <i class="fa-solid fa-person-digging"></i>
                </div>
            </div>
        `;
    }

    // Funciones Helper para Instrumental (si instrumental.js no está disponible globalmente)
    // Se intentará usar instrumental.js modificado
});






