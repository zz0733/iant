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


function _M:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  local error = nil
  if not self.client then
    -- the execute client
    self.client = ssdb_client.newClient()
  end
  if error then
    log(ERR,"new ssdb client,cause:",error)
  end
  return o, error
end

function toSSDBKey( key )
  return "IDF_" .. key
end

function _M:setValue(key, val)
   local ret, err = self.client:set(toSSDBKey(key), val)
   return ret, err
end

function _M:getValue(key)
   local ret, err = self.client:get(toSSDBKey(key))
   if err then
      return nil, err
   end
   if ret == ngx.null then
     return nil
   end
   return tonumber(ret)
end

return _M