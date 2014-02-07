local utils = require 'utils'
local settings = require 'settings'

local track_url = settings.track_url
local box_name = utils.box_name_from_host(ngx.var.host)
local port = ngx.var.server_port

local body= ngx.arg[1]
local inject_code = [[<img height="1" width="1" src="]]..track_url..[[?box=]]..box_name..[[&port=]]..port..[["/>]]
ngx.arg[1] = string.gsub(body, "</body>", inject_code.."%1", 1)
ngx.log(ngx.ERR, ngx.arg[1])
