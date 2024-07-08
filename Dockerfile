FROM nginx:1.27

ENV NGINX_VERSION=1.27.0

RUN apt update && apt upgrade -y
RUN set -x \
    && apt install vim git wget cron build-essential openssl libpcre3 libpcre3-dev libssl-dev zlib1g-dev libgd-dev -y

WORKDIR /tmp
RUN wget https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz \
    && tar -xzf nginx-$NGINX_VERSION.tar.gz

# https://github.com/LoicMahieu/alpine-nginx/blob/master/Dockerfile
# https://github.com/docker/awesome-compose/tree/master
WORKDIR /tmp/nginx-$NGINX_VERSION
RUN ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --user=nginx --group=nginx \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --with-compat \
        --with-file-aio \
        --with-threads \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-pcre \
        --with-http_image_filter_module=dynamic \
        --without-http_autoindex_module \
        --without-http_fastcgi_module \
        --with-stream \
        --with-stream_realip_module \
        --with-stream_ssl_module \
        --with-stream_ssl_preread_module \
        --with-http_v2_module \
#        --with-http_v3_module \
#        --with-openssl=../quiche/deps/boringssl \
#        --with-quiche=../quiche && \
#        --with-http_dav_module \
#        --with-http_flv_module \
#        --with-http_random_index_module \
#        --with-mail_ssl_module \
        --with-cc-opt='-g -O2 -ffile-prefix-map=/data/builder/debuild/nginx-1.25.2/debian/debuild-base/nginx-1.25.2=. -fstack-protector-strong -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fPIC' \
        --with-ld-opt='-Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie' \
    && make \
    && make install \
    && rm -rf /build

WORKDIR /root
COPY ./bashrc .

WORKDIR /etc/nginx
RUN rm conf.d/default.conf
COPY nginx.conf .
COPY sites-available sites-available

WORKDIR /etc/nginx/sites-enabled
RUN ln -s /etc/nginx/sites-available/default.conf

WORKDIR /etc/nginx/includes
COPY includes .

WORKDIR /app
COPY default default

# Bot Blocker
# https://github.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/tree/master
RUN wget https://raw.githubusercontent.com/mitchellkrogza/nginx-ultimate-bad-bot-blocker/master/install-ngxblocker -O /usr/local/sbin/install-ngxblocker \
    && chmod +x /usr/local/sbin/install-ngxblocker
WORKDIR /usr/local/sbin/
RUN ./install-ngxblocker -x \
    && chmod +x /usr/local/sbin/setup-ngxblocker \
    && chmod +x /usr/local/sbin/update-ngxblocker \
    && ./setup-ngxblocker -x -e conf
#RUN (crontab -l 2>/dev/null; echo "00 22 * * * /usr/local/sbin/update-ngxblocker") | sort - | uniq - | crontab -

WORKDIR /etc/nginx
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]