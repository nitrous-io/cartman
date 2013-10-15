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
    local paidUser = box.paidUser

    if username ~= cjson.null and password ~= cjson.null then
      local authorization = ngx.req.get_headers()['Authorization']
      if not utils.valid_auth(authorization, username, password) then
        ngx.header["WWW-Authenticate"] = 'Basic realm="Proctected Box"'
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
      end
    end

    -- TODO: This must be covered in
    -- integration tests
    if port == "80" or port == "443" then
      if paidUser then
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
