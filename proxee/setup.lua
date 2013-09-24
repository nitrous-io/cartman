redis = require 'resty.redis'
cjson = require 'cjson'
lru_cache = require 'proxee.lru_cache'

local null = ngx.null

local lru_cache_max = 100
local lru_cache_max_age = 10000

local cache = lru_cache:new(lru_cache_max, lru_cache_max_age)

local function connect_to_redis()
  local redis_client = redis:new()

  -- FIXME: Load Redis settings from ENV variables
  -- local redisHost = os.getenv('REDIS_HOST')
  -- local redisPort = os.getenv('REDIS_PORT')

  local redis_host = '127.0.0.1'
  local redis_port = 6379

  redis_client:set_timeout(1000)

  local ok, err = redis_client:connect(redis_host, redis_port)
  if not ok then
    ngx.log(ngx.ERR, 'Failed to conect to Redis: ', err)
  else
    return redis_client
  end
end

function getBox(name)
  item = cache:get(name)
  if item then
    return item, nil
  end

  local redis_client = connect_to_redis()
  local response, err = redis_client:hget('aio:boxes', name)
  if response ~= null then
    item = cjson.decode(response)
    cache:set(name, item)
    return item, nil
  else
    return nil, err
  end
end
