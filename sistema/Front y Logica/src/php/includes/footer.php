<?php
/**
 * ============================================================
 * PIE DE PÁGINA Y MODALES (INCLUDE)
 * ============================================================
 * 
 * PROPÓSITO:
 * Contiene todos los elementos que van al final de las páginas
 * del panel de administración. Se incluye automáticamente en
 * menuPrincipal.php.
 * 
 * CONTIENE:
 * 1. Modal de Modificar Perfil → Permite al usuario cambiar
 *    su nombre, email y teléfono
 * 2. Modal de Cambiar Contraseña → Con validación de fuerza
 *    y confirmación de coincidencia
 * 3. Modal Genérico de Gestión → Se llena dinámicamente con
 *    tablas de datos (usuarios, clientes, etc.)
 * 4. Modal de Soporte → Información de contacto del equipo
 * 5. Inyección de datos auxiliares → Pasa datos PHP a JavaScript
 * 6. Carga de scripts JS → logica.js, validations.js, etc.
 * 7. Funciones de cierre de sesión → Limpieza segura OWASP
 * ============================================================
 */
?>
<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 1: MODIFICAR PERFIL DE USUARIO          -->
<!-- ══════════════════════════════════════════════ -->
<!-- Formulario que permite al usuario cambiar     -->
<!-- su nombre, correo electrónico y teléfono.     -->
<!-- Los datos se envían por POST al mismo archivo -->
<!-- PHP (dashboard_controller.php lo procesa).    -->
<div id="modalPerfil" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Modificar Perfil</h2>
        </div>


        <!-- Formulario de edición de perfil -->
        <form id="formPerfil" method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <!-- Token CSRF: protege contra ataques Cross-Site Request Forgery -->
            <input type="hidden" name="csrf_token" value="<?php echo generarCSRFToken(); ?>">
            <div class="form-group">
                <label>Nombre de Usuario:</label>
                <input type="text" name="nom_user" id="nombreCompleto"
                    value="<?php echo htmlspecialchars($nom_user); ?>" required>
            </div>
            <div class="form-group">
                <label>Email:</label>
                <input type="email" name="mail_user" id="email" value="<?php echo htmlspecialchars($mail_user); ?>"
                    required>
            </div>
            <div class="form-group">
                <label>Teléfono:</label>
                <input type="tel" name="tel_user" id="telefono" value="<?php echo htmlspecialchars($tel_user); ?>"
                    required>
            </div>
            <div class="form-group">
                <label>Rol:</label>
                <!-- El rol no es editable, solo se muestra -->
                <input type="text" id="especialidad" value="<?php echo htmlspecialchars($rol_usuario); ?>" readonly>
            </div>
            <div class="modal-buttons">
                <button type="button" class="btn-modal btn-secondary" onclick="cerrarModalPerfil()">Cancelar</button>
                <button type="submit" class="btn-modal btn-primary">Guardar Cambios</button>
            </div>
        </form>
    </div>
</div>

