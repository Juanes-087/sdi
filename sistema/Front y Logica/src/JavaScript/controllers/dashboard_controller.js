/**
 * JavaScript/controllers/dashboard_controller.js
 * Controlador para gestionar el panel principal (Estadísticas, Usuarios, Empleados, etc)
 */

window.FormSchemas = window.FormSchemas || {};

const mapOptionsLocal = (list) => {
    if (!list) return [];
    return list.map(item => {
        if (typeof item === 'object' && item !== null) {
            if (item.label) return item;
            const id = item.id || item.id_documento || item.id_ciudad || item.id_cargo || item.id_tipo_sangre || item.id_banco || item.id_genero || item.id_instrumento || item.id_kit;
            const label = item.label || item.nom_tipo_docum || item.nom_ciudad || item.nom_cargo || item.nom_tip_sang || item.nom_banco || item.nom_genero || item.nom_instrumento || item.nom_kit;
            if (id && label) return { id, label };
        }
        return { id: item, label: item };
    });
};

/**
 * Obtiene la fecha actual en formato YYYY-MM-DD ajustada a la zona horaria de Bogotá (GMT-5)
 * Esto evita que cambios en el reloj local del computador permitan seleccionar fechas futuras de forma trivial
 */
const getTodayBogota = () => {
    try {
        const now = new Date();
        const formatter = new Intl.DateTimeFormat('sv-SE', {
            timeZone: 'America/Bogota',
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        });
        return formatter.format(now); // Retorna formato YYYY-MM-DD
    } catch (e) {
        // Fallback básico si Intl no soporta la zona horaria
        return new Date().toISOString().split('T')[0];
    }
};

window.FormSchemas['usuarios'] = (data = {}) => {
    const d = data || {};
    const f = [
        { label: 'Usuario', name: 'nom_user', type: 'text', value: d.nom_user, required: true, maxLength: 30, helpText: '3-30 caracteres.' },
        { label: 'Email', name: 'mail_user', type: 'email', value: d.mail_user, required: true, maxLength: 255, helpText: 'Correo electrónico válido.' },
        { label: 'Teléfono', name: 'tel_user', type: 'tel', value: d.tel_user, required: true, pattern: '[0-9]{7,10}', placeholder: '7-10 dígitos', maxLength: 10, helpText: 'Solo números, entre 7 y 10 dígitos.' }
    ];

    f.push({
        label: 'Contraseña', name: 'pass_user', type: 'password', value: '', required: true, placeholder: 'Min. 6 car., 1 Mayus, 1 Num', pattern: '(?=.*[0-9])(?=.*[A-Z]).{6,}'
    });
    return f;
};
window.FormSchemas['nuevos_mes'] = window.FormSchemas['usuarios'];

window.FormSchemas['clientes'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};
    return [
        { label: 'Tipo Documento', name: 'nom_documento', type: 'select', options: mapOptionsLocal(aux.documentos), value: d.id_documento || d.nom_documento, required: true },
        { label: 'Número Documento', name: 'num_documento', type: 'text', value: d.num_documento, required: true, pattern: '[a-zA-Z0-9-]{5,20}', maxLength: 20, helpText: '5-20 caracteres (letras, números o guiones).' },
        { label: 'Primer Nombre', name: 'prim_nom', type: 'text', value: d.prim_nom || (d.nombre_completo ? d.nombre_completo.split(' ')[0] : ''), required: true, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]+', maxLength: 30, helpText: 'Solo letras (Máx 30).' },
        { label: 'Segundo Nombre', name: 'segun_nom', type: 'text', value: d.segun_nom || '', required: false, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]*', maxLength: 30 },
        { label: 'Primer Apellido', name: 'prim_apell', type: 'text', value: d.prim_apell || (d.nombre_completo ? d.nombre_completo.split(' ')[1] : ''), required: true, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]+', maxLength: 30, helpText: 'Solo letras (Máx 30).' },
        { label: 'Segundo Apellido', name: 'segun_apell', type: 'text', value: d.segun_apell || '', required: false, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]*', maxLength: 30 },
        { label: 'Teléfono', name: 'tel_cliente', type: 'tel', value: d.tel_cliente, required: true, pattern: '[0-9]{7,10}', maxLength: 10, helpText: 'Solo números (7-10 dígitos).' },
        { label: 'Género', name: 'ind_genero', type: 'select', options: mapOptionsLocal(aux.generos), value: d.ind_genero || d.id_genero || d.nom_genero, required: true },
        { label: 'Ciudad', name: 'nom_ciudad', type: 'datalist', options: mapOptionsLocal(aux.ciudades), value: d.id_ciudad || d.nom_ciudad, required: true },
        { label: 'Dirección', name: 'dir_cliente', type: 'text', value: d.dir_cliente, required: true, fullWidth: true },
        { label: 'Profesión', name: 'ind_profesion', type: 'text', value: d.ind_profesion, required: true, fullWidth: true }
    ];
};

