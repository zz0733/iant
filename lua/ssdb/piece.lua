local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local ssdb_client = require "ssdb.client"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'


function open( )
   local client,err = ssdb_client:newClient();
   if err then
      return nil, err
   end
   return client
end
function close( client )
   if not client then
      return
   end
   local ok, err = client:set_keepalive(0, 20)
   if err then
      log(ERR,"failed to set keepalive:", err)
   end
end

function toSSDBKey( hash, start )
  return "piece_" .. hash .. "_" .. start
end

function _M:setValue(hash, start, val)
   local client =  open();
   local ret, err = client:set(toSSDBKey(hash, start), val)
   close(client)
   return ret, err
end

function _M:getValue(hash, start)
   local client =  open();
   local ret, err = client:get(toSSDBKey(hash, start))
   close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return ret
end

function _M:keys(hash, limit)
   local client =  open();
   local keyStart = 'piece_' .. hash
   local keyEnd = ''
   local ret, err = client:keys(keyStart, keyEnd, limit)
   close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return ret
end

function _M:remove(hash, limit)
   local client =  open();
   local keyStart = 'piece_' .. hash
   local keyEnd = ''
   local keyArr, err = client:keys(keyStart, keyEnd, limit)
   local kCount = 0
   if keyArr then
      kCount, err = client:multi_del(unpack(keyArr))
   end
   close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return kCount, err
end

return _M