<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 2: CAMBIAR CONTRASEÑA                   -->
<!-- ══════════════════════════════════════════════ -->
<!-- Pide la contraseña actual y una nueva.        -->
<!-- Incluye validación visual en tiempo real      -->
<!-- (íconos de check/error y mensajes de ayuda).  -->
<div id="modalPassword" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Cambiar Contraseña</h2>
        </div>


        <!-- Formulario de cambio de contraseña -->
        <form id="formPassword" method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <!-- Campo oculto para identificar que es un cambio de contraseña -->
            <input type="hidden" name="cambiar_password" value="1">
            <!-- Token CSRF: protege contra ataques Cross-Site Request Forgery -->
            <input type="hidden" name="csrf_token" value="<?php echo generarCSRFToken(); ?>">

            <div class="form-group">
                <label>Contraseña Actual:</label>
                <div style="position: relative;">
                    <input type="password" name="password_actual" id="password_actual" required
                        autocomplete="current-password" style="padding-right: 40px;">
                    <i class="fa-solid fa-eye" onclick="togglePasswordVisibility('password_actual', this)"
                        style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #888; z-index: 10;"></i>
                </div>
            </div>

            <div class="form-group">
                <label>Nueva Contraseña:</label>
                <div style="position: relative;">
                    <input type="password" name="password_nueva" id="password_nueva" required
                        autocomplete="new-password" minlength="8" style="padding-right: 60px;">
                    <!-- Ícono de mostrar/ocultar contraseña -->
                    <i class="fa-solid fa-eye" onclick="togglePasswordVisibility('password_nueva', this)"
                        style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #888; z-index: 10;"></i>
                    <!-- Íconos de validación visual (se muestran/ocultan con JavaScript) -->
                    <i class="fa-solid fa-circle-check" id="checkIconAdmin"
                        style="position: absolute; right: 35px; top: 50%; transform: translateY(-50%); color: #2ecc71; opacity: 0; transition: opacity 0.3s; z-index: 5;"></i>
                    <i class="fa-solid fa-circle-xmark" id="errorIconAdmin"
                        style="position: absolute; right: 35px; top: 50%; transform: translateY(-50%); color: #e74c3c; opacity: 0; transition: opacity 0.3s; z-index: 5;"></i>
                </div>
                <small id="passwordHelpAdmin"
                    style="display: block; margin-top: 5px; color: #666; font-size: 0.85rem; transition: color 0.3s;">
                    Mínimo 8 caracteres, mayúscula y número
                </small>
            </div>

            <div class="form-group">
                <label>Confirmar Nueva Contraseña:</label>
                <div style="position: relative;">
                    <input type="password" name="password_confirmar" id="password_confirmar" required
                        autocomplete="new-password" minlength="8" style="padding-right: 60px;">
                    <!-- Ícono de mostrar/ocultar contraseña -->
                    <i class="fa-solid fa-eye" onclick="togglePasswordVisibility('password_confirmar', this)"
                        style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #888; z-index: 10;"></i>
                    <!-- Ícono que aparece cuando las contraseñas coinciden -->
                    <i class="fa-solid fa-circle-check" id="matchIconAdmin"
                        style="position: absolute; right: 35px; top: 50%; transform: translateY(-50%); color: #2ecc71; opacity: 0; transition: opacity 0.3s; z-index: 5;"></i>
                </div>
                <small id="confirmHelpAdmin"
                    style="display: block; margin-top: 5px; color: #666; font-size: 0.85rem; transition: color 0.3s;">
                    Las contraseñas deben coincidir
                </small>
            </div>

            <div class="modal-buttons">
                <button type="button" class="btn-modal btn-secondary" onclick="cerrarModalPassword()">Cancelar</button>
                <button type="submit" class="btn-modal btn-primary">Cambiar Contraseña</button>
            </div>
        </form>
    </div>
</div>

<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 3: GESTIÓN DE DATOS (GENÉRICO)          -->
<!-- ══════════════════════════════════════════════ -->
<!-- Este modal se llena dinámicamente desde       -->
<!-- JavaScript (logica.js) con tablas de datos    -->
<!-- según la sección que elija el administrador   -->
<!-- (usuarios, clientes, empleados, etc.)         -->
<div id="modalGestion" class="modal">
    <div class="modal-content">
        <div class="modal-header" style="display: flex; justify-content: space-between; align-items: center;">
            <h2 id="modalGestionTitle">Gestión</h2>
            <div style="display: flex; gap: 15px; align-items: center;">
                <!-- Botón para agregar nuevo registro -->
                <button id="btnNuevoRegistro" class="btn-modal btn-primary"
                    style="padding: 8px 15px; font-size: 14px; display: none; display: flex; align-items: center; gap: 5px;">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor"
                        class="bi bi-plus-lg" viewBox="0 0 16 16">
                        <path fill-rule="evenodd"
                            d="M8 2a.5.5 0 0 1 .5.5v5h5a.5.5 0 0 1 0 1h-5v5a.5.5 0 0 1-1 0v-5h-5a.5.5 0 0 1 0-1h5v-5A.5.5 0 0 1 8 2z" />
                    </svg> Nuevo
                </button>
                <span class="close-btn" id="closeGestionBtn" style="float: none;">&times;</span>
            </div>
        </div>
        <!-- Aquí se inyecta dinámicamente la tabla de datos -->
        <div class="modal-body" id="modalGestionBody">
            <!-- Contenido dinámico -->
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-modal btn-secondary"
                onclick="document.getElementById('modalGestion').style.display='none'">Cerrar</button>
        </div>
    </div>
