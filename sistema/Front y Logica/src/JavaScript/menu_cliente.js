/**
 * Logic for menuCliente.php Redesign (v2)
 * Fixes: Price mapping, Filter normalization, SVG Icons
 */

document.addEventListener('DOMContentLoaded', () => {
    initApp();
});

const state = {
    products: [],
    cart: [],
    currentCategory: 'todos',
    currencyFormatter: new Intl.NumberFormat('es-CO', {
        style: 'currency',
        currency: 'COP',
        minimumFractionDigits: 0
    })
};

// --- Initialization ---
function initApp() {
    loadCart();
    fetchProducts();
    setupEventListeners();
    updateCartUI();
    verificarExpiracionToken();
}

// --- Token Expiration Logic ---
function verificarExpiracionToken() {
    const token = localStorage.getItem('token');
    if (!token) return; // No hay token, posiblemente ya expiró o no inició sesión

    try {
        const payloadBase64 = token.split('.')[1];
        const decodedJson = atob(payloadBase64);
        const payload = JSON.parse(decodedJson);
        const exp = payload.exp;
        const now = Math.floor(Date.now() / 1000);

        if (exp < now) {
            // Ya expiró
            mostrarModalExpiracion();
        } else {
            // Calcular tiempo restante
            const timeRemaining = (exp - now) * 1000;
            // Configurar timer
            setTimeout(() => {
                mostrarModalExpiracion();
            }, timeRemaining);
        }
    } catch (e) {
        console.error('Error al verificar token:', e);
    }
}

