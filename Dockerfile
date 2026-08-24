FROM php:8.2-apache

# Actualizar e instalar dependencias del sistema y librerías PostgreSQL
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Habilitar mod_rewrite y cabeceras de Apache
RUN a2enmod rewrite headers

# Configuración personalizada de PHP (seguridad y rendimiento)
RUN echo "expose_php = Off" > /usr/local/etc/php/conf.d/security.ini \
    && echo "display_errors = Off" >> /usr/local/etc/php/conf.d/security.ini \
    && echo "log_errors = On" >> /usr/local/etc/php/conf.d/security.ini \
    && echo "memory_limit = 128M" >> /usr/local/etc/php/conf.d/security.ini \
    && echo "upload_max_filesize = 10M" >> /usr/local/etc/php/conf.d/security.ini \
    && echo "post_max_size = 10M" >> /usr/local/etc/php/conf.d/security.ini

WORKDIR /var/www/html

# Copiar el código del sistema
COPY ["./sistema/Front y Logica/", "/var/www/html/"]

# Asegurar permisos correctos
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
