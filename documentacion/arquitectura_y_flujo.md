# Arquitectura y Flujo Detallado del Sistema

Este documento describe la arquitectura técnica y el flujo de datos del sistema, desde el inicio de sesión hasta la gestión de historiales y auditoría.

## 1. Arquitectura General
El sistema sigue una arquitectura de tres capas (3-Tier):

1.  **Frontend (Presentación):** Basado en HTML5, CSS3 y JavaScript vanila. Utiliza controladores en JS para manejar la lógica de la interfaz y peticiones `fetch`.
2.  **Backend (Lógica de Negocio):** Implementado en PHP 8+. Actúa como una API RESTful que procesa peticiones, valida seguridad (JWT/Sesiones) y delega la persistencia a la base de datos.
3.  **Base de Datos (Persistencia):** PostgreSQL. No es solo un almacén de datos; contiene gran parte de la lógica de negocio mediante funciones en **PL/pgSQL**, garantizando integridad y rendimiento.

---

## 2. Flujo de Autenticación (Login)

### Paso A: Interfaz (`inicio_sesion.js`)
*   El usuario ingresa credenciales en el formulario.
*   El JS captura el evento `submit`, previene la recarga y envía los datos mediante un `POST` a `validar.php`.

### Paso B: Procesamiento (`validar.php`)
*   **Conexión:** Instancia la clase `CConexion` (definida en `conexion.php`), la cual utiliza **PDO** (PHP Data Objects) para abrir un túnel seguro con PostgreSQL.
*   **Consulta Preparada:** Se busca al usuario usando `:usuario` para prevenir inyecciones SQL.
*   **Verificación de Hash:** 
    *   Si la contraseña guardada es un texto plano (legado), se compara y se actualiza automáticamente a un hash moderno (`password_hash`).
    *   Si es hash, se valida con `password_verify()`.
*   **Generación de Token:** Si es válido, se consulta `tab_parametros` para obtener el tiempo de inactividad permitido (`ind_idle`) y se genera un token **JWT** (JSON Web Token) con los datos del usuario y fecha de expiración.

### Paso C: Sesión
*   El servidor responde con un JSON que contiene el token y el perfil.
*   El frontend guarda el token y redirige al dashboard.

---

## 3. Flujo del Dashboard y Carga de Datos

### Carga de Estadísticas
1.  Al entrar al dashboard, el archivo `dashboard_controller.js` realiza una petición `GET` a `api_gestion.php?tipo=stats`.
2.  **Enrutamiento (`api_gestion.php`):** Verifica que exista una sesión activa. Si es válida, instancia `CQuerys` y delega la petición al controlador modular `ApiDashboardController::handleGet`.
3.  **Lógica del Controlador (`ApiDashboardController.php`):** Llama al método `$db->getStats()` de la clase `CQuerys`.
4.  **Capa de Datos (`querys.php`):** Ejecuta la consulta: `SELECT ... FROM fun_obtener_stats()`. 
    *   *Nota:* Aquí se ve la potencia del motor; PHP solo pide los resultados, mientras que la función SQL `fun_obtener_stats` se encarga de contar usuarios, sumar ventas y buscar productos con bajo stock en una sola operación atómica.
5.  **Renderizado:** El JSON resultante viaja al frontend, donde el JS inyecta los valores en las "tarjetas" (cards) de la interfaz.

---

## 4. Gestión de Datos (CRUD): Ejemplo Empleados/Proveedores

### Creación / Actualización
1.  **Captura (`logica.js`):** El usuario llena un modal. Al dar click en "Guardar", se recolectan los datos y se envían a `api_gestion.php` con `accion=create` o `update`.
2.  **Validación en Controladores:** `ApiDashboardController` recibe los nombres de los campos (ej: "nom_cargo") y utiliza el método `getIdByName` para buscar su ID interno en la base de datos.
3.  **Llamada a Funciones SQL:** 
    *   En lugar de hacer un `INSERT` simple desde PHP, se llama a funciones como `fun_insert_empleados(...)`.
    *   **Integridad en BD:** Estas funciones (visualizadas en la carpeta `BACK/Fun_insert`) realizan IFs de validación para asegurar que el Banco exista, que el salario sea mayor al mínimo, etc.
    *   **Manejo de Errores:** Usan `RAISE NOTICE` para informar errores al PHP sin romper la transacción SQL innecesariamente.

---

## 5. Sección de Historial y Auditoría

### El Motor de Auditoría (`Audit Trail`)
El sistema cuenta con un sistema de trazabilidad robusto definido en `script_instalacion_audit_trail.sql`.

*   **Triggers:** Casi todas las tablas importantes tienen disparadores (triggers) que se activan ante un `INSERT`, `UPDATE` o `DELETE`.
*   **Función de Auditoría:** Cuando ocurre un cambio, el trigger llama a la lógica de auditoría que registra:
    *   Quién hizo el cambio (`current_user`).
    *   Qué tabla se modificó.
    *   Los datos anteriores y los datos nuevos.
    *   La fecha y hora exacta (`NOW()`).

### Visualización (`ApiHistorialController.php`)
1.  Cuando accedes a la sección de Historial, se solicita el `tipo=historial` a la API.
2.  El controlador invoca funciones como `fun_audit_trail()` o consulta directamente las tablas de logs.
3.  Esto permite al administrador ver quién modificó el sueldo de un empleado o quién eliminó un proveedor, proporcionando transparencia total sobre las operaciones sensibles.

---

## 6. Patrones de Diseño Utilizados

1.  **Singleton/Punto Único de Entrada:** `api_gestion.php` centraliza todas las peticiones administrativas, forzando cabeceras de seguridad (`security_headers.php`) en cada llamada.
2.  **Data Mapper / Query Class:** `CQuerys` actúa como una capa de abstracción. Ningún controlador escribe SQL directamente; le piden a `CQuerys` que ejecute la lógica necesaria.
3.  **Programación Orientada a Base de Datos:** Se delega la lógica pesada a PostgreSQL (PL/pgSQL), lo que permite que el sistema sea escalable y las consultas PHP sean extremadamente ligeras y rápidas.
4.  **Uso de PDO:** Todas las comunicaciones PHP-BD usan parámetros vinculados (`bindValue`), eliminando cualquier riesgo de Inyección SQL.