function mostrarModalExpiracion() {
    // Eliminar cualquier otro modal
    const existing = document.querySelectorAll('.modal, .modal-client-custom');
    existing.forEach(m => m.style.display = 'none');

    let modal = document.getElementById('modalExpiracion');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'modalExpiracion';
        modal.className = 'modal-client-custom';

        modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.85); display: flex; align-items: center; justify-content: center; z-index: 2147483647 !important; backdrop-filter: blur(5px);';

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
        `;
        document.body.appendChild(modal);

        document.getElementById('btnAceptarExpiracion').onclick = function () {
            // Deshabilitar botón para evitar doble click
            this.disabled = true;
            this.innerHTML = "Cerrando...";

            // 1. Prevenir volver atrás
            window.history.pushState(null, null, window.location.href);
            window.onpopstate = function () {
                window.history.pushState(null, null, window.location.href);
            };

            // 2. Limpiar Storage Local
            try {
                localStorage.clear();
                sessionStorage.clear();
            } catch (e) {
                console.error(e);
            }

            // 3. Petición al servidor para destruir sesión PHP
            fetch('logout.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' }
            })
                .finally(() => {
                    // 4. Redirigir forzadamente
                    window.location.replace('../../index.html');
                });
        };
    }

    modal.style.setProperty('display', 'flex', 'important');
}

// --- Icons (Inline SVGs) ---
const icons = {
    search: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>',
    cart: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="9" cy="21" r="1"></circle><circle cx="20" cy="21" r="1"></circle><path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path></svg>',
    user: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>',
    logout: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>',
    plus: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>',
    check: '<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>',
    trash: '<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>',
    close: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>'
};

// --- Helper: Normalizer ---
function normalizeStr(str) {
    if (!str) return '';
    return str.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

// --- Event Listeners ---
function setupEventListeners() {
    // Mobile Menu
    const hamburger = document.querySelector('.hamburger');
    const overlay = document.querySelector('.mobile-overlay');

    if (hamburger) hamburger.addEventListener('click', toggleMobileMenu);
    if (overlay) overlay.addEventListener('click', closeMobileMenu);

    // Cart Drawer
    const cartBtn = document.querySelector('.cart-btn'); // Desktop
    const cartBtnMobile = document.querySelector('.mobile-link[px-cart]'); // Mobile
    const closeCartBtn = document.querySelector('.close-cart');

    if (cartBtn) cartBtn.addEventListener('click', toggleCart);
    if (cartBtnMobile) cartBtnMobile.addEventListener('click', (e) => {
        e.preventDefault();
        closeMobileMenu();
        toggleCart();
    });
    if (closeCartBtn) closeCartBtn.addEventListener('click', toggleCart);

    // Search
    const searchInput = document.querySelector('.search-input');
    if (searchInput) {
        searchInput.addEventListener('input', debounce((e) => {
            fetchProducts(e.target.value);
        }, 500));
    }

    // Category Tabs
    const tabs = document.querySelectorAll('.tab-btn');
    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');
            state.currentCategory = tab.dataset.category;
            renderProducts();
        });
    });
}

// --- Fetching Data ---
async function fetchProducts(query = '') {
    const grid = document.querySelector('.grid');
    if (!grid) return;

    // Use a simpler loading state without spinner icon first
    grid.innerHTML = '<div style="width:100%; text-align:center; padding:40px;">Cargando...</div>';

    try {
        const response = await fetch(`api_productos.php?q=${encodeURIComponent(query)}`);
        if (!response.ok) throw new Error(`HTTP ${response.status}`);

        // const rawData = await response.json();
        const rawData = await response.json();
        // console.log('API RESPONSE:', rawData); // Debug for user

        if (!Array.isArray(rawData)) throw new Error('Format error');

        // Robust mapping
        state.products = rawData.map(item => {
            // Price detection
            const priceVal = item.precio || item.precio_producto || item.costo || item.valor || 0;
            const categoryVal = item.categoria || item.tipo_producto || 'general';

            // Determinar si el producto es "Nuevo" (creado en las últimas 2 semanas)
            let isNew = false;
            if (item.fec_insert) {
                const createdDate = new Date(item.fec_insert + 'T00:00:00');
                const twoWeeksAgo = new Date();
                twoWeeksAgo.setDate(twoWeeksAgo.getDate() - 14);
                isNew = createdDate >= twoWeeksAgo;
            }

            return {
                id: item.id || item.id_producto || item.id_instrumento || item.id_kit, // Try multiple ID fields
                name: item.nombre_producto || item.nombre || item.nom_instrumento || item.nom_kit || 'Producto sin nombre',
                category: categoryVal,
                // Normalized category for filtering
                categoryNorm: normalizeStr(categoryVal),
                price: parseFloat(priceVal),
                description: item.descripcion || item.detalle_extra || 'Sin descripción disponible',
                isNew: isNew,
                image: (function () {
                    let img = item.img_url || item.imagen || '../../images/logo central solo.png';
                    // Fix: If path is "images/foo.jpg" (relative to specialized/), make it "../images/foo.jpg" (relative to specialized/php/)
                    if (img && !img.startsWith('../') && !img.startsWith('../../') && !img.startsWith('http') && !img.startsWith('/')) {
                        img = '../../' + img;
                    }
                    return img;
                })()
            };
        });

        renderProducts();

    } catch (error) {
        console.error('Error fetching products:', error);
        grid.innerHTML = '<p style="text-align:center; color:red;">No se pudieron cargar los productos.</p>';
    }
}

// --- Rendering ---
function renderProducts() {
    const grid = document.querySelector('.grid');
    if (!grid) return;

    const currentCatNorm = normalizeStr(state.currentCategory);

    const filtered = currentCatNorm === 'todos'
        ? state.products
        : state.products.filter(p => p.categoryNorm.includes(currentCatNorm));

    if (filtered.length === 0) {
        grid.innerHTML = '<p style="text-align:center; width:100%; grid-column: 1/-1;">No se encontraron productos en esta categoría.</p>';
        return;
    }

    grid.innerHTML = filtered.map(product => `
        <div class="product-card">
            <div class="card-image-container" style="background-color: #f5f5f5; height: 200px; display: flex; align-items: center; justify-content: center; position: relative;">
                <span class="card-badge">${product.category}</span>
                ${product.isNew ? '<span style="position:absolute; top:15px; right:15px; background:linear-gradient(135deg,#087d4e,#00d2ff); color:white; padding:5px 14px; border-radius:15px; font-size:0.75rem; font-weight:bold; z-index:2; letter-spacing:0.5px; box-shadow:0 2px 8px rgba(8,125,78,0.4);"><i class="fa-solid fa-certificate" style="margin-right:3px;"></i>Nuevo</span>' : ''}
                <img src="${product.image}" alt="${product.name}" class="card-image" 
                    loading="lazy"
                    style="max-width: 100%; max-height: 100%; object-fit: contain;"
                    onerror="this.src='../../images/logo central solo.png'; this.onerror=null;">
            </div>
            <div class="card-details">
                <h3 class="card-title">${product.name}</h3>
                <p class="card-description">${product.description.substring(0, 60)}...</p>
                <div class="card-footer">
                    <span class="card-price">${state.currencyFormatter.format(product.price)}</span>
                    <button class="btn-add" onclick="addToCart(${product.id})" title="Agregar al carrito">
                        ${icons.plus}
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