</div>

<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 4: SOPORTE Y AYUDA                      -->
<!-- ══════════════════════════════════════════════ -->
<!-- Muestra la información de contacto del equipo -->
<!-- de desarrollo para soporte técnico.           -->
<div id="modalSoporte" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Ayuda y Soporte</h2>
            <span class="close-btn" onclick="cerrarModalSoporte()" style="color: white; opacity: 0.8;">&times;</span>
        </div>
        <div class="modal-body" style="text-align: center; padding: 30px;">
            <p style="color: var(--text-muted); margin-bottom: 25px; font-size: 1.1rem;">
                Para asistencia técnica o consultas, por favor contacte a nuestro equipo de desarrollo:
            </p>

            <div class="dev-cards-container" style="display: flex; flex-direction: column; gap: 20px;">
                <!-- Developer 1 -->
                <div class="dev-card">
                    <div class="dev-avatar">
                        <i class="fa-solid fa-code"></i>
                    </div>
                    <div class="dev-info">
                        <h3>Santiago Calderon</h3>
                        <div class="contact-item">
                            <i class="fa-brands fa-whatsapp"></i> 300 143 8671
                        </div>
                        <div class="contact-item">
                            <i class="fa-solid fa-envelope"></i> santiagoc200508@gmail.com
                        </div>
                    </div>
                </div>

                <!-- Developer 2 -->
                <div class="dev-card">
                    <div class="dev-avatar">
                        <i class="fa-solid fa-laptop-code"></i>
                    </div>
                    <div class="dev-info">
                        <h3>Juan Esteban</h3>
                        <div class="contact-item">
                            <i class="fa-brands fa-whatsapp"></i> 310 227 8149
                        </div>
                        <div class="contact-item">
                            <i class="fa-solid fa-envelope"></i> juanbarrrios2005@gmail.com
                        </div>
                    </div>
                </div>
            </div>

            <div style="margin-top: 30px; font-size: 0.9rem; color: var(--text-muted);">
                <p>&copy; <?php echo date('Y'); ?> SDI System. Todos los derechos reservados.</p>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-modal btn-primary" onclick="cerrarModalSoporte()">Entendido</button>
        </div>
    </div>
</div>

<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 5: NOTIFICACIONES DE STOCK BAJO         -->
<!-- ══════════════════════════════════════════════ -->
<div id="modalNotificaciones" class="modal">
    <div class="modal-content">
        <div class="modal-header">
            <h2>Notificaciones</h2>
            <span class="close-btn" onclick="cerrarModalNotificaciones()" style="color: white; opacity: 0.8;">&times;</span>
        </div>
        <div class="modal-body" style="padding: 20px;">
            <div id="listaAlertasStock" class="lista-alertas">
                <?php if (!empty($stats['alertas_detalle'])): ?>
                    <p style="margin-bottom: 20px; color: var(--text-muted); font-weight: 500;"><i class="fa-solid fa-circle-info" style="color: var(--header-blue); margin-right: 8px;"></i> Los siguientes productos se encuentran en nivel crítico de stock:</p>
                    <?php foreach ($stats['alertas_detalle'] as $alerta): ?>
                        <div class="alerta-stock-item" style="display: flex; gap: 15px; background: var(--bg-primary); border: 1px solid var(--text-muted); padding: 15px; border-radius: 12px; margin-bottom: 15px; align-items: center; box-shadow: 0 4px 6px var(--card-shadow); border-left: 5px solid #dc3545;">
                            <div class="alerta-icon" style="background: rgba(220, 53, 69, 0.1); width: 50px; height: 50px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #dc3545; font-size: 1.4rem;">
                                <i class="fa-solid fa-triangle-exclamation"></i>
                            </div>
                            <div class="alerta-info" style="flex: 1;">
                                <div style="display: flex; justify-content: space-between; align-items: flex-start;">
                                    <strong style="display: block; color: var(--text-main); font-size: 1.05rem;"><?php echo htmlspecialchars($alerta['nombre']); ?></strong>
                                    <span style="background: var(--bg-secondary); padding: 2px 10px; border-radius: 15px; font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; font-weight: bold;"><?php echo $alerta['tipo']; ?></span>
                                </div>
                                <div class="alerta-cantidad" style="margin-top: 8px; display: flex; gap: 20px;">
                                    <div style="background: #dc3545; color: white; padding: 3px 12px; border-radius: 20px; font-size: 0.85rem;">
                                        Actual: <strong><?php echo $alerta['actual']; ?></strong>
                                    </div>
                                    <div style="color: var(--text-muted); font-size: 0.85rem; padding-top: 3px;">
                                        Mínimo: <strong><?php echo $alerta['minimo']; ?></strong>
                                    </div>
                                </div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                <?php else: ?>
                    <div style="text-align: center; padding: 40px 20px;">
                        <div style="background: #f8f9fa; width: 80px; height: 80px; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #ccc; font-size: 2.5rem; margin: 0 auto 20px;">
                            <i class="fa-solid fa-bell-slash"></i>
                        </div>
                        <p style="color: #888; font-size: 1.1rem; margin: 0;">No hay alertas de stock en este momento.</p>
                        <p style="color: #aaa; font-size: 0.9rem; margin-top: 5px;">Todo se encuentra bajo control.</p>
                    </div>
                <?php endif; ?>
            </div>
        </div>
        <div class="modal-footer">
            <button type="button" class="btn-modal btn-primary" onclick="cerrarModalNotificaciones()">Cerrar</button>
        </div>
    </div>
