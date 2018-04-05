local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"

local LevelDBClient = require "db.LevelDBClient"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local db_path = util_context.DB_ROOT_DIR or ""
local _M = LevelDBClient:new({createIfMissing = true, errorIfExists = false, path = db_path .. "content.db"})
_M._VERSION = '0.01'

return _M