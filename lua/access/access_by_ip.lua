local util_cache = require "util.cache"

local remote_addr = ngx.var.remote_addr

util_cache.incr(remote_addr)