</div>

<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 6: MOVIMIENTO DE INSTRUMENTAL (SEP)     -->
<!-- ══════════════════════════════════════════════ -->
    <div id="modalMovimientoInstrumental" class="modal">
        <div class="modal-content" style="max-width: 500px;">
            <div class="modal-header">
                <h2 id="modalMovimientoTitle" style="margin:0; font-size: 1.4rem;">Registrar Movimiento</h2>
                <span class="close-btn" onclick="document.getElementById('modalMovimientoInstrumental').style.display='none'" style="color: white; opacity: 0.8;">&times;</span>
            </div>
            <div class="modal-body" id="modalMovimientoBody" style="padding: 20px;">
                <!-- El contenido se genera en instrumental_controller.js -->
            </div>
        </div>
    </div>

    <!-- MODAL 7: MOVIMIENTO GLOBAL (NUEVO) -->
    <div id="modalMovimientoGlobal" class="modal">
        <div class="modal-content" style="max-width: 600px;">
            <div class="modal-header">
                <h2 id="modalGlobalMovTitle" style="margin:0; font-size: 1.4rem;">Registro General de Movimientos</h2>
                <span class="close-btn" onclick="document.getElementById('modalMovimientoGlobal').style.display='none'" style="color: white; opacity: 0.8;">&times;</span>
            </div>
            <div class="modal-body" id="modalGlobalMovBody" style="padding: 20px;">
                <!-- Se llena dinámicamente -->
            </div>
        </div>
    </div>