// --- Cart Logic ---
function loadCart() {
    const stored = localStorage.getItem('shoppingCart');
    if (stored) {
        try {
            state.cart = JSON.parse(stored);
        } catch (e) {
            state.cart = [];
        }
    }
}

function saveCart() {
    localStorage.setItem('shoppingCart', JSON.stringify(state.cart));
    updateCartUI();
}

window.addToCart = function (id) {
    const product = state.products.find(p => p.id == id);
    if (!product) return;

    const existing = state.cart.find(item => item.id == id);
    if (existing) {
        existing.qty++;
    } else {
        state.cart.push({ ...product, qty: 1 });
    }

    saveCart();

    // Visual feedback
    const btn = document.activeElement;
    if (btn && (btn.classList.contains('btn-add') || btn.closest('.btn-add'))) {
        const target = btn.classList.contains('btn-add') ? btn : btn.closest('.btn-add');
        const originalHTML = target.innerHTML;
        target.innerHTML = icons.check;
        target.style.background = '#087d4e';
        setTimeout(() => {
            target.innerHTML = originalHTML;
            target.style.background = '';
        }, 1000);
    }
}

window.removeFromCart = function (id) {
    state.cart = state.cart.filter(item => item.id != id);
    saveCart();
}

window.updateQty = function (id, change) {
    const item = state.cart.find(i => i.id == id);
    if (!item) return;

    item.qty += change;
    if (item.qty <= 0) {
        removeFromCart(id);
    } else {
        saveCart();
    }
}

function updateCartUI() {
    // Update Badge
    const count = state.cart.reduce((sum, item) => sum + item.qty, 0);
    const badges = document.querySelectorAll('.cart-count');
    badges.forEach(badge => {
        badge.textContent = count;
        if (count > 0) badge.classList.add('visible');
        else badge.classList.remove('visible');
    });

    // Render Drawer Items
    const container = document.querySelector('.cart-items');
    if (!container) return;

    if (state.cart.length === 0) {
        container.innerHTML = `
            <div class="empty-cart-msg">
                <div style="color:#ddd; margin-bottom:15px;">${icons.cart.replace('width="24"', 'width="64"').replace('height="24"', 'height="64"')}</div>
                <p>Tu carrito está vacío</p>
                <button class="btn-primary" onclick="toggleCart()" style="margin-top:10px;">Ver Productos</button>
            </div>
        `;
        document.querySelector('.cart-total-value').textContent = state.currencyFormatter.format(0);
        return;
    }

    let total = 0;
    container.innerHTML = state.cart.map(item => {
        total += item.price * item.qty;
        return `
            <div class="cart-item">
                <img src="${item.image}" class="cart-item-img" onerror="this.src='../../images/logo central solo.png'">
                <div class="cart-item-info">
                    <div class="cart-item-title">${item.name}</div>
                    <div class="cart-item-price">${state.currencyFormatter.format(item.price)}</div>
                    <div class="cart-item-controls">
                        <div class="qty-btn" onclick="updateQty(${item.id}, -1)">-</div>
                        <span class="qty-val">${item.qty}</span>
                        <div class="qty-btn" onclick="updateQty(${item.id}, 1)">+</div>
                    </div>
                </div>
                <div class="remove-item" onclick="removeFromCart(${item.id})">
                    ${icons.trash}
                </div>
            </div>
        `;
    }).join('');

    document.querySelector('.cart-total-value').textContent = state.currencyFormatter.format(total);
}

