local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local lrucache = require "resty.lrucache.pureffi"
local cache, err = lrucache.new(1000)

-- seconds
local ttl = 5 * 60

function _M.incr(ip_addr, count_stat)
    if not ip_addr then
      return
    end
    count_stat = count_stat or {}
    local key = "ip:" .. ip_addr
    local visit_obj, _ = cache:get(key)
    if not visit_obj then
      visit_obj = { ctime = ngx.time(), visit = 0,detail = 0, download = 0 }
    end
    visit_obj.visit = visit_obj.visit + 1
    visit_obj.detail = visit_obj.detail + count_stat.detail
    visit_obj.download = visit_obj.download + count_stat.download
    log(ERR,"visit["..ip_addr.. "],visit:" .. visit_obj.visit 
      .. ",detail:" .. visit_obj.detail 
      .. ",download:" .. visit_obj.download)
    cache:set(key, visit_obj, ttl)
end

return _M