window.FormSchemas['empleados'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};
    // Convertir puntos a comas para los campos de texto que lo requieren (Peso y Altura provienen de la DB como numéricos con punto)
    const weightValue = d.ind_peso ? String(d.ind_peso).replace('.', ',') : '';
    const heightValue = d.ind_altura ? String(d.ind_altura).replace('.', ',') : '';
    const today = getTodayBogota();

    return [
        { label: 'Tipo Documento', name: 'nom_documento', type: 'select', options: mapOptionsLocal(aux.documentos), value: d.id_documento || d.nom_documento || '', required: true },
        { label: 'Número Documento', name: 'num_documento', type: 'text', value: d.num_documento || '', required: true, pattern: '[a-zA-Z0-9-]{5,20}', maxLength: 20, helpText: 'Solo números/letras, entre 5 y 20 dígitos.' },
        { label: 'Primer Nombre', name: 'prim_nom', type: 'text', value: d.prim_nom || '', required: true, maxLength: 30, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]+', helpText: 'Solo letras (Máx 30).' },
        { label: 'Segundo Nombre', name: 'segun_nom', type: 'text', value: d.segun_nom || '', required: false, maxLength: 30, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]*' },
        { label: 'Primer Apellido', name: 'prim_apell', type: 'text', value: d.prim_apell || '', required: true, maxLength: 30, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]+', helpText: 'Solo letras (Máx 30).' },
        { label: 'Segundo Apellido', name: 'segun_apell', type: 'text', value: d.segun_apell || '', required: false, maxLength: 30, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ\\s]*' },
        { label: 'Fecha Contratación', name: 'ind_fecha_contratacion', type: 'date', value: d.ind_fecha_contratacion || '', required: true, min: '2000-01-01', max: today },
        { label: 'Tipo Sangre', name: 'nom_tipo_sangre', type: 'select', options: mapOptionsLocal(aux.sangre), value: d.id_tipo_sangre || d.nom_tipo_sangre || '', required: true },
        { label: 'Teléfono', name: 'tel_empleado', type: 'tel', value: d.tel_empleado || '', required: true, pattern: '[0-9]{7,10}', maxLength: 10, helpText: 'Solo números (7-10 dígitos).' },
        { label: 'Email', name: 'mail_empleado', type: 'email', value: d.mail_empleado || '', required: true, maxLength: 255 },
        { label: 'Ciudad', name: 'nom_ciudad', type: 'datalist', options: mapOptionsLocal(aux.ciudades), value: d.id_ciudad || d.nom_ciudad || '', required: true },
        { label: 'Dirección', name: 'dir_emple', type: 'text', value: d.dir_emple || '', required: true },
        { label: 'Género', name: 'ind_genero', type: 'select', options: mapOptionsLocal(aux.generos), value: d.ind_genero || d.id_genero || d.nom_genero || '', required: true },
        { label: 'Cargo', name: 'nom_cargo', type: 'select', options: mapOptionsLocal(aux.cargos), value: d.id_cargo || d.nom_cargo || '', required: true },
        { label: 'Banco', name: 'nom_banco', type: 'select', options: mapOptionsLocal(aux.bancos), value: d.id_banco || d.nom_banco || '', required: true },
        { label: 'No. Cuenta', name: 'num_cuenta', type: 'text', value: d.num_cuenta || '', required: true, pattern: '[0-9]{10,20}', maxLength: 20, helpText: 'Solo números, entre 10 y 20 dígitos.' },
        { label: 'Peso (Kg)', name: 'ind_peso', type: 'text', value: weightValue, required: true, pattern: '^[0-9]+(,[0-9]+)?$', helpText: 'Solo números y coma (ej: 70,5).' },
        { label: 'Altura (m)', name: 'ind_altura', type: 'text', value: heightValue, required: true, pattern: '^[0-9]+(,[0-9]+)?$', helpText: 'Solo números y coma (ej: 1,70).' },
        { label: 'Últ. Examen', name: 'ult_fec_exam', type: 'date', value: d.ult_fec_exam || '', required: true, max: today },
        { label: 'Observaciones', name: 'observ', type: 'textarea', value: d.observ || '', required: false, fullWidth: true }
    ];
};

