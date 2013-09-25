local _M = {}

function _M.get_parsed_host(host, hostname)
  local output = {}

  local subdomains = {}
  local hostname_start = string.find(host, hostname, 0, true)
  local subdomains_portion = string.sub(host, 0, (hostname_start - 1))

  if subdomains_portion then
    for subdomain in string.gmatch(subdomains_portion, "([^%.]+)%.") do
      table.insert(subdomains, subdomain)
    end

    output.box_name = table.remove(subdomains)
  end

  return output
end

return _M
