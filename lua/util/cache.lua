local util_table = require "util.table"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local lrucache = require "resty.lrucache.pureffi"
local ip_cache, err = lrucache.new(100)


function _M.cache_by_ip()
  return ip_cache
end

return _M