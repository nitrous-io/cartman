package.path = './lib/?.lua;'..package.path

local cjson = require 'cjson'
local utils = require 'utils'

local settings = require 'settings'
local cache = ngx.shared.cache
local null = ngx.null

function get_box(id)
  -- try to fetch cached response from shared memory
  local cached_response = cache:get(id)
  if cached_response then
    local box = cjson.decode(cached_response)
    return box, nil
  end

  local redis = require 'resty.redis'
  local red = redis:new()
  red:set_timeout(1000) -- 1 sec

  -- estabilish connection to redis server
  local ok, err = red:connect(settings.redis_host, settings.redis_port)
  if err then
    ngx.log(ngx.ERR, 'Failed to connect to Redis: ', err)
    return
  end

  -- authenticate
  if settings.redis_password ~= "" then
    local ok, err = red:auth(settings.redis_password)
    if err then
      ngx.log(ngx.ERR, "Failed to authenticate: ", err)
      return
    end
  end

  -- select db
  local ok, err = red:select(settings.redis_db)
  if err then
    ngx.log(ngx.ERR, "Failed to select db: ", err)
    return
  end

  -- get box details, finally :)
  local response, err = red:hget('aio:boxes', id)
  if response ~= null then
    cache:set(id, response)
    local box = cjson.decode(response)
    return box, nil
  else
    return nil, err
  end
end

local box_name = utils.box_name_from_host(ngx.var.host)
local port = ngx.var.server_port

local custom_proxy_host = ''

if box_name then
  local box, err = get_box(box_name)
  if box ~= nil then
    local username = box.authUsername or cjson.null
    local password = box.authPassword or cjson.null
    local premium = box.premium or cjson.null

    -- FIXME: why cant these conditions be merged into utils.valid_auth
    if username ~= cjson.null and password ~= cjson.null then
      -- if the username and password be empty string, as using a value as both
      -- null and string is really a bad idea, then its the same as both values
      -- are null
      local authorization = ngx.req.get_headers()['Authorization']
      if not utils.valid_auth(authorization, username, password) then
        ngx.header["WWW-Authenticate"] = 'Basic realm="Proctected Box"'
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
      end
    end

    -- TODO: This must be covered in
    -- integration tests
    -- forward all port 80 traffic to port 3000
    if port == "80" then
      port = "3000"
    end

    -- forward port 443 traffic only if the user is a paid user
    if port == "443" then
      -- have to check for true explicitly
      -- due to cjson.null and nil are 2 different values.
      if premium == true then
        port = "3000"
      else
        -- don't allow access for free users
        ngx.exit(403)
      end
    end

    custom_proxy_host = string.format('http://%s:%s', box.ip, port)
  else
    ngx.log(ngx.WARN, 'Box details were not found: ', err)
    ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    return
  end
else
  ngx.log(ngx.ERR, 'Invalid request: ', ngx.var.host)
  ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

ngx.var.custom_proxy_host = custom_proxy_host
