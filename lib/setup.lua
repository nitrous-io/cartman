package.path = './lib/?.lua;'..package.path

cjson = require 'cjson'

local lru_cache = require 'lru_cache'
local redis_client = require 'redis_client'
local settings = require 'settings'

local null = ngx.null

cache = lru_cache:new(settings.lru_cache_max, settings.lru_cache_max_age)

function get_box(id)
  item = cache:get(id)
  if item then
    return item, nil
  end

  local redis_conn, err = redis_client.connect(settings.redis_host, settings.redis_port, settings.redis_password, settings.redis_db)

  if err then
    ngx.log(ngx.ERR, 'Failed to connect to Redis: ', err)
    return
  end

  local response, err = redis_conn:hget('aio:boxes', id)
  if response ~= null then
    item = cjson.decode(response)
    cache:set(id, item)
    return item, nil
  else
    return nil, err
  end

  redis_client.keepalive(redis_conn)
end
