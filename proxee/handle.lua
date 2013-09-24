local function parse_host(host)
  local output = {}

  for split_host, port in string.gmatch(host, "(%S+):(%S+)") do
    output.port = port
    -- FIXME: This will not work in production
    -- production urls would look like http://test-29911.apse1.actionbox.io:3000/
    -- grab the box host
    -- first subdomain infront of it should be considered as the boxname
    for box_name, domain, tld in string.gmatch(split_host, "(%S+)%.(%S+)%.(%S+)") do
      output.box_name = box_name
    end
  end

  return output
end

-- get subdomain from the host name
local host = ngx.req.get_headers()["Host"]
local parsed_host = parse_host(host)
local custom_proxy_host = ''

-- check if theres an explicit port mentioned
-- if not use 3000 as the default port
local port = parsed_host.port or 3000

local box, err = getBox(parsed_host.box_name)
if box ~= nil then
  custom_proxy_host = string.format('http://%s:%s', box.ip, port)
else
  ngx.log(ngx.WARN, 'Box details was not found: ', err)
  ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
  return
end

ngx.var.custom_proxy_host = custom_proxy_host
