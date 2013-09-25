local _M = {}

function _M.parse_host(host, hostname)
  local output = {}

  local subdomains = {}
  local start_of_hostname = string.find(host, hostname, 0, true)

  if start_of_hostname then
    local subdomains_portion = string.sub(host, 0, (start_of_hostname - 1))
    for subdomain in string.gmatch(subdomains_portion, "([^%.]+)%.") do
      table.insert(subdomains, subdomain)
    end

    output.box_name = table.remove(subdomains)
  end

  return output
end

return _M
