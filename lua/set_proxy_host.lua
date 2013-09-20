local redis = require 'resty.redis'
local cjson = require 'cjson'
local redisClient = redis:new()
local null = ngx.null

local function parseHost(host)
  local output = {}

  for splitHost, port in string.gmatch(host, "(%S+):(%S+)") do
    output.port = port
    for boxName, domain, tld in string.gmatch(splitHost, "(%S+)%.(%S+)%.(%S+)") do
      output.boxName = boxName
    end
  end

  return output
end

-- FIXME: Load Redis settings from ENV variables
-- local redisHost = os.getenv('REDIS_HOST')
-- local redisPort = os.getenv('REDIS_PORT')

local redisHost = '127.0.0.1'
local redisPort = 6379

redisClient:set_timeout(1000)

local ok, err = redisClient:connect(redisHost, redisPort)
if not ok then
  -- respond with an 500 status
  ngx.log(ngx.ERR, 'Failed to conect to Redis: ', err)
  ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
  return
end

-- get subdomain from the host name
local host = ngx.req.get_headers()["Host"]
local parsedHost = parseHost(host)
local custom_proxy_host = ''

-- check if theres an explicit port mentioned
-- if not use 3000 as the default port
local port = parsedHost.port or 3000

-- from redis pick the box for the host
-- set its IP as the proxy pass (include port if available)
local response, err = redisClient:hget('aio:boxes', parsedHost.boxName)
if response ~= null then
  box = cjson.decode(response)
  custom_proxy_host = string.format('http://%s:%s', box.ip, port)
else
  ngx.log(ngx.WARN, 'Box details was not found in Redis: ', err)
  ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
  return
end

ngx.var.custom_proxy_host = custom_proxy_host
