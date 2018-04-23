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
   if not ok then
      log(ERR,"failed to set keepalive: ", err)
   end
end

function toSSDBKey( key )
  return "IDF_" .. key
end

function _M:setValue(key, val)
   local client =  open();
   local ret, err = client:set(toSSDBKey(key), val)
   close(client)
   return ret, err
end

function _M:getValue(key)
   local client =  open();
   local ret, err = client:get(toSSDBKey(key))
   close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return tonumber(ret)
end

return _M