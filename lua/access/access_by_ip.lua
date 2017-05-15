local util_table = require "util.table"
local util_cache = require "util.cache"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local lrucache = require "resty.lrucache.pureffi"
local ip_cache, err = lrucache.new(100)

-- seconds
local ttl = 5 * 60

local string_find = string.find

local alarm_count = { visit = 1000, detail = 50, download = 50 }

local isAlarm = function ( stat_count )
   for k,v in ipairs(alarm_count) do
      if stat_count[k] >= v then
        return true
      end
   end
   return false
end

local incr_count = function (ip_addr, count_stat)
    if not ip_addr then
      return
    end
    count_stat = count_stat or {}
    local dest_stat, _ = ip_cache:get(ip_addr)
    if not dest_stat then
      dest_stat = { ctime = ngx.time(), visit = 0,detail = 0, download = 0 }
    end
    dest_stat.visit = dest_stat.visit + 1
    dest_stat.detail = dest_stat.detail + count_stat.detail
    dest_stat.download = dest_stat.download + count_stat.download
    ip_cache:set(ip_addr, dest_stat, ttl)
    return dest_stat
end

function _M.access(ngx)
    local ip_addr = ngx.var.remote_addr
    local uri = ngx.var.uri
    if not ip_addr or  not uri then
      return
    end
    
    local count_stat = { detail = 0, download = 0 }
    if string_find(uri,'/movie/detail/') then
      count_stat.detail = 1
    elseif string_find(uri,'/movie/download') then
      count_stat.download = 1
    end
    local dest_stat = incr_count(ip_addr, count_stat)
    if isAlarm(dest_stat) then
      log(CRIT,"alarm,addr["..ip_addr.. "],visit:" .. dest_stat.visit 
          .. ",detail:" .. dest_stat.detail 
          .. ",download:" .. dest_stat.download..",uri:" .. uri)
      ngx.exit(ngx.HTTP_FORBIDDEN)
    else
      log(ERR,"addr["..ip_addr.. "],visit:" .. dest_stat.visit 
          .. ",detail:" .. dest_stat.detail 
          .. ",download:" .. dest_stat.download)
    end
end



return _M