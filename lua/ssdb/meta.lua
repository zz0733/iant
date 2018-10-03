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


local ES_FIELDS = {
    "id", "albumId", "title", "media","sort",
    "lang", "source", "cost", "space","year",
    "epindex","cstatus","pstatus","vip",
    "issueds","regions","genres",
    "names","directors","actors",
    "ctime","utime","epmax_time"
}

-- local SSDB_FIELDS = {}
-- table.insert(SSDB_FIELDS, "douban")
-- table.insert(SSDB_FIELDS, "digests")
-- for _,iv in ipairs(ES_FIELDS) do
--   table.insert(SSDB_FIELDS, v)
-- end

-- local fields = {
--     "digests", "url", "html", "fill","douban"
-- }


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
  return "M_" .. tostring(key)
end

function _M:toMetaBean( sVal )
   if not sVal then
      return nil
   end
   local jsonVal =  cjson_safe.decode(sVal)
   if jsonVal and not util_table.is_table(jsonVal) then
      jsonVal = nil
   end
   if jsonVal and jsonVal.digests then
      local digests = jsonVal.digests
      for index,imgURL in ipairs(digests) do
         -- dv.content = '/img/a9130b4f2d5e7acd.jpg'
         if util_table.is_table(imgURL) then
            log(ERR,"table imgURL:" .. cjson_safe.encode(imgURL) .. ",sVal:" .. sVal)
            jsonVal = nil
         else
           if string.match(imgURL,"^/img/") then
              digests[index] = util_context.CDN_URI .. imgURL
           end
         end
      end
   end
   return jsonVal
end

function _M:makeESDoc(inDoc, rmField)
   local indexDoc = {}
   for i,v in ipairs(ES_FIELDS) do
       indexDoc[v] = inDoc[v]
       if rmField then
          inDoc[v] = nil
       end
   end
   return indexDoc
end

function _M:set(content_id, content_val)
   if util_table.is_table(content_val) then
      local digests = content_val.digests
      for index,imgURL in ipairs(digests) do
         if not util_table.is_table(imgURL) then
           digests[index] = ngx.re.sub(imgURL, util_context.CDN_URI, "")
         end
      end
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
   return self:toMetaBean(ret)
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
           k = string.sub(k,3)
           dest[k] =  self:toMetaBean(v)
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

return _M