// --- UI Helpers ---
function toggleMobileMenu() {
    document.querySelector('.mobile-menu').classList.toggle('active');
    document.querySelector('.mobile-overlay').classList.toggle('active');
}

function closeMobileMenu() {
    document.querySelector('.mobile-menu').classList.remove('active');
    document.querySelector('.mobile-overlay').classList.remove('active');
}

function toggleCart() {
    const drawer = document.querySelector('.cart-drawer');
    const overlay = document.querySelector('.mobile-overlay');

    drawer.classList.toggle('open');
    if (drawer.classList.contains('open')) {
        overlay.classList.add('active');
        // Override overlay click to close cart
        overlay.onclick = () => {
            drawer.classList.remove('open');
            overlay.classList.remove('active');
            // Reset overlay click to close mobile menu
            overlay.onclick = closeMobileMenu;
        };
    } else {
        overlay.classList.remove('active');
        overlay.onclick = closeMobileMenu;
    }
}

// Utils
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// --- Profile & User Actions ---
window.openProfileModal = function () {
    const modal = document.getElementById('modalPerfil');
    if (modal) {
        modal.display = 'flex'; // Fix: might fail if strict mode? No. style.display
        modal.style.display = 'flex';
        setTimeout(() => modal.classList.add('show'), 10);
    }
}

window.closeProfileModal = function () {
    const modal = document.getElementById('modalPerfil');
    if (modal) {
        modal.classList.remove('show');
        setTimeout(() => modal.style.display = 'none', 300);
    }
}

window.openPasswordModal = function () {
    const modal = document.getElementById('modalPassword');
    if (modal) {
        modal.style.display = 'flex';
        setTimeout(() => modal.classList.add('show'), 10);
    }
}

window.closePasswordModal = function () {
    const modal = document.getElementById('modalPassword');
    if (modal) {
        modal.classList.remove('show');
        setTimeout(() => modal.style.display = 'none', 300);

        // Limpiar formulario al cerrar (opcional, pero buena práctica)
        const form = document.getElementById('formPassword');
        if (form && !document.querySelector('.alert-success')) {
            // Solo limpiar si NO hubo éxito reciente (para que usuario vea mensaje)
            // O simplemente limpiar siempre
            form.reset();
        }
    }
}

