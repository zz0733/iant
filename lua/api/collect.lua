local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local collect_dao = require "dao.collect_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local exptime = 600

local shared_dict = ngx.shared.shared_dict

local message = {}
message.code = 200
if not method then
	message.status = 400
	message.message = "empty method"
	ngx.say(cjson_safe.encode(message))
	return
end
local data = util_request.post_body(ngx.req)
local body_json = cjson_safe.decode(data)
if not body_json then
	message.code = 400
	message.error = "illegal params"
	ngx.say(cjson_safe.encode(message))
	return
end
if 'insert' == method  then
	local resp, status = collect_dao.inserts(body_json )
    -- message.data = resp
    if status == 200 then
    	message.code = 200
    else
    	message.code = 500
    	message.error = status
    end
    ngx.say(cjson_safe.encode(message))
end
