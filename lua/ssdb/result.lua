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
_M._VERSION = '0.02'

local KEY_PREFIX = "R_"
local ORIGIN_KEY_START = string.len(KEY_PREFIX)  + 1

function _M:open( )
   local client,err = ssdb_client:newClient();
   if err then
      return nil, err
   end
   return client
end
function _M:close( client )
   if not client then
      return
   end
   local ok, err = client:set_keepalive(0, 20)
   if err then
      log(ERR,"failed to set keepalive:", err)
   end
end

function _M:toSSDBKey( key )
  return KEY_PREFIX .. tostring(key)
end

function _M:toBean( sVal )
   if not sVal then
      return nil
   end
   local jsonVal =  cjson_safe.decode(sVal)
   if jsonVal and not util_table.is_table(jsonVal) then
      jsonVal = nil
   end
   return jsonVal
end


function _M:set(content_id, content_val)
   if util_table.is_table(content_val) then
   	 content_val =  cjson_safe.encode(content_val)
   end
   local client =  self:open();
   local ret, err = client:set(self:toSSDBKey(content_id), content_val)
   self:close(client)
   return ret, err
end

function _M:get(content_id)
   local client =  self:open();
   local ret, err = client:get(self:toSSDBKey(content_id))
   self:close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return self:toBean(ret)
end

function _M:multi_get(keys)
   if not keys then
      return {}
   end
   for i = 1, #keys do
     keys[i] =  self:toSSDBKey(keys[i]) 
   end
   local client = self:open();
   local ret, err = client:multi_get(unpack(keys))
   self:close(client)
   if ret then
      local dest = {}
      for k,v in pairs(ret) do
           k = string.sub(k, ORIGIN_KEY_START)
           dest[k] =  self:toBean(v)
      end
      return dest
   else
      return ret, err
   end
end

function _M:remove(content_id)
   local client =  self:open();
   local ret, err = client:del(self:toSSDBKey(content_id))
   self:close(client)
   return ret, err 
end

function _M:multi_del(keys)
   if not keys then
      return {}
   end
   for i = 1, #keys do
     keys[i] =  self:toSSDBKey(keys[i]) 
   end
   local client = self:open();
   local ret, err = client:multi_del(unpack(keys))
   self:close(client)
   return ret, err
end

function _M:keys(size)
   local startKey = KEY_PREFIX
   local endKey = KEY_PREFIX .. "}"
   size = size or 10
   local client =  self:open();
   local ret, err = client:keys(startKey,endKey, size)
   self:close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   if ret then
      for ikey,vkey in ipairs(ret) do
        vkey = string.sub(vkey, ORIGIN_KEY_START)
        ret[ikey] = vkey
      end
   end
   return ret, err
end

return _M