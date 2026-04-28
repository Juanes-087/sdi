/**
 * JavaScript/core/api_service.js
 * Servicio centralizado para peticiones al backend
 */

const ApiService = {
    /**
     * Realiza una petición GET genérica
     * @param {string} url La URL a la que se hace la petición (relativa o absoluta)
     * @returns {Promise<any>} Promesa con los datos JSON o lanza un error
     */
    get: async (url) => {
        try {
            const response = await fetch(url);
            if (response.status === 401) {
                if (window.UIComponents) window.UIComponents.showSessionExpired();
                throw new Error('Sesión Expirada');
            }
            if (!response.ok) {
                let errorData;
                try {
                    errorData = await response.json();
                } catch (e) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                throw new Error(errorData.error || errorData.message || `HTTP error! status: ${response.status}`);
            }
            const data = await response.json();
            return data;
        } catch (error) {
            console.error('[ApiService] GET Error:', error);
            throw error;
        }
    },

    /**
     * Realiza una petición POST genérica (enviando JSON)
     * @param {string} url La URL a la que se hace la petición
     * @param {object} payload El objeto a enviar
     * @returns {Promise<any>} Promesa con los datos JSON o lanza un error
     */
    postJson: async (url, payload) => {
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (response.status === 401) {
                if (window.UIComponents) window.UIComponents.showSessionExpired();
                throw new Error('Sesión Expirada');
            }
            if (!response.ok) {
                let errorData;
                try {
                    errorData = await response.json();
                } catch (e) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                throw new Error(errorData.error || errorData.message || `HTTP error! status: ${response.status}`);
            }
            const data = await response.json();
            return data;
        } catch (error) {
            console.error('[ApiService] POST JSON Error:', error);
            throw error;
        }
    },

    /**
     * Realiza una petición POST enviando FormData (útil para archivos e imágenes)
     * @param {string} url La URL a la que se hace la petición
     * @param {FormData} formData El objeto FormData a enviar
     * @returns {Promise<any>} Promesa con los datos JSON o lanza un error
     */
    postFormData: async (url, formData) => {
        try {
            // No se establece 'Content-Type' manualmente cuando se envía FormData,
            // el navegador lo hace automáticamente incluyendo el boundary.
            const response = await fetch(url, {
                method: 'POST',
                body: formData
            });
            if (response.status === 401) {
                if (window.UIComponents) window.UIComponents.showSessionExpired();
                throw new Error('Sesión Expirada');
            }
            if (!response.ok) {
                let errorData;
                try {
                    errorData = await response.json();
                } catch (e) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                throw new Error(errorData.error || errorData.message || `HTTP error! status: ${response.status}`);
            }
            const data = await response.json();
            return data;
        } catch (error) {
            console.error('[ApiService] POST FormData Error:', error);
            throw error;
        }
    },

    /**
     * Realiza una petición estandarizada al API Gestión (api_gestion.php)
     * @param {string} accion La acción a realizar ('create', 'update', 'delete', etc)
     * @param {string} tipo El tipo de entidad ('instrumentos', 'usuarios', etc)
     * @param {object|FormData} payload Datos a enviar (si es FormData se envía con postFormData)
     * @param {number|null} id ID opcional de la entidad (para update/delete)
     * @returns {Promise<any>}
     */
    fetchApiGestion: async (accion, tipo, payload = null, id = null) => {
        const url = './api_gestion.php';

        // GET (Para consultas de tablas por ejemplo)
        if (accion === 'read') {
            const idParam = id ? `&id=${id}` : '';
            return await ApiService.get(`${url}?tipo=${tipo}${idParam}`);
        }

        // Si es FormData
        if (payload instanceof FormData) {
            payload.append('accion', accion);
            payload.append('tipo', tipo);
            if (id) payload.append('id', id);
            return await ApiService.postFormData(url, payload);
        }

        // Si es JSON u otros POST
        const bodyObj = {
            accion: accion,
            tipo: tipo,
            ...(payload && typeof payload === 'object' ? { data: payload } : {})
        };
        if (id) bodyObj.id = id;

        return await ApiService.postJson(url, bodyObj);
    }
};

window.ApiService = ApiService;






