-- local args = ngx.req.get_uri_args()
-- local cjson_safe = require "cjson.safe"
-- local resp = ngx.location.capture(
--                 "/api/script.json", {args={method = "get", type = args.type }}
-- )

local cjson_safe = require "cjson.safe"
local util_table = require "util.table"
local script_dao = require "dao.script_dao"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local args = ngx.req.get_uri_args()

local value, err = script_dao:search_by_type( args.type)
local message = {}
if err then
    message.code = 500
    message.error = err
else
    message.data = cjson_safe.encode(value)
    message.code = 200
end
local body = cjson_safe.encode(message)
ngx.say(body)
