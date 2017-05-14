-- local access_by_ip = require "access.access_by_ip"
local util_cache = require "util.cache"

local remote_addr = ngx.var.remote_addr
local uri = ngx.var.uri
if not uri then
	return
end
local find = string.find
local count_stat = { detail = 0, download = 0 }
if find(uri,'/movie/detail/') then
	count_stat.detail = 1
elseif find(uri,'/movie/download') then
	count_stat.download = 1
end
util_cache.incr(remote_addr, count_stat)