<!-- ══════════════════════════════════════════════ -->
<!-- MODAL 8: CONFIGURACIÓN (TEMA E IDIOMA)        -->
<!-- ══════════════════════════════════════════════ -->
<div id="modalAccesibilidad" class="modal">
    <div class="modal-content" style="max-width: 450px; border-radius: 15px; overflow: hidden;">
        <div class="modal-header" style="background: var(--modal-header-grad);">
            <h2 data-i18n="settings.title" style="color: white; margin: 0; font-size: 1.5rem;">Accesibilidad</h2>
            <span class="close-btn" onclick="cerrarModalAccesibilidad()" style="color: white; opacity: 0.8;">&times;</span>
        </div>
        <form id="formAccesibilidad" method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
            <input type="hidden" name="update_params" value="1">
            <!-- Token CSRF: protege contra ataques Cross-Site Request Forgery -->
            <input type="hidden" name="csrf_token" value="<?php echo generarCSRFToken(); ?>">
            <div class="modal-body" style="padding: 30px;">
                <!-- Modo Oscuro (Switch) -->
                <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 30px;">
                    <div>
                        <label style="display: block; font-weight: bold; font-size: 1.1rem; color: var(--text-main);" data-i18n="settings.theme">Modo Oscuro</label>
                        <small style="color: var(--text-muted);" data-i18n="settings.theme_desc">Cambiar la apariencia de la aplicación</small>
                    </div>
                    <label class="switch">
                        <input type="checkbox" name="tema_toggle" id="tema_toggle" <?php echo !$stats['ind_tema'] ? 'checked' : ''; ?> onchange="togglePreviewTheme(!this.checked)">
                        <span class="slider round"></span>
                    </label>
                    <input type="hidden" name="tema" id="tema_value" value="<?php echo $stats['ind_tema'] ? 'claro' : 'oscuro'; ?>">
                </div>

                <!-- Selección de Idioma -->
                <div style="margin-bottom: 10px;">
                    <label style="display: block; font-weight: bold; font-size: 1.1rem; color: var(--text-main); margin-bottom: 10px;" data-i18n="settings.language">Idioma de la Plataforma</label>
                    <div style="position: relative;">
                        <select name="idioma" id="selectIdioma" class="form-control" style="width: 100%; padding: 12px 15px; border-radius: 10px; border: 1px solid var(--text-muted); background: var(--bg-primary); color: var(--text-main); appearance: none; cursor: pointer;" onchange="cambiarIdiomaPreview(this.value)">
                            <option value="ES" <?php echo $stats['ind_idioma'] == 'ES' ? 'selected' : ''; ?>>Español (Latinoamérica)</option>
                            <option value="EN" <?php echo $stats['ind_idioma'] == 'EN' ? 'selected' : ''; ?>>English (United States)</option>
                        </select>
                        <i class="fa-solid fa-chevron-down" style="position: absolute; right: 15px; top: 50%; transform: translateY(-50%); color: var(--text-muted); pointer-events: none;"></i>
                    </div>
                </div>
            </div>
            <div class="modal-footer" style="padding: 20px 30px; background: var(--bg-secondary); border-top: 1px solid var(--text-muted); text-align: center;">
                <button type="submit" class="btn-modal btn-primary" style="width: 100%; padding: 12px; border-radius: 10px; font-weight: bold;" data-i18n="settings.save">Guardar Cambios</button>
            </div>
        </form>
    </div>
</div>



<script>
    // --- LÓGICA DE TRADUCCIÓN ---
    let translations = {};
    const currentLang = '<?php echo $stats['ind_idioma']; ?>';

    async function cargarTraducciones(lang) {
        try {
            const response = await fetch(`../lang/${lang.toLowerCase()}.json`);
            translations = await response.json();
            aplicarTraducciones();
        } catch (error) {
            console.error('Error cargando traducciones:', error);
        }
    }

    function aplicarTraducciones() {
        document.querySelectorAll('[data-i18n]').forEach(el => {
            const key = el.getAttribute('data-i18n');
            const translation = key.split('.').reduce((obj, i) => obj[i], translations);
            if (translation) {
                if (el.tagName === 'INPUT' && (el.type === 'text' || el.type === 'search')) {
                    el.placeholder = translation;
                } else {
                    el.innerText = translation;
                }
            }
        });
    }

    function cambiarIdiomaPreview(lang) {
        cargarTraducciones(lang);
    }

    // --- LÓGICA DE TEMA ---
    function togglePreviewTheme(isLight) {
        if (isLight) {
            document.body.classList.remove('dark-mode');
        } else {
            document.body.classList.add('dark-mode');
        }
    }

    // --- MODAL CONFIG ---
    function abrirModalConfig() {
        const modal = document.getElementById('modalConfig');
        modal.style.display = 'block';
        setTimeout(() => modal.classList.add('show'), 10);
    }

    function cerrarModalConfig() {
        const modal = document.getElementById('modalConfig');
        modal.classList.remove('show');
        setTimeout(() => modal.style.display = 'none', 300);
    }

    // Inicialización
    document.addEventListener('DOMContentLoaded', () => {
        cargarTraducciones(currentLang);
        togglePreviewTheme(<?php echo $stats['ind_tema'] ? 'true' : 'false'; ?>);
    });
</script>

