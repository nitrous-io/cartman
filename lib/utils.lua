local _M = {}

local decode_base64 = ngx.decode_base64

function _M.box_name_from_host(host, position)
  local output = nil
  -- position of the box subdomain
  -- from right (0-indexed)
  -- default value is 3 (eg. box-name.region.boxhost.com)
  local position = position or 3

  if host then
    local subdomains = {}
    for subdomain in string.gmatch(host, "([^%.]+)%.") do
      table.insert(subdomains, subdomain)
    end

    local length = #subdomains
    output = subdomains[length - (position - 1)]
  end

  return output
end

function _M.valid_auth(header, username, password)
  if username == "" and password == "" then
    return true
  end

  local result = false

  if header and username and password then
    for hash_type, hash in string.gmatch(header, "(%w+) (%w+)") do
      if hash_type and hash_type == "Basic" then
        decoded_hash = decode_base64(hash)
        for given_username, given_password in string.gmatch(decoded_hash, "(%w+):(%w+)") do
          if (given_username == username) and (given_password == password) then
            result = true
          end
        end
      end
    end
  end

  return result
end


return _M