window.FormSchemas['proveedores'] = (data = {}) => {
    const d = data || {};
    const aux = window.auxiliares || {};
    return [
        { label: 'Tipo Documento', name: 'nom_documento', type: 'select', options: mapOptionsLocal(aux.documentos), value: d.id_documento || d.nom_documento, required: true },
        { label: 'NIT / Documento', name: 'num_documento', type: 'text', value: d.num_documento, required: true, pattern: '[a-zA-Z0-9-]{5,20}', maxLength: 20 },
        { label: 'Razón Social / Nombre', name: 'nom_prov', type: 'text', value: d.nom_prov, required: true, fullWidth: true, pattern: '[a-zA-ZñÑáéíóúÁÉÍÓÚ0-9\\s\\.\\-]+', maxLength: 50, helpText: 'Proveedores pueden incluir números si es Razón Social (Máx 50).' },
        { label: 'Teléfono', name: 'tel_prov', type: 'tel', value: d.tel_prov, required: true, pattern: '[0-9]{7,10}', maxLength: 10, helpText: 'Solo números (7-10 dígitos).' },
        { label: 'Email', name: 'mail_prov', type: 'email', value: d.mail_prov, required: true, maxLength: 255 },
        { label: 'Ciudad', name: 'nom_ciudad', type: 'datalist', options: mapOptionsLocal(aux.ciudades), value: d.id_ciudad || d.nom_ciudad, required: true },
        { label: 'Calidad', name: 'ind_calidad', type: 'text', value: d.ind_calidad, required: false },
        { label: 'Dirección', name: 'dir_prov', type: 'text', value: d.dir_prov, required: true, fullWidth: true }
    ];
};



window.ValidationRules['nom_documento'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "Seleccione un tipo de documento." };
        return { valid: true, msg: "Seleccionado." };
    }
};

window.ValidationRules['nom_ciudad'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "Seleccione una ciudad." };
        
        // Verificar si la ciudad existe en los auxiliares
        const cities = window.auxiliares?.ciudades || [];
        const exists = cities.some(c => 
            (c.nom_ciudad && c.nom_ciudad.toLowerCase() === val.trim().toLowerCase()) ||
            (c.label && c.label.toLowerCase() === val.trim().toLowerCase())
        );
        
        if (!exists) return { valid: false, msg: "Ciudad no reconocida. Seleccione de la lista." };
        return { valid: true, msg: "Ciudad válida." };
    }
};

window.ValidationRules['nom_cargo'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "Seleccione un cargo." };
        return { valid: true, msg: "Cargo seleccionado." };
    }
};

window.ValidationRules['ind_genero'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "Seleccione un género." };
        return { valid: true, msg: "Género seleccionado." };
    }
};

window.ValidationRules['nom_banco'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "Seleccione un banco." };
        return { valid: true, msg: "Banco seleccionado." };
    }
};

window.ValidationRules['nom_tipo_sangre'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "Seleccione tipo de sangre." };
        return { valid: true, msg: "Válido." };
    }
};

window.ValidationRules['dir_emple'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "La dirección es obligatoria." };
        if (val.length < 5) return { valid: false, msg: "Dirección demasiado corta." };
        return { valid: true, msg: "Válido." };
    }
};

