FROM wordpress:latest

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y \
    libzip-dev \
    zip \
    unzip \
    wget \
    && docker-php-ext-install zip \
    && rm -rf /var/lib/apt/lists/*

# WP-CLI インストール（WordPress管理用）
RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# パーミッション設定
RUN chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

EXPOSE 80