FROM php:8.4-fpm-alpine AS php-base

WORKDIR /var/www/html

RUN apk add --no-cache \
        bash \
        icu-libs \
        libpq \
        libzip \
        oniguruma \
    && apk add --no-cache --virtual .build-deps \
        icu-dev \
        libpq-dev \
        libzip-dev \
        oniguruma-dev \
    && docker-php-ext-install \
        bcmath \
        intl \
        mbstring \
        opcache \
        pcntl \
        pdo_pgsql \
        pgsql \
        zip \
    && apk del .build-deps

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY docker/php/opcache.ini "$PHP_INI_DIR/conf.d/opcache.ini"


FROM composer:2 AS vendor

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --no-scripts \
    --optimize-autoloader


FROM node:24-alpine AS assets

WORKDIR /app

COPY package.json package-lock.json vite.config.js ./
COPY resources ./resources
COPY public ./public
RUN npm ci && npm run build


FROM php-base AS dev

ENV APP_ENV=local \
    COMPOSER_ALLOW_SUPERUSER=1

COPY . .
RUN composer install \
        --prefer-dist \
        --no-interaction \
        --no-progress \
    && mkdir -p \
        storage/framework/cache \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]


FROM php-base AS app

ENV APP_ENV=production \
    COMPOSER_ALLOW_SUPERUSER=1

COPY --chown=www-data:www-data . .
COPY --from=vendor --chown=www-data:www-data /app/vendor ./vendor
COPY --from=assets --chown=www-data:www-data /app/public/build ./public/build

RUN php artisan package:discover --ansi \
    && mkdir -p \
        storage/framework/cache \
        storage/framework/sessions \
        storage/framework/views \
        storage/logs \
        bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R ug+rwX storage bootstrap/cache

USER www-data

EXPOSE 9000

CMD ["php-fpm"]


FROM nginx:1.29-alpine AS nginx

WORKDIR /var/www/html

COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY public ./public
COPY --from=assets /app/public/build ./public/build

EXPOSE 80