window.ValidationRules['num_documento'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "El número de documento es obligatorio." };
        if (!/^[a-zA-Z0-9-]+$/.test(val)) return { valid: false, msg: "Solo letras, números y guiones." };
        if (val.length < 5 || val.length > 20) return { valid: false, msg: "Debe tener entre 5 y 20 caracteres." };
        return { valid: true, msg: "Formato válido." };
    }
};

window.ValidationRules['prim_nom'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "El primer nombre es obligatorio." };
        if (!/^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$/.test(val)) return { valid: false, msg: "Solo letras y espacios." };
        if (val.length < 3 || val.length > 30) return { valid: false, msg: "Entre 3 y 30 caracteres." };
        return { valid: true, msg: "Nombre válido." };
    }
};

window.ValidationRules['segun_nom'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: true, msg: "" };
        if (!/^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$/.test(val)) return { valid: false, msg: "Solo letras y espacios." };
        if (val.length < 3 || val.length > 30) return { valid: false, msg: "Entre 3 y 30 caracteres." };
        return { valid: true, msg: "Válido." };
    }
};

window.ValidationRules['prim_apell'] = window.ValidationRules['prim_nom'];
window.ValidationRules['segun_apell'] = window.ValidationRules['segun_nom'];

window.ValidationRules['mail_empleado'] = {
    validate: (val) => {
        if (!val || val.trim() === '') return { valid: false, msg: "El email es obligatorio." };
        if (!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(val)) return { valid: false, msg: "Formato de email inválido." };
        if (val.length > 255) return { valid: false, msg: "Máximo 255 caracteres." };
        return { valid: true, msg: "Email válido." };
    }
};

window.ValidationRules['tel_empleado'] = {
    validate: (val) => {
        const clean = val.replace(/\D/g, '');
        if (clean.length < 7 || clean.length > 10) return { valid: false, msg: "Debe tener entre 7 y 10 dígitos." };
        return { valid: true, msg: "Teléfono válido." };
    }
};

window.ValidationRules['num_cuenta'] = {
    validate: (val) => {
        const clean = val.replace(/\D/g, '');
        if (clean.length < 10 || clean.length > 20) return { valid: false, msg: "Entre 10 y 20 dígitos numéricos." };
        return { valid: true, msg: "Número de cuenta válido." };
    }
};


window.ValidationRules['ind_peso'] = {
    validate: (val) => {
        const num = parseFloat(String(val).replace(',', '.'));
        if (isNaN(num)) return { valid: false, msg: "Ingrese el peso (ej: 70)." };
        if (num <= 40 || num >= 200) return { valid: false, msg: "El peso debe estar entre 40 y 200 kg." };
        return { valid: true, msg: "Peso válido." };
    }
};

window.ValidationRules['ind_altura'] = {
    validate: (val) => {
        const num = parseFloat(String(val).replace(',', '.'));
        if (isNaN(num)) return { valid: false, msg: "Ingrese la altura (ej: 1,70)." };
        if (num <= 1.30 || num >= 2.50) return { valid: false, msg: "La altura debe estar entre 1.30 y 2.50 m." };
        return { valid: true, msg: "Altura válida." };
    }
};

window.ValidationRules['ult_fec_exam'] = {
    validate: (val) => {
        if (!val) return { valid: false, msg: "La fecha de examen es obligatoria." };
        const d = new Date(val);
        const bogotaDateStr = getTodayBogota();
        const [year, month, day] = bogotaDateStr.split('-').map(Number);
        const nowBogota = new Date(year, month - 1, day, 23, 59, 59, 999);
        
        if (d > nowBogota) {
            return { valid: false, msg: "La fecha del examen NO puede ser futura." };
        }
        return { valid: true, msg: "Fecha válida." };
    }
};

window.ValidationRules['ind_fecha_contratacion'] = {
    validate: (val) => {
        if (!val) return { valid: false, msg: "La fecha de contratación es obligatoria." };
        const d = new Date(val);
        if (d < new Date('2000-01-01')) return { valid: false, msg: "La fecha mínima es el año 2000." };
        return { valid: true, msg: "Fecha válida." };
    }
};
