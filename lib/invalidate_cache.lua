package.path = './lib/?.lua;'..package.path

local uri_args = ngx.req.get_uri_args()
local id = uri_args['id']

cache:del(id)
ngx.exit(ngx.HTTP_OK)
