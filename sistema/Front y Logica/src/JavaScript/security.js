(function () {
    // ══════════════════════════════════════════════
    // 0. BLOQUEO BÁSICO DE INTERACCIÓN
    // ══════════════════════════════════════════════
    // Se mantiene el clic derecho desactivado pero sin redirecciones.
    document.addEventListener('contextmenu', event => event.preventDefault());

    // ══════════════════════════════════════════════
    // 1. BLOQUEOS DE TECLADO
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
})();
