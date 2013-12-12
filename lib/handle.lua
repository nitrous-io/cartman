package.path = './lib/?.lua;'..package.path

local utils = require 'utils'

local box_name = utils.box_name_from_host(ngx.var.host)
local custom_proxy_host = ''

local port = ngx.var.server_port

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
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
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
