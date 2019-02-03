local cjson_safe = require "cjson.safe"
local util_table = require "app.libs.util.table"
local ssdb_client = require "app.libs.ssdb.client"



local _M = {}
_M._VERSION = '0.02'

local KEY_PREFIX = "ver_"
local KEY_PREFIX_LEN = string.len(KEY_PREFIX)

function _M:toSSDBKey( key )
  return KEY_PREFIX .. tostring(key)
end

function _M:toVersionBean( sVal )
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
   local client =  ssdb_client:open();
   local ret, err = client:set(self:toSSDBKey(content_id), content_val)
   ssdb_client:close(client)
   return ret, err
end

function _M:get(content_id)
   local client =  ssdb_client:open();
   local ret, err = client:get(self:toSSDBKey(content_id))
   ssdb_client:close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return self:toVersionBean(ret)
end

function _M:multi_get(keys)
   if not keys then
      return {}
   end
   for i = 1, #keys do
     keys[i] =  self:toSSDBKey(keys[i]) 
   end
   local client = ssdb_client:open();
   local ret, err = client:multi_get(unpack(keys))
   ssdb_client:close(client)
   if ret then
      local dest = {}
      for k,v in pairs(ret) do
           k = string.sub(k,KEY_PREFIX_LEN + 1)
           dest[k] =  self:toVersionBean(v)
      end
      return dest
   else
      return ret, err
   end
end

return _M