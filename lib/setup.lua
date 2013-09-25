package.path = './lib/?.lua;'..package.path

local cjson = require 'cjson'
local lru_cache = require 'lru_cache'
local redis_client = require 'redis_client'

local null = ngx.null

local lru_cache_max = tonumber(os.getenv('LRU_CACHE_MAX'), 10)
local lru_cache_max_age = tonumber(os.getenv('LRU_CACHE_MAX_AGE'), 10)

local redis_host = os.getenv('REDIS_HOST')
local redis_port = tonumber(os.getenv('REDIS_PORT'), 10)

local cache = lru_cache:new(lru_cache_max, lru_cache_max_age)

function get_box(name)
  item = cache:get(name)
  if item then
    ngx.log(ngx.ERR, 'got item from cache')
    return item, nil
  end

  local redis_conn, err = redis_client.connect(redis_host, redis_port)

  if err then
    ngx.log(ngx.ERR, 'Failed to connect to Redis: ', err)
  end

  local response, err = redis_conn:hget('aio:boxes', name)
  if response ~= null then
    item = cjson.decode(response)
    ngx.log(ngx.ERR, 'got item from redis')
    cache:set(name, item)
    return item, nil
  else
    return nil, err
  end

  redis_client.keepalive(redis_conn)
end
