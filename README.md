## How to setup in the Development Environment:

* Download OpenResty - http://openresty.org/download/ngx_openresty-1.4.2.8.tar.gz (or latest stable)
* Build and install OpenResty:
```
  tar xzvf ngx_openresty-VERSION.tar.gz
  cd ngx-openresty-VERSION/
  ./confgiure --with-luajit --prefix=/home/USERNAME/openresty
  make
  make install
```

* Append OpenResty's Nginx path to PATH

    PATH=$PATH:$HOME/openresty/nginx/sbin

(If you already have a system-wide Nginx installation, better to symlink the OpenResty's Nginx to something like `nx`)

* Switch to project directory;
  `export $(cat .env) && script/server`

This will start a Nginx server with the sample config avialble in (`config/nginx.conf`).

### Testing

**Integration testing**

* Run:
    sh spec/integration/proxee_spec.sh

*Note* You may need to update the name of Nginx in `script/server` depending on how it's exposed in PATH.

** Unit testing **

* Install `luarocks`
    
    sudo apt-get install luarocks

* Install `busted`
  
    luarocks install busted

* Then on the project's root, run:
    
    busted
