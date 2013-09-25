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

* Switch to project directory and run `script/server` to start a Nginx server with the sample config.

### Testing

* Install `luarocks`
    
    sudo apt-get install luarocks

* Install `busted`
  
    sudo luarocks install busted


