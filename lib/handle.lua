package.path = './lib/?.lua;'..package.path

local utils = require 'utils'

local parsed_host = utils.parse_host(ngx.var.host, ngx.var.hostname)
local custom_proxy_host = ''

-- check if theres an explicit port mentioned
-- if not use 3000 as the default port
local port = parsed_host.port or 3000

local box, err = get_box(parsed_host.box_name)
if box ~= nil then
  local username = box.authUsername
  local password = box.authPassword

  if username and password then
    if not utils.valid_auth(ngx.var.authorization, username, password) then
      ngx.header["WWW-Authenticate"] = 'Basic realm="Proctected Box"'
      ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
  end

  custom_proxy_host = string.format('http://%s:%s', box.ip, port)
else
  ngx.log(ngx.WARN, 'Box details were not found: ', err)
  ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
  return
end

ngx.var.custom_proxy_host = custom_proxy_host
