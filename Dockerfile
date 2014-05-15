FROM ubuntu:precise

ENV OPENRESTY_VERSION 1.5.12.1
ENV OPENRESTY_URL http://openresty.org/download/ngx_openresty-1.5.12.1.tar.gz

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu precise-updates main universe" >> /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu precise-security main universe" >> /etc/apt/sources.list

RUN apt-get update && apt-get -yy install \
  build-essential \
  libgd2-xpm-dev \
  libncurses5-dev \
  libpcre3-dev \
  libpcre3-dev \
  libreadline-dev \
  libssl-dev \
  libxslt1-dev \
  make \
  perl \
  reprepro \
  ruby1.9.1 \
  ruby1.9.1-dev \
  s3cmd \
  wget

RUN gem install --no-rdoc --no-ri fpm --version 1.0.2

RUN wget $OPENRESTY_URL \
  && tar -xzvf ngx_openresty-$OPENRESTY_VERSION.tar.gz \
  && cd ngx_openresty-$OPENRESTY_VERSION \
  && ./configure --with-luajit \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-log-path=/var/log/nginx/access.log \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/var/run/nginx.pid \
  --with-ipv6 \
  --with-md5-asm \
  --with-sha1-asm \
  --without-http_ssi_module \
  --without-mail_smtp_module \
  --without-mail_imap_module \
  --without-mail_pop3_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_gzip_static_module \
  --with-http_realip_module \
  && make

ENV OPENRESTY_DIR ngx_openresty-$OPENRESTY_VERSION
ENV CARTMAN_DIR /opt/cartman
ADD . /opt/cartman
