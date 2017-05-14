local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'


local elasticsearch = require "elasticsearch"
local client = elasticsearch.client{
  hosts = {
    {
      host = "127.0.0.1",
      port = "9200"
    }
  },
  params = {
	maxRetryCount = 1
  }
}

local lrucache = require "resty.lrucache"
local cache, err = lrucache.new(1000)

function _M.client()
    return client
end

function _M.cache(ip_addr)
    return cache
end

return _M