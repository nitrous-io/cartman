FROM ubuntu

ENV OPENRESTY_VERSION 1.5.8.1
ENV OPENRESTY_URL http://openresty.org/download/ngx_openresty-1.5.8.1.tar.gz

RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu precise-updates main universe" >> /etc/apt/sources.list
RUN echo "deb http://archive.ubuntu.com/ubuntu precise-security main universe" >> /etc/apt/sources.list
RUN apt-get update

RUN apt-get -yy install \
  curl \
  dnsmasq \
  libncurses5-dev \
  libpcre3-dev \
  libreadline-dev \
  libssl-dev \
  luarocks \
  make \
  perl \
  redis-server \
  wget

RUN luarocks install busted

RUN wget $OPENRESTY_URL \
  && tar -xzvf ngx_openresty-$OPENRESTY_VERSION.tar.gz \
  && cd ngx_openresty-$OPENRESTY_VERSION \
  && ./configure --with-luajit \
  && make \
  && make install

RUN ln -sf /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nx

# dnsmasq configuration
RUN echo 'listen-address=127.0.0.1' >> /etc/dnsmasq.conf \
  && echo 'resolv-file=/etc/resolv.dnsmasq.conf' >> /etc/dnsmasq.conf \
  && echo 'conf-dir=/etc/dnsmasq.d' >> /etc/dnsmasq.conf

WORKDIR /var/cartman
