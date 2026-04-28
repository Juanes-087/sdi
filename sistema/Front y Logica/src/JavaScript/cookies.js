/**
 * Sistema de gestión de cookies - OWASP Compliant
 * Manejo seguro de cookies con consentimiento del usuario
 */

class CookieManager {
    constructor() {
        this.cookieConsent = null;
        this.init();
    }

    init() {
        // Verificar si ya hay consentimiento
        this.cookieConsent = this.getCookie('cookie_consent');

        // Si no hay consentimiento, mostrar el modal cuando se haga clic en "Ingresar"
        if (!this.cookieConsent) {
            this.setupLoginButtonListener();
        }
    }

    setupLoginButtonListener() {
        const loginLinks = document.querySelectorAll(
            'a[href*="InicioSesion"], .btn-link[href*="InicioSesion"]'
        );

        loginLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                if (!this.cookieConsent) {
                    e.preventDefault();
                    this.showCookieConsentModal(link.href, link.target);
                }
            });
        });
    }


    showCookieConsentModal(redirectUrl = null, target = null) {
        // Crear modal si no existe
        let modal = document.getElementById('cookieConsentModal');

        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'cookieConsentModal';
            modal.className = 'cookie-modal';
            modal.innerHTML = `
                <div class="cookie-modal-content">
                    <div class="cookie-modal-header">
                        <h2>🍪 Política de Cookies</h2>
                    </div>
                    <div class="cookie-modal-body">
                        <p>Utilizamos cookies para mejorar tu experiencia en nuestro sitio web. Las cookies nos ayudan a:</p>
                        <ul>
                            <li>Recordar tus preferencias de sesión</li>
                            <li>Mejorar la seguridad de tu cuenta</li>
                            <li>Personalizar tu experiencia</li>
                        </ul>
                        <p><strong>¿Aceptas el uso de cookies?</strong></p>
                    </div>
                    <div class="cookie-modal-footer">
                        <button id="acceptCookies" class="btn-accept">Aceptar</button>
                        <button id="rejectCookies" class="btn-reject">Rechazar</button>
                    </div>
                </div>
            `;
            document.body.appendChild(modal);

            // Agregar estilos si no existen
            this.addCookieModalStyles();

            // Event listeners
            document.getElementById('acceptCookies').addEventListener('click', () => {
                this.acceptCookies(redirectUrl, target);
            });

            document.getElementById('rejectCookies').addEventListener('click', () => {
                this.rejectCookies(redirectUrl, target);
            });
        }

        modal.style.display = 'flex';
    }

    acceptCookies(redirectUrl = null, target = null) {
        // Guardar consentimiento
        this.setCookie('cookie_consent', 'accepted', 365); // 1 año
        this.setCookie('cookie_preferences', JSON.stringify({
            necessary: true,
            functional: true,
            analytics: false
        }), 365);

        this.cookieConsent = 'accepted';

        // Cerrar modal
        const modal = document.getElementById('cookieConsentModal');
        if (modal) {
            modal.style.display = 'none';
        }

        // Redirigir si hay URL
        if (redirectUrl) {
            if (target === '_blank') {
                window.open(redirectUrl, '_blank');
            } else {
                window.location.href = redirectUrl;
            }
        }
    }

    rejectCookies(redirectUrl = null, target = null) {
        // Guardar rechazo
        this.setCookie('cookie_consent', 'rejected', 365);
        this.setCookie('cookie_preferences', JSON.stringify({
            necessary: true,
            functional: false,
            analytics: false
        }), 365);

        this.cookieConsent = 'rejected';

        // Cerrar modal
        const modal = document.getElementById('cookieConsentModal');
        if (modal) {
            modal.style.display = 'none';
        }

        // Redirigir si hay URL (aunque rechace, puede usar la página)
        if (redirectUrl) {
            if (target === '_blank') {
                window.open(redirectUrl, '_blank');
            } else {
                window.location.href = redirectUrl;
            }
        }
    }

    setCookie(name, value, days) {
        const expires = new Date();
        expires.setTime(expires.getTime() + (days * 24 * 60 * 60 * 1000));

        // Configuración segura de cookies
        const cookieString = `${name}=${encodeURIComponent(value)};expires=${expires.toUTCString()};path=/;SameSite=Strict`;
        document.cookie = cookieString;
    }

    getCookie(name) {
        const nameEQ = name + "=";
        const ca = document.cookie.split(';');

        for (let i = 0; i < ca.length; i++) {
            let c = ca[i];
            while (c.charAt(0) === ' ') c = c.substring(1, c.length);
            if (c.indexOf(nameEQ) === 0) {
                return decodeURIComponent(c.substring(nameEQ.length, c.length));
            }
        }
        return null;
    }

    deleteCookie(name) {
        document.cookie = `${name}=;expires=Thu, 01 Jan 1970 00:00:00 UTC;path=/;`;
    }

    addCookieModalStyles() {
        if (document.getElementById('cookieModalStyles')) return;

        const style = document.createElement('style');
        style.id = 'cookieModalStyles';
        style.textContent = `
            .cookie-modal {
                display: none;
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background-color: rgba(0, 0, 0, 0.7);
                z-index: 10000;
                justify-content: center;
                align-items: center;
                animation: fadeIn 0.3s ease;
            }
            
            .cookie-modal-content {
                background: white;
                border-radius: 10px;
                max-width: 500px;
                width: 90%;
                max-height: 90vh;
                overflow-y: auto;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.3);
                animation: slideUp 0.3s ease;
            }
            
            .cookie-modal-header {
                padding: 20px;
                border-bottom: 1px solid #eee;
                background: linear-gradient(to right, #36498f, #087d4e);
                color: white;
                border-radius: 10px 10px 0 0;
            }
            
            .cookie-modal-header h2 {
                margin: 0;
                font-size: 24px;
            }
            
            .cookie-modal-body {
                padding: 20px;
            }
            
            .cookie-modal-body ul {
                margin: 15px 0;
                padding-left: 20px;
            }
            
            .cookie-modal-body li {
                margin: 8px 0;
            }
            
            .cookie-modal-footer {
                padding: 20px;
                border-top: 1px solid #eee;
                display: flex;
                gap: 10px;
                justify-content: flex-end;
            }
            
            .btn-accept, .btn-reject {
                padding: 12px 24px;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                font-size: 16px;
                font-weight: bold;
                transition: all 0.3s ease;
            }
            
            .btn-accept {
                background: linear-gradient(to right, #36498f, #087d4e);
                color: white;
            }
            
            .btn-accept:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(54, 73, 143, 0.4);
            }
            
            .btn-reject {
                background: #f0f0f0;
                color: #333;
            }
            
            .btn-reject:hover {
                background: #e0e0e0;
            }
            
            @keyframes fadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
            }
            
            @keyframes slideUp {
                from {
                    transform: translateY(50px);
                    opacity: 0;
                }
                to {
                    transform: translateY(0);
                    opacity: 1;
                }
            }
        `;
        document.head.appendChild(style);
    }
}

// Inicializar el gestor de cookies
const cookieManager = new CookieManager();







