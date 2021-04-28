# Default Dockerfile
#
# @link     https://www.hyperf.io
# @document https://doc.hyperf.io
# @contact  group@hyperf.io
# @license  https://github.com/hyperf-cloud/hyperf/blob/master/LICENSE

FROM hyperf/hyperf:7.3-alpine-v3.9-swoole
LABEL maintainer="Hyperf Developers <group@hyperf.io>" version="1.0" license="MIT"

##
# ---------- env settings ----------
##
# --build-arg timezone=Asia/Shanghai
ARG timezone

ENV TIMEZONE=${timezone:-"Asia/Shanghai"} \
    COMPOSER_VERSION=1.9.1 \
    APP_ENV=prod

# update
RUN set -ex \
    && apk update \
    # install composer
    && cd /tmp \
    && wget https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod u+x composer.phar \
    && mv composer.phar /usr/local/bin/composer \
    && composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ \
    && composer config -g secure-http false \
    && echo  '{"bitbucket-oauth":{},"github-oauth":{},"gitlab-oauth":{},"gitlab-token":{"47.106.79.235":"CDHpGe4_Poa2TMxyya_T"},"http-basic":{},"gitlab-domains":["47.106.79.235"]}' > ~/.composer/auth.json \
    && ls  ~/.composer/  \
    && cat  ~/.composer/auth.json  \
    # add igbinary extensions
    && apk add --no-cache php7-pear php7-dev zlib-dev re2c gcc g++ make curl autoconf\
    && cp /usr/bin/phpize7 /usr/bin/phpize -f \
    && curl -fsSL "https://pecl.php.net/get/igbinary-3.2.2.tgz" -o igbinary.tgz \
    && mkdir -p /tmp/igbinary \
    && tar -xf igbinary.tgz -C /tmp/igbinary --strip-components=1 \
    && rm igbinary.tgz \
    && cd /tmp/igbinary \
    && phpize && ./configure --with-php-config=/usr/bin/php-config7 --enable-reader && make && make install \
    && echo "extension=igbinary.so" > /etc/php7/conf.d/igbinary.ini \
    && rm -rf /var/cache/apk/* /tmp/* /usr/share/man \
    && php -m \
    && php --ri igbinary \
    # show php version and extensions
    && php -v \
    && php -m \
    #  ---------- some config ----------
    && cd /etc/php7 \
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
