package.path = './lib/?.lua;'..package.path

local cjson = require 'cjson'
local lru_cache = require 'lru_cache'
local redis_client = require 'redis_client'

local null = ngx.null

local lru_cache_max = 100
local lru_cache_max_age = 10000

-- FIXME: Load Redis settings from ENV variables
-- local redisHost = os.getenv('REDIS_HOST')
-- local redisPort = os.getenv('REDIS_PORT')

local redis_host = '127.0.0.1'
local redis_port = 6379

local cache = lru_cache:new(lru_cache_max, lru_cache_max_age)

function get_box(name)
  item = cache:get(name)
  if item then
    return item, nil
  end

  local redis_conn, err = redis_client.connect(redis_host, redis_port)

  if err then
    ngx.log(ngx.ERR, 'Failed to conect to Redis: ', err)
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
