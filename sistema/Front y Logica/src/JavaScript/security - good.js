(function () {
    // ══════════════════════════════════════════════
    // 0. BLOQUEO BÁSICO DE INTERACCIÓN
    // ══════════════════════════════════════════════
    // Se mantiene el clic derecho desactivado pero sin redirecciones.
    document.addEventListener('contextmenu', event => event.preventDefault());

    // ══════════════════════════════════════════════
    // 1. IDENTIFICACIÓN DE RUTA Y CONTEXTO
    // ══════════════════════════════════════════════
    const fullPath = window.location.pathname.toLowerCase();
    
    function killPage() {
        console.warn("Detección de herramientas de desarrollo activada.");
        // Ya no matamos la página ni redirigimos a Google para evitar bloqueos accidentales.
    }

    function handleDevToolsDetection() {
        // En lugar de redirigir a Google, simplemente mostramos una advertencia en consola
        // o realizamos una acción menos destructiva.
        console.warn("Herramientas de desarrollo detectadas.");
        // window.location.replace('https://www.google.com'); // ELIMINADO: Bloqueaba al desarrollador
    }

    // ══════════════════════════════════════════════
    // 2. DETECCIÓN RELAJADA
    // ══════════════════════════════════════════════
    
    // Trampa de Debugger: Desactivada temporalmente para evitar bloqueos por zoom o lentitud
    /*
    const runDebuggerTrap = () => {
        const startTime = performance.now();
        debugger;
        const endTime = performance.now();
        if (endTime - startTime > 100) {
            handleDevToolsDetection();
        }
    };
    setInterval(runDebuggerTrap, 2000); 
    */

    // Detección por tamaño: ELIMINADA. 
    // Es la causante del bloqueo al hacer zoom.
    /*
    const threshold = 160;
    const checkResize = () => {
        if (window.outerWidth - window.innerWidth > threshold || window.outerHeight - window.innerHeight > threshold) {
            handleDevToolsDetection();
        }
    };
    window.addEventListener('resize', checkResize);
    */

    // ══════════════════════════════════════════════
    // 3. BLOQUEOS DE TECLADO
    // ══════════════════════════════════════════════
    document.addEventListener('keydown', function (e) {
        const forbiddenKeys = ['F12', 123];
        const isForbiddenShortcut = (e.ctrlKey && e.shiftKey && ['I', 'J', 'C'].includes(e.key.toUpperCase())) ||
                                    (e.ctrlKey && e.key.toUpperCase() === 'U');
        
        if (forbiddenKeys.includes(e.key) || forbiddenKeys.includes(e.keyCode) || isForbiddenShortcut) {
            e.preventDefault();
            console.info("Acceso a herramientas de desarrollo restringido.");
        }
    });

    // Bloqueo de historial: Relajado para permitir navegación normal
    /*
    window.history.pushState(null, null, window.location.href);
    window.onpopstate = function () {
        window.history.pushState(null, null, window.location.href);
    };
    */

    // Silenciar consola: Desactivado para permitir depuración básica en desarrollo
    /*
    if (typeof console !== 'undefined') {
        const methods = ['log', 'debug', 'info', 'warn', 'error', 'table', 'clear'];
        methods.forEach(method => {
            Object.defineProperty(console, method, {
                get: function() { return () => {}; },
                set: function() {}
            });
        });
    }
    */

})();
