
document.addEventListener("DOMContentLoaded", function () {
    const form = document.getElementById("loginForm");

    if (form) {
        // ── Referencias a los modales de error ──
        const overlayError  = document.getElementById('modalErrorLogin');
        const boxError      = document.getElementById('modalErrorBox');
        const msgError      = document.getElementById('errorLoginMsg');
        const btnCerrarErr  = document.getElementById('btnCerrarErrorLogin');
        const overlayBrute  = document.getElementById('modalBruteForce');
        const countdownNum  = document.getElementById('countdownNum');
        const ringFill      = document.getElementById('ringFill');
        const btnCerrarBrute = document.getElementById('btnCerrarBrute');
        const CIRC = 238.76; // 2πr con r=38
        let bruteTimer = null;

        // Abrir modal de error de credenciales (con shake)
        function mostrarErrorCredenciales(msg) {
            msgError.innerHTML = msg || 'Usuario o contraseña incorrectos.<br>Verifica tus datos e inténtalo de nuevo.';
            overlayError.classList.add('visible');
            // Shake después de que la caja termina de aparecer
            setTimeout(() => boxError.classList.add('shake'), 350);
            boxError.addEventListener('animationend', () => boxError.classList.remove('shake'), { once: true });
        }

        // Cerrar modal de error
        if (btnCerrarErr) {
            btnCerrarErr.addEventListener('click', () => overlayError.classList.remove('visible'));
        }
        // Cerrar al hacer clic en el fondo
        if (overlayError) {
            overlayError.addEventListener('click', (e) => {
                if (e.target === overlayError) overlayError.classList.remove('visible');
            });
        }

        // Abrir modal de bloqueo con countdown en tiempo real
        function mostrarBruteForce(segundos) {
            clearInterval(bruteTimer);
            let restante = Math.max(0, segundos);
            const total  = restante;

            function actualizarRing() {
                const progreso = restante / total;               // 1 → 0
                const offset   = CIRC * (1 - progreso);         // 0 → CIRC
                ringFill.style.strokeDashoffset = offset;
                countdownNum.textContent = restante;

                if (restante <= 0) {
                    clearInterval(bruteTimer);
                    countdownNum.textContent = '0';
                    ringFill.style.strokeDashoffset = CIRC;
                    btnCerrarBrute.disabled = false;
                    btnCerrarBrute.textContent = 'Intentar de nuevo';
                }
            }

            actualizarRing();
            overlayBrute.classList.add('visible');

            bruteTimer = setInterval(() => {
                restante--;
                actualizarRing();
            }, 1000);
        }

        // Cerrar modal brute force (solo cuando el timer llega a 0)
        if (btnCerrarBrute) {
            btnCerrarBrute.addEventListener('click', () => {
                clearInterval(bruteTimer);
                overlayBrute.classList.remove('visible');
                btnCerrarBrute.disabled = true;
                btnCerrarBrute.textContent = 'Espera...';
                countdownNum.textContent = '--';
                ringFill.style.strokeDashoffset = '0';
            });
        }

        form.addEventListener("submit", function (e) {
            e.preventDefault();
            const formData = new FormData(form);

            const btn = form.querySelector('button[type="submit"]');
            const originalText = btn.innerHTML;
            btn.innerHTML = "Iniciando...";
            btn.disabled = true;

            fetch("../src/php/validar.php", {
                method: "POST",
                body: formData
            })
                .then(async res => {
                    const contentType = res.headers.get("content-type");
                    let data;

                    // Leer el texto primero para poder usarlo en caso de error
                    const text = await res.text();

                    // Intentar parsear JSON si el Content-Type lo indica
                    if (contentType && contentType.includes("application/json")) {
                        try {
                            data = JSON.parse(text);
                        } catch (e) {
                            console.error("Error al parsear JSON. Respuesta recibida:", text);
                            btn.innerHTML = originalText;
                            btn.disabled = false;
                            throw new Error("Error al procesar la respuesta del servidor.");
                        }
                    } else {
                        btn.innerHTML = originalText;
                        btn.disabled = false;
                        throw new Error("El servidor respondió con un formato incorrecto.");
                    }

                    // Si el servidor devuelve error, enriquecer con código HTTP
                    if (!data.success) {
                        btn.innerHTML = originalText;
                        btn.disabled = false;
                        const err = new Error(data.error || "Error en la solicitud");
                        err.httpStatus = res.status;
                        err.segundos   = data.segundos ?? null;
                        throw err;
                    }

                    return data;
                })
                .then(data => {
                    // Guardar el token en localStorage para los fetch posteriores
                    // (Authorization: Bearer). La URL de redirección ya NO lleva el
                    // token como parámetro: el servidor creó la sesión PHP en validar.php
                    // y envía la URL limpia en data.redirect.
                    localStorage.setItem("token", data.token);

                    if (data.redirect) {
                        window.location.replace(data.redirect);
                    } else {
                        mostrarErrorCredenciales('Menú no válido. Contacta al administrador.');
                        btn.innerHTML = originalText;
                        btn.disabled = false;
                    }
                    form.reset();
                })
                .catch(err => {
                    console.error("Error:", err);
                    btn.innerHTML = originalText;
                    btn.disabled = false;

                    // Brute force bloqueado (429) → modal con countdown
                    if (err.httpStatus === 429) {
                        // Extraer segundos del mensaje: "Espera 13 minuto(s)..."
                        // O usar data.segundos si el servidor lo envía
                        let segs = err.segundos;
                        if (!segs) {
                            const match = err.message.match(/(\d+)\s*minuto/);
                            segs = match ? parseInt(match[1]) * 60 : 900;
                        }
                        mostrarBruteForce(segs);
                        return;
                    }

                    // Error de credenciales (401) u otro → modal de error
                    mostrarErrorCredenciales(
                        (err.message || 'Error de conexión.')
                            .replace(/\./g, '.<br>')
                    );
                });
        });
    }

    // Manejo del formulario de REGISTRO
    const registerForm = document.getElementById("registerForm");
    if (registerForm) {
        // === VALIDACIONES EN TIEMPO REAL (Mensajes de Ayuda) ===
        // Validadores y mensajes
        const inputs = registerForm.querySelectorAll('input');

        inputs.forEach(input => {
            // Crear elemento para mensaje
            const msg = document.createElement("div");
            msg.className = "validation-msg";
            msg.style.display = "none";
            msg.style.fontSize = "11px";
            msg.style.color = "#666";
            msg.style.marginTop = "2px";
            msg.style.textAlign = "left";
            msg.style.width = "100%";
            msg.style.paddingLeft = "5px";
            input.parentNode.insertBefore(msg, input.nextSibling);

            input.addEventListener('focus', () => showHelp(input, msg));
            input.addEventListener('input', () => validateInput(input, msg));
            input.addEventListener('blur', () => msg.style.display = 'none');
        });

        function showHelp(input, msg) {
            msg.style.display = 'block';
            if (input.name === 'usuario') msg.textContent = "3-50 caracteres, letras y números.";
            if (input.name === 'mail_user') msg.textContent = "Ingresa un correo electrónico válido.";
            if (input.name === 'tel_user') msg.textContent = "Solo números (10 dígitos exactos).";
            if (input.name === 'password') msg.textContent = "Min. 8 caracteres, 1 Mayúscula, 1 Minúscula, 1 Número.";
            if (input.name === 'confirm_password') msg.textContent = "Debe coincidir con la contraseña.";
        }

        function validateInput(input, msg) {
            msg.style.display = 'block';
            let valid = true;

            // Usuario
            if (input.name === 'usuario') {
                if (!/^[a-zA-Z0-9_]{3,50}$/.test(input.value)) {
                    msg.style.color = "#dc3545";
                    msg.textContent = "3-50 caracteres, sin espacios especiales.";
                    valid = false;
                } else {
                    msg.style.color = "#087d4e";
                    msg.textContent = "Usuario válido.";
                }
            }
            // Email
            if (input.name === 'mail_user') {
                if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input.value)) {
                    msg.style.color = "#dc3545";
                    msg.textContent = "Correo inválido.";
                    valid = false;
                } else {
                    msg.style.color = "#087d4e";
                    msg.textContent = "Correo válido.";
                }
            }
            // Teléfono
            if (input.name === 'tel_user') {
                if (!/^[0-9]{10}$/.test(input.value)) {
                    msg.style.color = "#dc3545";
                    msg.textContent = "Debe tener exactamente 10 dígitos numéricos.";
                    valid = false;
                } else {
                    msg.style.color = "#087d4e";
                    msg.textContent = "Teléfono válido.";
                }
            }
            // Password
            if (input.name === 'password') {
                const val = input.value;
                if (val.length < 8 || !/[A-Z]/.test(val) || !/[a-z]/.test(val) || !/[0-9]/.test(val)) {
                    msg.style.color = "#dc3545";
                    // Mensaje detallado
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
            }
            // Confirm Password
            if (input.name === 'confirm_password') {
                const passwordInput = registerForm.querySelector('input[name="password"]');
                if (input.value !== passwordInput.value) {
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
            }
            return valid;
        }

        // Toggle Password Logic
        const togglePwd = document.getElementById('togglePassword');
        const pwdInput = document.getElementById('regPassword');
        if (togglePwd && pwdInput) {
            togglePwd.addEventListener('click', function () {
                // Toggle type
                const type = pwdInput.getAttribute('type') === 'password' ? 'text' : 'password';
                pwdInput.setAttribute('type', type);

                // Toggle icon with animation
                this.classList.toggle('fa-eye');
                this.classList.toggle('fa-eye-slash');

                // Simple animation effect
                this.style.transform = "translateY(-50%) scale(1.2)";
                setTimeout(() => {
                    this.style.transform = "translateY(-50%) scale(1)";
                }, 200);
            });
        }

        // Toggle Confirm Password Logic
        const toggleConfirmPwd = document.getElementById('toggleConfirmPassword');
        const confirmPwdInput = document.getElementById('regConfirmPassword');
        if (toggleConfirmPwd && confirmPwdInput) {
            toggleConfirmPwd.addEventListener('click', function () {
                // Toggle type
                const type = confirmPwdInput.getAttribute('type') === 'password' ? 'text' : 'password';
                confirmPwdInput.setAttribute('type', type);

                // Toggle icon with animation
                this.classList.toggle('fa-eye');
                this.classList.toggle('fa-eye-slash');

                // Simple animation effect
                this.style.transform = "translateY(-50%) scale(1.2)";
                setTimeout(() => {
                    this.style.transform = "translateY(-50%) scale(1)";
                }, 200);
            });
        }

        // Toggle Password Logic (LOGIN)
        const toggleLoginPwd = document.getElementById('toggleLoginPassword');
        const loginPwdInput = document.getElementById('loginPassword');
        if (toggleLoginPwd && loginPwdInput) {
            toggleLoginPwd.addEventListener('click', function () {
                // Toggle type
                const type = loginPwdInput.getAttribute('type') === 'password' ? 'text' : 'password';
                loginPwdInput.setAttribute('type', type);

                // Toggle icon with animation
                this.classList.toggle('fa-eye');
                this.classList.toggle('fa-eye-slash');

                // Simple animation effect
                this.style.transform = "translateY(-50%) scale(1.2)";
                setTimeout(() => {
                    this.style.transform = "translateY(-50%) scale(1)";
                }, 200);
            });
        }

        registerForm.addEventListener("submit", function (e) {
            e.preventDefault();

            // === VALIDACIÓN FINAL ANTES DE ENVIAR ===
            let allValid = true;
            const inputs = registerForm.querySelectorAll('input');
            inputs.forEach(input => {
                // Validación para inputs normales (usuario, email, tel)
                // Estructura: input -> msg (creado con insertBefore(msg, input.nextSibling))
                // Por lo tanto: input.nextElementSibling DEBERIA ser el msg.

                // Validación para passwords
                // Estructura: div(relative) -> input, i
                // msg se inserta antes de input.nextSibling (que es i).
                // Resultado: div -> input, msg, i
                // Por lo tanto: input.nextElementSibling TAMBIEN es msg.

                // Verificamos si el siguiente elemento es un mensaje de validación
                let currentMsg = input.nextElementSibling;

                // Si no es (por si acaso hay algo en medio), buscamos especificamente la clase
                if (currentMsg && !currentMsg.classList.contains('validation-msg')) {
                    // Intenta el siguiente (caso borde)
                    currentMsg = currentMsg.nextElementSibling;
                }

                // Asegurar que es el mensaje PROPIO y no de otro input
                if (currentMsg && currentMsg.classList.contains('validation-msg')) {
                    const isValid = validateInput(input, currentMsg);
                    if (!isValid) allValid = false;
                }
            });

            // === VALIDACIÓN DE TÉRMINOS Y CONDICIONES ===
            const termsCheck = document.getElementById("termsCheck");
            if (termsCheck && !termsCheck.checked) {
                showCustomModal("Términos Requeridos", "Debes aceptar los términos y condiciones para registrarte.", "error");
                allValid = false;
            }

            if (!allValid) {
                // Si el error fue por términos, no mostramos el mensaje general de "campos en rojo" 
                // ya que ya se mostró el modal de los términos.
                if (termsCheck && termsCheck.checked) {
                    showCustomModal("Datos Incorrectos", "Por favor corrige los campos marcados en rojo antes de registrarte.", "error");
                }
                return; // DETENER ENVÍO
            }

            const formData = new FormData(registerForm);
            const btn = registerForm.querySelector('button[type="submit"]');

            // Agregar margen superior al botón dinámicamente si no lo tiene (fix UI)
            if (!btn.style.marginTop) {
                btn.style.marginTop = "20px";
            }

            const originalText = btn.innerHTML;
            btn.innerHTML = "Registrando...";
            btn.disabled = true;

            fetch("../src/php/registrar.php", {
                method: "POST",
                body: formData
            })
                .then(res => res.json())
                .then(data => {
                    btn.innerHTML = originalText;
                    btn.disabled = false;

                    if (data.success) {
                        showCustomModal("¡Registro Exitoso!", data.message || "Tu cuenta ha sido creada. Ya puedes iniciar sesión.", "success", () => {
                            // Cambiar al panel de inicio de sesión visualmente (Usa la función centralizada)
                            if (typeof window.togglePanel === 'function') {
                                window.togglePanel('signIn');
                            } else {
                                const container = document.getElementById('container');
                                if (container) container.classList.remove("right-panel-active");
                            }
                            
                            registerForm.reset();
                            // Limpiar validaciones
                            registerForm.querySelectorAll('.validation-msg').forEach(m => m.style.display = 'none');
                        });
                    } else {
                        showCustomModal("Error", data.error || "No se pudo registrar.", "error");
                    }
                })
                .catch(err => {
                    console.error(err);
                    btn.innerHTML = originalText;
                    btn.disabled = false;
                    showCustomModal("Error de Conexión", "Intenta nuevamente más tarde.", "error");
                });
        });
    }

    // Modal reutilizable simple inyectado
    function showCustomModal(title, message, type, callback) {
        // Eliminar anterior si existe
        const old = document.getElementById('customModalSimple');
        if (old) old.remove();

        const color = type === 'success' ? '#087d4e' : '#dc3545';

        const modal = document.createElement('div');
        modal.id = 'customModalSimple';
        modal.style.cssText = `
            position: fixed; top: 0; left: 0; width: 100%; height: 100vh;
            background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center;
            z-index: 10000; animation: fadeIn 0.3s;
        `;

        modal.innerHTML = `
            <div style="background: white; padding: 30px; border-radius: 15px; width: 90%; max-width: 400px; text-align: center; box-shadow: 0 5px 20px rgba(0,0,0,0.3); transform: translateY(0);">
                <h2 style="color: ${color}; margin-top: 0;">${title}</h2>
                <p style="color: #666; margin: 20px 0;">${message}</p>
                <button id="modalBtnOk" style="
                    background: ${color}; color: white; border: none; padding: 10px 25px; 
                    border-radius: 5px; cursor: pointer; font-size: 14px; font-weight: bold;
                ">Aceptar</button>
            </div>
        `;

        document.body.appendChild(modal);

        document.getElementById('modalBtnOk').addEventListener('click', () => {
            modal.style.display = 'none';
            if (callback) callback();
        });
    }

    // Animaciones con validación de existencia
    const signUpButton = document.getElementById('signUp');
    const signInButton = document.getElementById('signIn');
    const container = document.getElementById('container');

    // Función centralizada para alternar paneles (Evita errores de sincronización)
    window.togglePanel = function(mode) {
        const container = document.getElementById('container');
        if (!container) return;

        if (mode === 'signUp') {
            container.classList.add("right-panel-active");
        } else {
            container.classList.remove("right-panel-active");
        }
    };

    if (signUpButton && signInButton && container) {
        signUpButton.addEventListener('click', () => window.togglePanel('signUp'));
        signInButton.addEventListener('click', () => window.togglePanel('signIn'));
    }

    // ============================================
    // LÓGICA DE RECUPERACIÓN DE CONTRASEÑA
    // ============================================
    const forgotLink = document.getElementById("forgotPasswordLink");
    const recoveryModal = document.getElementById("recoveryModal");
    const closeRecovery = document.getElementById("closeRecoveryModal");

    if (forgotLink && recoveryModal) {
        forgotLink.addEventListener("click", (e) => {
            e.preventDefault();

            // Limpiar campos y validaciones al abrir
            const inputs = recoveryModal.querySelectorAll('input');
            inputs.forEach(i => i.value = '');

            const msgs = recoveryModal.querySelectorAll('.validation-msg');
            msgs.forEach(m => m.style.display = 'none');

            recoveryModal.classList.add("active");
            showStep(1);
        });

        if (closeRecovery) {
            closeRecovery.addEventListener("click", () => {
                recoveryModal.classList.remove("active");
            });
        }

        // --- VALIDACIONES EN TIEMPO REAL RECUPERACIÓN ---
        const recupInputs = [
            document.getElementById('recupUser'),
            document.getElementById('recupNewPass'),
            document.getElementById('recupConfirmPass')
        ];

        recupInputs.forEach(input => {
            if (input && !input.dataset.validationInitialized) {
                input.dataset.validationInitialized = "true";

                const msg = document.createElement("div");
                msg.className = "validation-msg";
                msg.style.display = "none";
                msg.style.fontSize = "11px";
                msg.style.color = "#666";
                msg.style.marginTop = "2px";
                msg.style.textAlign = "left";
                msg.style.width = "100%";
                msg.style.paddingLeft = "5px";

                // Insertar mensaje
                if (input.parentNode.style.position === 'relative') {
                    // Caso password con toggle (div relative)
                    input.parentNode.appendChild(msg);
                } else {
                    // Caso normal
                    input.parentNode.insertBefore(msg, input.nextSibling);
                }

                input.addEventListener('focus', () => showHelp(input, msg));
                input.addEventListener('input', () => {
                    if (input.name === 'confirm_password') {
                        validateRecupConfirm(input, msg);
                    } else {
                        validateInput(input, msg);
                    }
                });
                input.addEventListener('blur', () => msg.style.display = 'none');
            }
        });

        function validateRecupConfirm(input, msg) {
            msg.style.display = 'block';
            let valid = true;
            const passwordInput = document.getElementById('recupNewPass');

            if (input.value !== passwordInput.value) {
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
    }

    function showStep(stepNumber) {
        document.querySelectorAll('.recovery-step').forEach(s => s.classList.remove('active'));
        const step = document.getElementById('step' + stepNumber);
        if (step) step.classList.add('active');
    }

    // PASO 1: Buscar Usuario
    const btnSearch = document.getElementById("btnSearchUser");
    if (btnSearch) {
        btnSearch.addEventListener("click", () => {
            const user = document.getElementById("recupUser").value.trim();
            if (!user) return alert("Ingresa tu usuario");

            const btnOriginal = btnSearch.innerHTML;
            btnSearch.innerHTML = "Buscando...";
            btnSearch.disabled = true;

            const fd = new FormData();
            fd.append("accion", "buscar_usuario");
            fd.append("usuario", user);

            fetch("../src/php/recuperar.php", { method: "POST", body: fd })
                .then(r => r.json())
                .then(data => {
                    btnSearch.innerHTML = btnOriginal;
                    btnSearch.disabled = false;

                    if (data.success) {
                        // Llenar opciones
                        const container = document.getElementById("recoveryOptionsContainer");
                        if (container) {
                            container.innerHTML = "";

                            // Opción Email (único método funcional)
                            if (data.email_masked) {
                                const btnEmail = document.createElement("div");
                                btnEmail.className = "btn-recovery-option";
                                btnEmail.innerHTML = `<i class="fa-solid fa-envelope"></i> Enviar código a <br><small>(${data.email_masked})</small>`;
                                btnEmail.onclick = () => sendCode("email");
                                container.appendChild(btnEmail);
                            } else {
                                container.innerHTML = "<p style='color:#dc3545;'>Este usuario no tiene un correo registrado.</p>";
                            }
                        }

                        showStep(2);
                    } else {
                        alert(data.message || "Usuario no encontrado");
                    }
                })
                .catch(e => {
                    alert("Error servidor");
                    btnSearch.innerHTML = btnOriginal;
                    btnSearch.disabled = false;
                });
        });
    }

    // PASO 2: Volver
    const btnBack = document.getElementById("btnBackToStep1");
    if (btnBack) btnBack.addEventListener("click", () => showStep(1));

    // Función enviar código por email real
    function sendCode(metodo) {
        // Deshabilitar botones mientras se envía
        const btns = document.querySelectorAll('.btn-recovery-option');
        btns.forEach(b => {
            b.style.opacity = '0.5';
            b.style.pointerEvents = 'none';
        });

        const fd = new FormData();
        fd.append("accion", "enviar_codigo");
        fd.append("metodo", metodo);

        fetch("../src/php/recuperar.php", { method: "POST", body: fd })
            .then(r => r.json())
            .then(data => {
                if (data.success) {
                    showStep(3);
                } else {
                    alert(data.message || "Error al enviar el código");
                    btns.forEach(b => {
                        b.style.opacity = '1';
                        b.style.pointerEvents = 'auto';
                    });
                }
            })
            .catch(e => {
                alert("Error de conexión al enviar código");
                btns.forEach(b => {
                    b.style.opacity = '1';
                    b.style.pointerEvents = 'auto';
                });
            });
    }

    // PASO 3: Cambiar Password
    const btnChange = document.getElementById("btnChangePass");
    if (btnChange) {
        btnChange.addEventListener("click", () => {
            const codeInput = document.getElementById("recupCode");
            const newPassInput = document.getElementById("recupNewPass");
            const confirmPassInput = document.getElementById("recupConfirmPass");

            if (!codeInput || !newPassInput || !confirmPassInput) return;

            const code = codeInput.value.trim();
            const newPass = newPassInput.value;
            const confirmPass = confirmPassInput.value;

            if (code.length !== 6) return alert("El código debe tener 6 dígitos");
            if (newPass !== confirmPass) return alert("Las contraseñas no coinciden");
            if (newPass.length < 8) return alert("La contraseña debe tener al menos 8 caracteres");

            const btnOriginal = btnChange.innerHTML;
            btnChange.innerHTML = "Verificando...";
            btnChange.disabled = true;

            const fd = new FormData();
            fd.append("accion", "verificar_cambiar");
            fd.append("codigo", code);
            fd.append("new_password", newPass);

            fetch("../src/php/recuperar.php", { method: "POST", body: fd })
                .then(r => r.json())
                .then(data => {
                    btnChange.innerHTML = btnOriginal;
                    btnChange.disabled = false;

                    if (data.success) {
                        showStep(4);
                    } else {
                        alert(data.message);
                    }
                })
                .catch(e => {
                    alert("Error al cambiar contraseña");
                    btnChange.innerHTML = btnOriginal;
                    btnChange.disabled = false;
                });
        });
    }

    // Finalizar
    const btnSuccess = document.getElementById("btnCloseRecoverySuccess");
    if (btnSuccess) {
        btnSuccess.addEventListener("click", () => {
            if (recoveryModal) recoveryModal.classList.remove("active");
            showStep(1); // Reset
            // Limpiar campos
            const inputs = document.querySelectorAll("#recoveryModal input");
            if (inputs) inputs.forEach(i => i.value = "");
        });
    }

    // Toggle Password en Recuperación
    const toggleRecup = document.getElementById('toggleRecupPass');
    const recupInput = document.getElementById('recupNewPass');
    if (toggleRecup && recupInput) {
        toggleRecup.addEventListener('click', function () {
            const type = recupInput.getAttribute('type') === 'password' ? 'text' : 'password';
            recupInput.setAttribute('type', type);
            this.classList.toggle('fa-eye');
            this.classList.toggle('fa-eye-slash');
        });

        // Soporte teclado
        toggleRecup.addEventListener('keydown', e => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggleRecup.click(); } });
    }
});


