package.path = './lib/?.lua;'..package.path

local redis = require 'resty.redis'

local _M = {}

function _M.connect(host, port, password, db)
  local redis_client = redis:new()
  redis_client:set_timeout(1000)

  local ok, err = redis_client:connect(host, port)
  if not ok then
    return nil, err
  end

  if password then
    local ok, err = redis_client:auth(password)
    if not ok then
      return nil, err
    end
  end

  if db then
    local ok, err = redis_client:select(db)
    if not ok then
      return nil, err
    end
  end

  return redis_client, nil
end

function _M.keepalive(conn)
  -- use default keepalive values for now
  -- optimize it later
  conn:set_keepalive()
end

return _M
