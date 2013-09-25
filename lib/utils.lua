local _M = {}

local decode_base64 = ngx.decode_base64

function _M.parse_host(host, hostname)
  local output = {}

  if host and hostname then
    local subdomains = {}
    local start_of_hostname = string.find(host, hostname, 0, true)

    if start_of_hostname then
      local subdomains_portion = string.sub(host, 0, (start_of_hostname - 1))
      for subdomain in string.gmatch(subdomains_portion, "([^%.]+)%.") do
        table.insert(subdomains, subdomain)
      end

      output.box_name = table.remove(subdomains)
    end
  end

  return output
end

function _M.valid_auth(header, username, password)
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
