-- local access_by_ip = require "access.access_by_ip"
local util_cache = require "util.cache"

local remote_addr = ngx.var.remote_addr

util_cache.incr(remote_addr)