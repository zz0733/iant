local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local ssdb_task = require "ssdb.task"

-- local args = ngx.req.get_uri_args()
-- local resp = ngx.location.capture(
--                 "/api/task.json", { args={method = "getmore" }}
-- )
-- ngx.say(resp.body)

local max = 5
local message = {}
message.code = 200
local assignArr, err = ssdb_task:qpop(max)
if err then
	message.error = err
    message.code = 500
else
	message.data = assignArr
end
local body = cjson_safe.encode(message)
ngx.say(body)