<!-- Los datos auxiliares (ciudades, documentos, bancos, cargos, etc.) -->
<!-- se pasan de PHP a JavaScript como una variable global.           -->
<!-- Esto permite que los formularios se llenen sin peticiones extra. -->
<script>
    const auxiliares = <?php echo json_encode($auxiliares ?? []); ?>;
</script>

<!-- ══════════════════════════════════════════════ -->
<!-- CARGA DE SCRIPTS JAVASCRIPT                   -->
<!-- ══════════════════════════════════════════════ -->
<!-- Se cargan al final del HTML para que los      -->
<!-- elementos del DOM ya existan cuando se ejecuten. -->
<script src="../JavaScript/core/api_service.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/core/ui_components.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/core/validadores_base.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/controllers/instrumental_controller.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/controllers/mat_prim_controller.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/controllers/historial_controller.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/controllers/productos_controller.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/controllers/finanzas_controller.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/controllers/dashboard_controller.js?v=<?php echo time(); ?>"></script>
<script src="../JavaScript/navigation.js?v=<?php echo time(); ?>"></script>

<!-- Scripts antiguos (pendientes de limpieza total) -->
<!-- <script src="../JavaScript/validations.js?v=<?php echo time(); ?>"></script> -->
<script src="../JavaScript/logica.js?v=<?php echo time(); ?>"></script>

