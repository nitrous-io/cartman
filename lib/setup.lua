package.path = './lib/?.lua;'..package.path

local cjson = require 'cjson'
local lru_cache = require 'lru_cache'
local redis_client = require 'redis_client'
local config = require 'config'

local null = ngx.null

local cache = lru_cache:new(config.lru_cache_max, config.lru_cache_max_age)

function get_box(name)
  item = cache:get(name)
  if item then
    return item, nil
  end

  local redis_conn, err = redis_client.connect(config.redis_host, config.redis_port, config.redis_password, config.redis_db)

  if err then
    ngx.log(ngx.ERR, 'Failed to connect to Redis: ', err)
    return
  end

  local response, err = redis_conn:hget('aio:boxes', name)
  if response ~= null then
    item = cjson.decode(response)
    cache:set(name, item)
    return item, nil
  else
    return nil, err
  end

  redis_client.keepalive(redis_conn)
end
