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
   content_id = "D_" .. content_id
   if util_table.is_table(content_val) then
   	 content_val =  cjson_safe.encode(content_val)
   end
   local client = ssdb_client:newClient();
   if not client then
      return nil, 'fail to newClient'
   end
   return client:set(content_id, content_val)
end

function _M:get(content_id)
   content_id = "D_" .. content_id
   local client = ssdb_client:newClient();
   if not client then
      return nil, 'fail to newClient'
   end
   local content_val =  client:get(content_id)
   if content_val then
      content_val = cjson_safe.decode(content_val)
   end
   return content_val
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
     keys[i] = "D_" .. keys[i]
   end

   local client = ssdb_client:newClient();
   if not client then
      return nil, 'fail to newClient'
   end
   local resp, err = client:multi_get(unpack(keys))
   if err then
       log(ERR,"multi_get,cause:",err)
   end
   if resp then
      local dest = {}
      for k,v in pairs(resp) do
           k = string.sub(k,3)
           dest[k] =  cjson_safe.decode(v)
      end
      return dest
   else
      return resp
   end
end

return _M