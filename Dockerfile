FROM serversideup/php:8.1-fpm

USER root

# Install dependencies including GD requirements
RUN apt-get update && apt-get install -y \
    libexif-dev \
    curl \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install exif gd

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Create Laravel cache directory and set permissions
RUN mkdir -p /var/www/bootstrap/cache /var/www/storage/logs \
    && chown -R www-data:www-data /var/www \
    && chmod -R 775 /var/www/bootstrap/cache /var/www/storage

USER www-data