<!-- ══════════════════════════════════════════════ -->
<!-- SCRIPTS INLINE: CONTROLES DE MODALES Y LOGOUT -->
<!-- ══════════════════════════════════════════════ -->
<script>
    // ─── FUNCIONES PARA EL MODAL DE CONTRASEÑA ───
    // Abrir y cerrar el modal de cambio de contraseña
    // con animación suave (clase CSS 'show')
    function abrirModalPassword() {
        const modal = document.getElementById('modalPassword');
        if (modal) {
            modal.style.display = 'block';
            setTimeout(() => {
                modal.classList.add('show');
            }, 10);
        }
    }

    function cerrarModalPassword() {
        const modal = document.getElementById('modalPassword');
        if (modal) {
            modal.classList.remove('show');
            setTimeout(() => {
                modal.style.display = 'none';
                // Limpiar formulario
                document.getElementById('formPassword').reset();
            }, 300);
        }
    }

    // ─── CERRAR MODAL AL HACER CLIC FUERA ───
    // Si el usuario hace clic en el fondo oscuro
    // (fuera del contenido del modal), se cierra.
    window.addEventListener('click', function (event) {
        const modalPassword = document.getElementById('modalPassword');
        const modalSoporte = document.getElementById('modalSoporte');

        if (event.target === modalPassword) {
            cerrarModalPassword();
        }
        if (event.target === modalSoporte) {
            cerrarModalSoporte();
        }
        if (event.target === document.getElementById('modalNotificaciones')) {
            cerrarModalNotificaciones();
        }
    });

    // --- MODAL DE ACCESIBILIDAD ---
    window.abrirModalAccesibilidad = function() {
        const modal = document.getElementById('modalAccesibilidad');
        if (modal) modal.style.display = 'block';
    }
    window.cerrarModalAccesibilidad = function() {
        const modal = document.getElementById('modalAccesibilidad');
        if (modal) modal.style.display = 'none';
    }

    window.togglePreviewTheme = function(isLight) {
        if (isLight) {
            document.body.classList.remove('dark-mode');
            document.getElementById('tema_value').value = 'claro';
        } else {
            document.body.classList.add('dark-mode');
            document.getElementById('tema_value').value = 'oscuro';
        }
    }

    window.cambiarIdiomaPreview = function(lang) {
        // En un sistema real podrías cargar las traducciones dinámicamente aquí
        console.log("Cambiando previsualización de idioma a:", lang);
    }

    // ─── FUNCIONES PARA EL MODAL DE NOTIFICACIONES ───
    function abrirModalNotificaciones() {
        const modal = document.getElementById('modalNotificaciones');
        if (modal) {
            modal.style.display = 'block';
            setTimeout(() => {
                modal.classList.add('show');
            }, 10);
        }
    }

    function cerrarModalNotificaciones() {
        const modal = document.getElementById('modalNotificaciones');
        if (modal) {
            modal.classList.remove('show');
            setTimeout(() => {
                modal.style.display = 'none';
            }, 300);
        }
    }

    // ─── FUNCIONES PARA EL MODAL DE SOPORTE ───
    function abrirModalSoporte() {
        const modal = document.getElementById('modalSoporte');
        if (modal) {
            modal.style.display = 'block';
            setTimeout(() => {
                modal.classList.add('show'); // Ensure CSS has .modal.show handling opacity
            }, 10);
        }
    }

    function cerrarModalSoporte() {
        const modal = document.getElementById('modalSoporte');
        if (modal) {
            modal.classList.remove('show');
            setTimeout(() => {
                modal.style.display = 'none';
            }, 300);
        }
    }

    // ─── APERTURA AUTOMÁTICA DE MODALES ───
    // Si hay mensajes de error/éxito en la sesión,
    // se muestra el SweetAlert y se limpia la URL.
    <?php if ($mensaje_error || $mensaje_success): ?>
        document.addEventListener('DOMContentLoaded', function () {
            <?php if ($mensaje_success): ?>
                // Mostrar alerta de éxito bonita con SweetAlert2
                Swal.fire({
                    title: '¡Perfil Actualizado!',
                    text: '<?php echo $mensaje_success; ?>',
                    icon: 'success',
                    timer: 3000,
                    timerProgressBar: true,
                    confirmButtonColor: '#36498f'
                });
                <?php unset($_SESSION['success_perfil']); ?>
            <?php else: ?>
                // Si hay error, mostrar alerta de error
                Swal.fire({
                    title: 'Error de Actualización',
                    text: '<?php echo $mensaje_error; ?>',
                    icon: 'error',
                    confirmButtonColor: '#36498f'
                }).then(() => {
                    abrirModalPerfil();
                });
                <?php unset($_SESSION['error_perfil']); ?>
            <?php endif; ?>

            // Limpiar URL para evitar que el mensaje se repita al recargar
            if (window.history.replaceState) {
                const cleanUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
                window.history.replaceState({ path: cleanUrl }, '', cleanUrl);
            }
        });
    <?php endif; ?>

    <?php if (isset($_GET['password']) || $mensaje_error_password || $mensaje_success_password): ?>
        document.addEventListener('DOMContentLoaded', function () {
            <?php if ($mensaje_success_password): ?>
                // Alerta de éxito para contraseña
                Swal.fire({
                    title: '¡Contraseña Cambiada!',
                    text: '<?php echo $mensaje_success_password; ?>',
                    icon: 'success',
                    timer: 3000,
                    timerProgressBar: true,
                    confirmButtonColor: '#36498f'
                });
                <?php unset($_SESSION['success_password']); ?>
            <?php elseif ($mensaje_error_password): ?>
                Swal.fire({
                    title: 'Error en Contraseña',
                    text: '<?php echo $mensaje_error_password; ?>',
                    icon: 'error',
                    confirmButtonColor: '#36498f'
                }).then(() => {
                    abrirModalPassword();
                });
                <?php unset($_SESSION['error_password']); ?>
            <?php else: ?>
                // Si es apertura manual por parámetro en URL
                setTimeout(function () {
                    abrirModalPassword();
                }, 100);
            <?php endif; ?>

            // Limpiar URL
            if (window.history.replaceState) {
                const cleanUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
                window.history.replaceState({ path: cleanUrl }, '', cleanUrl);
            }
        });
    <?php endif; ?>

    // ─── VALIDACIÓN DEL FORMULARIO DE PERFIL ───
    // Previene el envío si faltan campos obligatorios.
    // Se reemplaza el formulario por un clon limpio
    // para evitar duplicación de eventos.
    document.addEventListener('DOMContentLoaded', function () {
        const formPerfil = document.getElementById('formPerfil');
        if (formPerfil) {
            // Remover cualquier listener previo que pueda estar interfiriendo
            const newForm = formPerfil.cloneNode(true);
            formPerfil.parentNode.replaceChild(newForm, formPerfil);

            // Agregar listener al nuevo formulario
            document.getElementById('formPerfil').addEventListener('submit', function (e) {
                // Validación básica
                const nom = document.getElementById('nombreCompleto').value;
                const mail = document.getElementById('email').value;
                const tel = document.getElementById('telefono').value;

                if (!nom || !mail || !tel) {
                    e.preventDefault();
                    alert('Por favor completa todos los campos');
                    return false;
                }
                // Permitir envío
            });
        }
    });

    // ══════════════════════════════════════════════
    // CIERRE DE SESIÓN SEGURO (OWASP)
    // ══════════════════════════════════════════════
    // Proceso:
    // 1. Muestra confirmación con modal personalizado
    // 2. Bloquea la navegación hacia atrás
    // 3. Limpia localStorage y sessionStorage (tokens)
    // 4. Llama al endpoint logout.php para destruir la sesión
    // 5. Redirige al inicio de sesión
    function cerrarSesionSeguro(event) {
        if (event) {
            event.preventDefault();
        }
        
        mostrarConfirmacionCustom(
            'Cerrar Sesión',
            '¿Estás seguro de que deseas cerrar sesión?',
            function () {
                ejecutarLogout();
            },
            'Sí, Cerrar Sesión'
        );
    }
    window.cerrarSesionSeguro = cerrarSesionSeguro;
    window.logout = cerrarSesionSeguro; // Alias para compatibilidad

    // Ejecuta el proceso de cierre de sesión
    function ejecutarLogout() {
        // Paso 1: Bloquear navegación hacia atrás
        window.history.pushState(null, null, window.location.href);
        window.onpopstate = function () {
            window.history.pushState(null, null, window.location.href);
            window.location.href = '../../index.html';
        };

        // Paso 2: Limpiar tokens almacenados en el navegador
        try {
            localStorage.removeItem('token');
            localStorage.clear();
        } catch (e) {
            console.error('Error al limpiar localStorage:', e);
        }

        // Paso 3: Limpiar almacenamiento temporal de sesión
        try {
            sessionStorage.clear();
        } catch (e) {
            console.error('Error al limpiar sessionStorage:', e);
        }

        // Paso 4: Llamar al servidor para destruir la sesión PHP
        fetch('logout.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-Requested-With': 'XMLHttpRequest'
            },
            credentials: 'same-origin',
            cache: 'no-store'
        })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Error en la respuesta del servidor');
                }
                return response.json();
            })
            .then(data => {
                if (data.success) {
                    // Paso 5: Redirigir a la página de inicio
                    const redirectUrl = data.redirect || '../../index.html';
                    window.location.replace(redirectUrl);
                } else {
                    // Aún así redirigir a index
                    window.location.replace('../../index.html');
                }
            })
            .catch(error => {
                console.error('Error al cerrar sesión:', error);
                // Aún así redirigir a index
                window.location.replace('../../index.html');
            });
    }

    // ─── PROTECCIÓN CONTRA NAVEGACIÓN HACIA ATRÁS ───
    // Si el usuario presiona "atrás" después de cerrar sesión,
    // se redirige automáticamente al inicio de sesión.
    window.addEventListener('pageshow', function (event) {
        if (event.persisted) {
            // Página cargada desde cache (botón atrás). Subir 2 niveles desde src/php/
            // para llegar a raíz y luego entrar a html/
            window.location.href = '../../html/InicioSesion.html';
        }
    });

    // ─── BLOQUEO DE BACKSPACE COMO NAVEGACIÓN ───
    // Evita que la tecla Backspace (retroceso) funcione
    // como botón "atrás" del navegador cuando no se está
    // escribiendo en un campo de texto.
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Backspace' && event.target.tagName !== 'INPUT' && event.target.tagName !== 'TEXTAREA') {
            // Prevenir navegación hacia atrás con Backspace fuera de campos de texto
            event.preventDefault();
        }
    });
    // --- Mostrar/Ocultar Contraseña ---
    function togglePasswordVisibility(inputId, icon) {
        const input = document.getElementById(inputId);
        if (input.type === 'password') {
            input.type = 'text';
            icon.classList.remove('fa-eye');
            icon.classList.add('fa-eye-slash');
        } else {
            input.type = 'password';
            icon.classList.remove('fa-eye-slash');
            icon.classList.add('fa-eye');
        }
    }
</script>
</body>

</html>