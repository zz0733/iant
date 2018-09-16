local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_movie = require "util.movie"
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

local fields = {
}


_M._ONGLYS = {}
for i = 1, #fields do
    local cmd = fields[i]
    _M._ONGLYS[cmd] = 1
end

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
  return "VM_" .. tostring(key)
end

function _M:toVMetaBean( sVal )
   if not sVal then
      return nil
   end
   local jsonVal =  cjson_safe.decode(sVal)
   if jsonVal and not util_table.is_table(jsonVal) then
      jsonVal = nil
   end
   if jsonVal and jsonVal.body and jsonVal.prefixs then
      local digests = jsonVal.digests
      for index, prefix in ipairs(jsonVal.prefixs) do 
         local sCode =  util_movie.toUnsignHashCode(prefix)
         jsonVal.body = ngx.re.gsub(jsonVal.body, "@" .. sCode .. "@", prefix)
         if not string.match(jsonVal.body,"%.ts%?") then
            jsonVal.body = ngx.re.sub(jsonVal.body, "#EXT-X-TARGETDURATION:10", "#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1080x608")
         end
      end
   end
   return jsonVal
end

function _M:hasOnlyFields(fields)
   if not fields then
      -- all fields
      return true
   end
   for i = 1, #fields do
     local fld = fields[i]
     if _M._ONGLYS[fld] then
        return true
     end
   end
   return false
end

function _M:removeOnlyFields(content_val)
   for k,v in pairs(_M._ONGLYS) do
      content_val[k] = nil
   end
   return content_val
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
   return self:toVMetaBean(ret)
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
   if ret then
      local dest = {}
      for k,v in pairs(ret) do
           k = string.sub(k,3)
           dest[k] =  self:toVMetaBean(v)
      end
      return dest
   else
      return ret, err
   end
end



return _M