// --- Password Validation Logic ---
function setupPasswordValidation() {
    const newPassInput = document.getElementById('newPassClient');
    const confirmPassInput = document.getElementById('confirmPassClient');
    const form = document.getElementById('formPassword');

    if (!newPassInput || !confirmPassInput || !form) return;

    function getMsgElement(input) {
        let msg = input.nextElementSibling;
        while (msg && !msg.classList.contains('validation-msg') && !msg.classList.contains('form-group')) {
            msg = msg.nextElementSibling;
        }
        if (!msg || !msg.classList.contains('validation-msg')) {
            msg = document.createElement("div");
            msg.className = "validation-msg";
            msg.style.display = "none";
            msg.style.fontSize = "11px";
            msg.style.color = "#666";
            msg.style.marginTop = "5px";
            input.parentNode.appendChild(msg);
        }
        return msg;
    }

    // Helper functions need to be defined or hoisted
    function validateStrength(input, msg) {
        const val = input.value;
        let valid = true;

        if (val.length < 8 || !/[A-Z]/.test(val) || !/[a-z]/.test(val) || !/[0-9]/.test(val)) {
            msg.style.color = "#dc3545";
            let errs = [];
            if (val.length < 8) errs.push("8+ caracteres");
            if (!/[A-Z]/.test(val)) errs.push("1 Mayúscula");
            if (!/[a-z]/.test(val)) errs.push("1 Minúscula");
            if (!/[0-9]/.test(val)) errs.push("1 Número");
            msg.textContent = "Faltan: " + errs.join(", ");
            valid = false;
        } else {
            msg.style.color = "#087d4e";
            msg.textContent = "Contraseña segura.";
        }
        return valid;
    }

    function validateMatch(input, msg, matchInput) {
        let valid = true;
        if (input.value !== matchInput.value) {
            msg.style.color = "#dc3545";
            msg.textContent = "Las contraseñas no coinciden.";
            valid = false;
        } else if (input.value === '') {
            msg.style.color = "#dc3545";
            msg.textContent = "No puede estar vacío.";
            valid = false;
        } else {
            msg.style.color = "#087d4e";
            msg.textContent = "Las contraseñas coinciden.";
        }
        return valid;
    }

    [newPassInput, confirmPassInput].forEach(input => {
        const msg = getMsgElement(input);

        input.addEventListener('focus', () => {
            msg.style.display = 'block';
            if (input.id === 'newPassClient') msg.textContent = "Min. 8 caracteres, 1 Mayúscula, 1 Minúscula, 1 Número.";
            if (input.id === 'confirmPassClient') msg.textContent = "Debe coincidir con la nueva contraseña.";
        });

        input.addEventListener('input', () => {
            msg.style.display = 'block';
            if (input.id === 'newPassClient') validateStrength(input, msg);
            if (input.id === 'confirmPassClient') validateMatch(input, msg, newPassInput);
        });

        input.addEventListener('blur', () => {
            msg.style.display = 'none';
        });
    });

    form.addEventListener('submit', function (e) {
        let valid = true;
        const msgNew = getMsgElement(newPassInput);
        if (!validateStrength(newPassInput, msgNew)) valid = false;

        const msgConfirm = getMsgElement(confirmPassInput);
        if (!validateMatch(confirmPassInput, msgConfirm, newPassInput)) valid = false;

        if (!valid) {
            e.preventDefault();
            msgNew.style.display = 'block';
            msgConfirm.style.display = 'block';
        }
    });
}

// Initialize validation on load
setupPasswordValidation();

// ============================================
// LOGOUT SEGURO & MODALES PERSONALIZADOS
// ============================================

window.cerrarSesionSeguro = function (e) {
    if (e) e.preventDefault();

    mostrarConfirmacionCustom(
        'Cerrar Sesión',
        '¿Estás seguro de que deseas cerrar sesión?',
        function () {
            ejecutarLogout();
        },
        'Sí, Cerrar Sesión',
        'linear-gradient(135deg, #36498f 0%, #087d4e 100%)'
    );
};

function ejecutarLogout() {
    mostrarCargando();

    // Deshabilitar navegación hacia atrás
    window.history.pushState(null, null, window.location.href);
    window.onpopstate = function () {
        window.history.pushState(null, null, window.location.href);
        window.location.href = '../../index.html';
    };

    // Limpiar localStorage (tokens JWT)
    try {
        localStorage.removeItem('token');
        localStorage.clear();
    } catch (e) {
        console.error('Error al limpiar localStorage:', e);
    }

    // Limpiar sessionStorage
    try {
        sessionStorage.clear();
    } catch (e) {
        console.error('Error al limpiar sessionStorage:', e);
    }

    fetch('logout.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    })
        .finally(() => {
            // Siempre redirigir, incluso si falla el fetch
            setTimeout(() => {
                window.location.replace('../../index.html');
            }, 800);
        });
}


function mostrarCargando() {
    let modal = document.getElementById('modalCargandoClient');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'modalCargandoClient';
        modal.className = 'modal-client-custom'; // Unique class

        // Force critical styles inline with !important
        modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2147483647 !important;';

        // Estructura interna
        modal.innerHTML = `
        <div style="background: white; padding: 30px 50px; border-radius: 15px; text-align: center; box-shadow: 0 4px 15px rgba(0,0,0,0.2);">
                <div style="margin-bottom: 15px;">
                   <svg xmlns="http://www.w3.org/2000/svg" width="40" height="40" viewBox="0 0 50 50" style="animation: spin 1s linear infinite;">
                        <circle cx="25" cy="25" r="20" fill="none" stroke="#36498f" stroke-width="5" stroke-dasharray="80" stroke-linecap="round"></circle>
                   </svg>
                   <style>@keyframes spin { 100% { transform: rotate(360deg); } }</style>
                </div>
                <h3 style="margin: 0; color: #333; font-size: 18px;">Cerrando Sesión...</h3>
            </div >
        `;
        document.body.appendChild(modal);
    }
    modal.style.setProperty('display', 'flex', 'important');
}

