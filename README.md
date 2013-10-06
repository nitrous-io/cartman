# Proxee (as an Nginx module)

### How to setup in the Development Environment:

* Download OpenResty - http://openresty.org/download/ngx_openresty-1.4.2.8.tar.gz (or latest stable)
* Install dependencies:
```
apt-get install libreadline-dev libncurses5-dev libpcre3-dev libssl-dev perl make
```

* Build and install OpenResty:
```
  tar xzvf ngx_openresty-VERSION.tar.gz
  cd ngx-openresty-VERSION/
  ./configure --with-luajit --prefix=/home/USERNAME/openresty
  make
  make install
```

* Append OpenResty's Nginx path to PATH
```
  PATH=$PATH:$HOME/openresty/nginx/sbin
```
  (If you already have a system-wide Nginx installation, better to symlink the OpenResty's Nginx to something like `nx`)

* Switch to project directory and run:
```
  export $(cat .env) && script/server
```
  This will start an Nginx server with the sample config in `config/nginx.conf`.
  *Note* You may need to update the name of Nginx in `script/server` depending on how it's exposed in `PATH`.

### Testing

**Integration tests**

* You may need to install `curl` first: `apt-get install curl`.
* Run:
```
  sh spec/integration/proxee_spec.sh
```

**Unit testing**

* Install [busted](http://olivinelabs.com/busted/)
```
  apt-get install luarocks
  luarocks install busted
```

* Then on the project's root, run:
```
  busted
```
