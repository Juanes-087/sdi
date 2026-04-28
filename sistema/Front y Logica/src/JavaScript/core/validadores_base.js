/**
 * JavaScript/core/validadores_base.js
 * Sistema centralizado de validaciones base
 * Los controladores pueden inyectar reglas especificas en window.ValidationRules
 */

window.ValidationRules = window.ValidationRules || {};

const validationUtils = {
    isNegative: (val) => {
        const n = parseFloat(val);
        return !isNaN(n) && n < 0;
    }
};

window.validationUtils = validationUtils;

// Reglas Genéricas Globales
Object.assign(window.ValidationRules, {
    text_generic: {
        validate: (val) => {
            if (!val || val.trim() === '') return { valid: false, msg: "Requerido." };
            return { valid: true, msg: "Válido." };
        }
    },
    numeric_generic: {
        validate: (val) => {
            if (validationUtils.isNegative(val)) return { valid: false, msg: "No puede ser menor al mínimo." };
            return { valid: true, msg: "Válido." };
        }
    }
});

/**
 * Inicializa las validaciones dinámicas para un formulario dado
 * @param {HTMLFormElement} form 
 */
function initFormValidations(form) {
    if (!form) return;

    const inputs = form.querySelectorAll('input, select, textarea');

    inputs.forEach(input => {
        if (input.type === 'hidden' || input.type === 'submit' || input.type === 'button') return;

        let msg = input.nextElementSibling;
        if (!msg || !msg.classList.contains('validation-msg')) {
            msg = document.createElement('div');
            msg.className = 'validation-msg';
            input.parentNode.insertBefore(msg, input.nextSibling);
        }

        input.addEventListener('input', () => validateField(input, msg, form));
        input.addEventListener('blur', () => {
            if (msg.classList.contains('success')) {
                setTimeout(() => msg.style.display = 'none', 2000);
            }
        });
        input.addEventListener('focus', () => {
            validateField(input, msg, form);
        });
    });
}

/**
 * Valida un campo específico contra el registro de reglas globales
 */
function validateField(input, msg, form) {
    const name = input.getAttribute('data-validate-as') || input.name;
    const val = input.value;
    let result = { valid: true, msg: "" };

    // Si existe una regla con el nombre del input en window.ValidationRules, la usamos
    if (window.ValidationRules && window.ValidationRules[name]) {
        result = window.ValidationRules[name].validate(val);

        // --- CROSSLINKS ESPÉCIFICOS QUE ANTES ESTABAN "HARDCODEADOS" EN VALIDATIONS.JS ---
        // Cross validation especial para stock min/max (Se inyectan si el formulario las tiene)
        if (name === 'cant_disp' && result.valid) {
            const minInput = form.querySelector('input[name="stock_min"]');
            const maxInput = form.querySelector('input[name="stock_max"]');
            const n = parseInt(val);
            if (minInput && minInput.value && n < parseInt(minInput.value)) {
                result = { valid: false, msg: `No puede ser menor al Mínimo (${minInput.value}).` };
            } else if (maxInput && maxInput.value && n > parseInt(maxInput.value)) {
                result = { valid: false, msg: `No puede exceder el Máximo (${maxInput.value}).` };
            }
        }
        if (name === 'stock_min') {
            const maxInput = form.querySelector('input[name="stock_max"]');
            if (maxInput && maxInput.value && parseInt(val) > parseInt(maxInput.value)) {
                result = { valid: false, msg: "No puede ser mayor al Stock Máximo." };
            }
            revalidateNeighbor(form, 'cant_disp');
        }
        if (name === 'stock_max') {
            const minInput = form.querySelector('input[name="stock_min"]');
            if (minInput && minInput.value && parseInt(val) < parseInt(minInput.value)) {
                result = { valid: false, msg: "No puede ser menor al Stock Mínimo." };
            }
            revalidateNeighbor(form, 'cant_disp');
            revalidateNeighbor(form, 'cant_mat_prima');
        }
        if (name === 'cant_mat_prima') {
            const n = parseInt(val);
            const maxInput = form.querySelector('input[name="stock_max"]');
            let maxVal = maxInput && maxInput.value ? parseInt(maxInput.value) : 10000;
            if (maxVal > 0 && n > maxVal) result = { valid: false, msg: `No puede exceder el Máximo (${maxVal}).` };
        }
    }
    // Fallbacks si no hay regla específica
    else {
        if (input.required && (!val || val.trim() === '')) {
            result = { valid: false, msg: "Este campo es obligatorio." };
        } else if (val) {
            if (input.type === 'number') {
                const numVal = parseFloat(val);
                if (validationUtils.isNegative(val)) {
                    result = { valid: false, msg: "No puede ser negativo." };
                } else if (input.hasAttribute('min') && numVal < parseFloat(input.min)) {
                    result = { valid: false, msg: `El mínimo es ${input.min}.` };
                } else if (input.hasAttribute('max') && numVal > parseFloat(input.max)) {
                    result = { valid: false, msg: `El máximo es ${input.max}.` };
                }
            } else {
                if (input.hasAttribute('maxLength') && input.maxLength > 0 && val.length > input.maxLength) {
                    result = { valid: false, msg: `Máximo ${input.maxLength} caracteres.` };
                }
            }
        }
    }

    applyValidationResult(input, msg, result);
    return result.valid;
}

function revalidateNeighbor(form, neighborName) {
    const input = form.querySelector(`input[name="${neighborName}"]`);
    if (input && input.value) {
        const msg = input.nextElementSibling;
        if (msg && msg.classList.contains('validation-msg')) {
            validateField(input, msg, form);
        }
    }
}

function applyValidationResult(input, msg, result) {
    msg.textContent = result.msg;
    msg.style.display = 'block';

    if (result.valid) {
        input.classList.remove('input-error');
        input.classList.add('input-success');
        msg.classList.remove('error');
        msg.classList.add('success');
    } else {
        input.classList.remove('input-success');
        input.classList.add('input-error');
        msg.classList.remove('success');
        msg.classList.add('error');
    }
}

function checkFormValidity(form) {
    let isValid = true;
    const inputs = form.querySelectorAll('input, select, textarea');
    inputs.forEach(input => {
        if (input.type === 'hidden' || input.type === 'submit' || input.type === 'button') return;
        const msg = input.nextElementSibling;
        if (msg && msg.classList.contains('validation-msg')) {
            if (!validateField(input, msg, form)) isValid = false;
        }
    });

    if (!form.checkValidity()) {
        form.reportValidity();
        isValid = false;
    }
    return isValid;
}

window.initFormValidations = initFormValidations;
window.checkFormValidity = checkFormValidity;