function ocultarCargando() {
    const modal = document.getElementById('modalCargandoClient');
    if (modal) {
        modal.style.display = 'none';
    }
}

function mostrarConfirmacionCustom(titulo, mensaje, callbackAceptar, btnText = 'Sí, eliminarlo', btnStyle = null) {
    let modal = document.getElementById('modalConfirmClient');
    if (!modal) {
        modal = document.createElement('div');
        modal.id = 'modalConfirmClient';
        modal.className = 'modal-client-custom'; // Unique class

        // Fix for visibility: Force styles inline
        modal.style.cssText = 'position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 2147483647 !important;';

        modal.innerHTML = `
        <div style="background: white; padding: 0; border-radius: 20px; width: 400px; max-width: 90%; overflow: hidden; box-shadow: 0 10px 40px rgba(0,0,0,0.3); animation: modalSlideIn 0.3s ease;">
                <div style="background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%); color: white; padding: 25px; text-align: center;" id="headerConfirmClient">
                     <div style="width: 60px; height: 60px; background: rgba(255,255,255,0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 15px; border: 2px solid white;">
                        <svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                            <line x1="12" y1="9" x2="12" y2="13"></line>
                            <line x1="12" y1="17" x2="12.01" y2="17"></line>
                        </svg>
                     </div>
                     <h2 id="tituloConfirmClient" style="margin: 0; font-size: 22px;">${titulo}</h2>
                </div>
                <div style="padding: 30px 25px; text-align: center;">
                    <p id="msgConfirmClient" style="font-size: 16px; color: #555; margin-bottom: 25px;">${mensaje}</p>
                    <div style="display: flex; justify-content: center; gap: 10px;">
                        <button id="btnCancelarClient" style="padding: 10px 20px; border: none; border-radius: 8px; cursor: pointer; background: #eee; color: #333;">Cancelar</button>
                        <button id="btnAceptarClient" style="
                            background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
                            color: white; border: none; padding: 10px 20px; border-radius: 8px; cursor: pointer;
                            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
                        ">${btnText}</button>
                    </div>
                </div>
            </div >
        `;

        // Add minimal animation style if not present
        if (!document.getElementById('modalAnimStyle')) {
            const style = document.createElement('style');
            style.id = 'modalAnimStyle';
            style.innerHTML = `@keyframes modalSlideIn { from {opacity: 0; transform: translateY(-20px);} to {opacity: 1; transform: translateY(0);} }`;
            document.head.appendChild(style);
        }

        document.body.appendChild(modal);
    }

    document.getElementById('tituloConfirmClient').textContent = titulo;
    document.getElementById('msgConfirmClient').textContent = mensaje;

    const btnCancel = document.getElementById('btnCancelarClient');
    btnCancel.onclick = function () { modal.style.display = 'none'; };

    const btnAccept = document.getElementById('btnAceptarClient');
    btnAccept.textContent = btnText;

    if (btnStyle) {
        btnAccept.style.background = btnStyle;
        const header = document.getElementById('headerConfirmClient');
        header.style.background = btnStyle;
    }

    // Clonar para limpiar eventos previos
    const newBtn = btnAccept.cloneNode(true);
    btnAccept.parentNode.replaceChild(newBtn, btnAccept);

    newBtn.addEventListener('click', function () {
        modal.style.display = 'none';
        if (callbackAceptar) callbackAceptar();
    });

    // Ensure it is visible
    modal.style.setProperty('display', 'flex', 'important');
    modal.style.setProperty('visibility', 'visible', 'important');
    modal.style.setProperty('opacity', '1', 'important');
}






