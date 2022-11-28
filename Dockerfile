# Default Dockerfile
#
# @link     https://www.hyperf.io
# @document https://doc.hyperf.io
# @contact  group@hyperf.io
# @license  https://github.com/hyperf-cloud/hyperf/blob/master/LICENSE

FROM hyperf/hyperf:8.0-alpine-v3.15-swoole
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    APP_ENV=prod \
    SW_VERSION=${SW_VERSION:-"v4.6.7"} \
    COMPOSER_VERSION=2.1.1 \
    #  install and remove building packages
    PHPIZE_DEPS="autoconf dpkg-dev dpkg file g++ gcc libc-dev make php8-dev php8-pear pkgconf re2c pcre-dev pcre2-dev zlib-dev libtool automake"

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# update
RUN set -ex \
    && apk update \
    # install igbinary extension
    && apk add --no-cache php8-pear php8-dev zlib-dev re2c gcc g++ make curl autoconf \
    && cp /usr/bin/phpize8 /usr/bin/phpize -f \
    && curl -fsSL "https://pecl.php.net/get/igbinary-3.2.6.tgz" -o igbinary.tgz \
    && mkdir -p /tmp/igbinary \
    && tar -xf igbinary.tgz -C /tmp/igbinary --strip-components=1 \
    && rm igbinary.tgz \
    && cd /tmp/igbinary \
    && phpize && ./configure --with-php-config=/usr/bin/php-config8 --enable-reader && make && make install \
    && echo "extension=igbinary.so" > /etc/php8/conf.d/igbinary.ini \
    # install xlswriter extension
    && curl -fsSL "https://pecl.php.net/get/xlswriter-1.5.1.tgz" -o xlswriter.tgz \
    && mkdir -p /tmp/xlswriter \
    && tar -xf xlswriter.tgz -C /tmp/xlswriter --strip-components=1 \
    && rm xlswriter.tgz \
    && cd /tmp/xlswriter \
    && phpize && ./configure --with-php-config=/usr/bin/php-config8 --enable-reader && make && make install \
    && echo "extension=xlswriter.so" > /etc/php8/conf.d/igbinary.ini \
    # install pcre2 extension \
    && curl -fsSL "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.37/pcre2-10.37.tar.gz" -o pcre2.tar.gz \
    && mkdir -p /tmp/pcre2 \
    && tar -xf pcre2.tar.gz -C /tmp/pcre2 --strip-components=1 \
    && rm pcre2.tar.gz \
    && cd /tmp/pcre2 \
    && ./configure --prefix=/usr/local/pcre2 && make && make install \
    && ln -s /usr/local/pcre2 /usr/sbin/pcre2 \
    # install mongodb extension \
    && curl -fsSL "https://pecl.php.net/get/mongodb-1.10.0.tgz" -o mongodb.tgz \
    && mkdir -p /tmp/mongodb \
    && tar -xf mongodb.tgz -C /tmp/mongodb --strip-components=1 \
    && rm mongodb.tgz \
    && cd /tmp/mongodb \
    && phpize && ./configure --with-php-config=/usr/bin/php-config8 --enable-reader && make && make install \
    && echo "extension=mongodb.so" > /etc/php8/conf.d/mongodb.ini \
    # install composer \
    && cd /tmp \
    && wget https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && composer config -g secure-http false \
    && ls  ~/.composer/  \
    && cat  ~/.composer/auth.json  \
    # show php version and extensions
    && php -v \
    && php -m \
    #  ---------- some config ----------
    && cd /etc/php8 \
    # - config PHP
    && { \
        echo "upload_max_filesize=100M"; \
        echo "post_max_size=108M"; \
        echo "memory_limit=1024M"; \
        echo "date.timezone=${TIMEZONE}"; \
    } | tee conf.d/99-overrides.ini \
    # - config timezone
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    # ---------- clear works ----------
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && echo -e "\033[42;37m Build Completed :).\033[0m\n"