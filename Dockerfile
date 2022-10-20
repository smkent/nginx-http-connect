ARG NGINX_VERSION_MAJOR=1
ARG NGINX_VERSION_MINOR=22
ARG NGINX_VERSION_POINT=0
ARG CONNECT_PATCH_REPO_REF=v0.0.3
ARG CONNECT_PATCH_VERSION=102101

ARG NGINX_VERSION=${NGINX_VERSION_MAJOR}.${NGINX_VERSION_MINOR}.${NGINX_VERSION_POINT}

FROM nginx:${NGINX_VERSION_MAJOR}.${NGINX_VERSION_MINOR}-alpine as upstream
FROM alpine:latest as builder

ARG NGINX_VERSION
ARG CONNECT_PATCH_REPO_REF
ARG CONNECT_PATCH_VERSION

RUN apk add --no-cache --virtual .build-deps \
        alpine-sdk \
        bash \
        findutils \
        gcc \
        gd-dev \
        geoip-dev \
        git \
        libc-dev \
        libedit-dev \
        libxslt-dev \
        linux-headers \
        make \
        openssl-dev \
        pcre2-dev \
        perl-dev \
        zlib-dev

# Apply HTTP CONNECT patch
WORKDIR /app
RUN git clone https://github.com/chobits/ngx_http_proxy_connect_module -b ${CONNECT_PATCH_REPO_REF}
RUN wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar zxvf nginx-*.tar.gz \
    && cd /app/nginx-* \
    && patch -p1 < /app/ngx_http_proxy_connect_module/patch/proxy_connect_rewrite_${CONNECT_PATCH_VERSION}.patch

COPY --from=upstream /usr/sbin/nginx /app/upstream-nginx

# Build nginx with same --configure options as upstream
RUN cd /app/nginx-* \
    && ./configure \
        $(/app/upstream-nginx -V 2>&1 \
            | grep '^configure arguments:' | cut -d: -f2 \
            | sed -e "s/--with-cc-opt='-Os -fomit-frame-pointer -g'/--with-cc-opt='-Os'/" -e 's| --add-dynamic-module=[^ ]*||g' \
        ) \
        --add-dynamic-module=/app/ngx_http_proxy_connect_module \
    && make -j$(grep processor /proc/cpuinfo | wc -l) \
    && make install -j$(grep processor /proc/cpuinfo | wc -l)

# Build output image
FROM upstream as publish
ARG NGINX_VERSION
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /app/nginx-${NGINX_VERSION}/objs/ngx_http_proxy_connect_module.so /usr/lib/nginx/modules
RUN sed '1s;^;load_module\ /usr/lib/nginx/modules/ngx_http_proxy_connect_module.so\;\n;' -i /etc/nginx/nginx.conf

# Add overrides and extras
RUN apk add --no-cache inotify-tools tini
COPY extras /smkent-extras
RUN ln -svf /smkent-extras/map-hosts /docker-entrypoint.d/99-map-hosts.sh
ENTRYPOINT ["/sbin/tini", "-g", "--", "/smkent-extras/entrypoint"]
