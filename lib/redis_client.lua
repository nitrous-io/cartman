package.path = './lib/?.lua;'..package.path

local redis = require 'resty.redis'

local _M = {}

function _M.connect(host, port)
  local redis_client = redis:new()
  redis_client:set_timeout(1000)

  local ok, err = redis_client:connect(host, port)
  return redis_client, err
end

function _M.keepalive(conn)
  -- use default keepalive values for now
  -- optimize it later
  conn:set_keepalive()
end

return _M
