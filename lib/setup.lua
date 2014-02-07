package.path = './lib/?.lua;'..package.path

cjson = require 'cjson'

settings = require 'settings'
null = ngx.null

local lru_cache = require 'lru_cache'
cache = lru_cache:new(settings.lru_cache_max, settings.lru_cache_max_age)
