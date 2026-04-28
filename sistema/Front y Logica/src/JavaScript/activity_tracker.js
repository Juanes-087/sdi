/**
 * Activity Tracker - Mantiene la sesión viva mientras el usuario interactúe.
 * 
 * Monitorea eventos de mouse, teclado y scroll para enviar un "heartbeat"
 * al servidor y refrescar el token JWT antes de que expire.
 */

(function() {
    let lastRefresh = Date.now();
    const REFRESH_INTERVAL = 5 * 60 * 1000; // Refrescar máximo cada 5 minutos
    let isRefreshing = false;

    /**
     * Determina la ruta correcta hacia el script de refresh según la ubicación actual
     */
    function getRefreshPath() {
        const fullPath = window.location.pathname.toLowerCase();
        if (fullPath.includes('/src/php/')) {
            return 'refrescar_sesion.php';
        } else if (fullPath.includes('/html/')) {
            return '../src/php/refrescar_sesion.php';
        } else {
            return 'src/php/refrescar_sesion.php';
        }
    }

    /**
     * Envía una petición al servidor para refrescar el token.
     */
    async function refreshSessionToken() {
        if (isRefreshing) return;
        
        const token = localStorage.getItem('token');
        if (!token) return;

        try {
            isRefreshing = true;
            const refreshUrl = getRefreshPath();

            const response = await fetch(refreshUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({ token: token })
            });

            const data = await response.json();

            if (data.success && data.token) {
                localStorage.setItem('token', data.token);
                lastRefresh = Date.now();
                
                // Si existe la función de verificación en logica.js, la llamamos para actualizar el timer
                if (typeof window.verificarExpiracionTokenAdmin === 'function') {
                    window.verificarExpiracionTokenAdmin();
                }
            }
        } catch (error) {
            // Silencio en errores de red para no molestar al usuario
        } finally {
            isRefreshing = false;
        }
    }

    /**
     * Manejador de eventos de actividad.
     * Throttled para no saturar el servidor.
     */
    function handleActivity() {
        const now = Date.now();
        if (now - lastRefresh > REFRESH_INTERVAL) {
            refreshSessionToken();
        }
    }

    // Registrar eventos de interacción humana
    const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'];
    events.forEach(name => {
        document.addEventListener(name, handleActivity, { passive: true });
    });

    console.log("[Activity] Rastreador de actividad iniciado.");
})();
