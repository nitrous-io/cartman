# Cartman

                    _._
                __.{,_.).__
             .-"           "-.
           .'  __.........__  '.
          /.-'`___.......___`'-.\
         /_.-'` /   \ /   \ `'-._\
         |     |   '/ \'   |     |
         |      '-'     '-'      |
         ;                       ;
         _\         ___         /_
        /  '.'-.__  ___  __.-'.'  \
      _/_    `'-..._____...-'`    _\_
     /   \           .           /   \
     \____)         .           (____/
         \___________.___________/
           \___________________/
          (_____________________)

An Nginx extension (written in Lua), which proxies requests to boxes.

Features:
- Supports web sockets proxying
- Basic HTTP Auth
- Forwards SSL and port 80 traffic to port 3000
- Caches box details for performance

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
  script/server
```
  This will start an Nginx server with the sample config in `config/nginx.conf`.
  *Note* You may need to update the name of Nginx in `script/server` depending on how it's exposed in `PATH`.

### Testing

* Install [busted](http://olivinelabs.com/busted/)
```
  apt-get install luarocks
  luarocks install busted
```

* You may need to install `curl` too: `apt-get install curl`

* Then on the project's root, run:
```
  script/test
```
