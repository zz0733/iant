local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ssdb_task = require "ssdb.task"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

-- local args = ngx.req.get_uri_args()
-- local resp = ngx.location.capture(
--                 "/api/task.json", { args={method = "getmore" }}
-- )
-- ngx.say(resp.body)

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local client = args.client
local max = 5
local message = {}
message.code = 200
local assignArr, err = ssdb_task:qpop(max)
if err then
	message.error = err
    message.code = 500
else
	local count = #assignArr
	log(ERR,"assign:" .. tostring(client) .. ",count:" .. count)
	message.data = assignArr
end
local body = cjson_safe.encode(message)
ngx.say(body)