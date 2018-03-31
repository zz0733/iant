local cjson_safe = require "cjson.safe"
local util_table = require "util.table"
local Leveldb = require 'lualeveldb'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local LevelDBClient = new_tab(0, 6)
LevelDBClient._VERSION = '0.01'
-- The path
LevelDBClient.path = nil

function LevelDBClient:open(o)
  o = o or {}
  if o.createIfMissing == nil then
     o.createIfMissing = true
  end
  if o.errorIfExists == nil then
     o.errorIfExists = false
  end
  setmetatable(o, self)
  self.__index = self
  local error = nil
  if not o.path then
  	error = "path is nil"
  end
  if error then
  	log(ERR,"LevelDBClient:open",error)
  end
  self.db = Leveldb.open(o, o.path)
  return o, error
end

function LevelDBClient:check()
  return Leveldb:check(self.db)
end

function LevelDBClient:close()
  return Leveldb:close(self.db)
end

function LevelDBClient:put(key, val)
  return self.db.put(key, val)
end

function LevelDBClient:get(key)
  return self.db.get(key)
end

return LevelDBClient