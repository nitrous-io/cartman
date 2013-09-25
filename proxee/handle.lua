local utils = require 'proxee.utils'

local parsed_host = utils.get_parsed_host(ngx.var.host, ngx.var.hostname)
local custom_proxy_host = ''

-- check if theres an explicit port mentioned
-- if not use 3000 as the default port
local port = parsed_host.port or 3000

local box, err = getBox(parsed_host.box_name)
if box ~= nil then
  custom_proxy_host = string.format('http://%s:%s', box.ip, port)
else
  ngx.log(ngx.WARN, 'Box details were not found: ', err)
  ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
  return
end

ngx.var.custom_proxy_host = custom_proxy_host
