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

local fields = {
    "evaluates", "digests", "contents", "actors", "extends"
}

_M._ONGLYS = {}
for i = 1, #fields do
    local cmd = fields[i]
    _M._ONGLYS[cmd] = 1
end

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
      local ok, err = client:close()
      if not err then
         log(ERR,"failed to close client:", err)
      end
   end
end

function toSSDBKey( key )
  return "D_" .. key
end

function toJSONBean( sVal )
   if not sVal then
      return nil
   end
   local jsonVal =  cjson_safe.decode(sVal)
   if jsonVal and jsonVal.digests then
      local digests = jsonVal.digests
      for _,dv in ipairs(digests) do
         -- dv.content = '/img/a9130b4f2d5e7acd.jpg'
         if dv.sort == 'img' and string.match(dv.content,"^/img/") then
            dv.content = util_context.CDN_URI .. dv.content
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
   local client =  open();
   local ret, err = client:set(toSSDBKey(content_id), content_val)
   close(client)
   return ret, err
end

function _M:get(content_id)
   local client =  open();
   local ret, err = client:get(toSSDBKey(content_id))
   close(client)
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return toJSONBean(ret)
end



function _M:update(content_id, content)
   local has_content_val = self:get(content_id)
   local save_content = content
   if not has_content_val then
      save_content = has_content_val
      for k,v in pairs(content) do
         save_content[k] = v
      end
   end
   return self:set(content_id, save_content)
end

function _M:multi_get(keys)
   if not keys then
      return {}
   end
   for i = 1, #keys do
     keys[i] =  toSSDBKey(keys[i]) 
   end
   local client = open();
   local ret, err = client:multi_get(unpack(keys))
   if ret then
      local dest = {}
      for k,v in pairs(ret) do
           k = string.sub(k,3)
           dest[k] =  toJSONBean(v)
      end
      return dest
   else
      return ret, err
   end
end



return _M