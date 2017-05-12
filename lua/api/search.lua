local cjson_safe = require "cjson.safe"
local util_request = require "util.request"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local client_utils = require("util.client_utils")
local client = client_utils.client()

local post_body = util_request.post_body(ngx.req)
-- log(ERR,"params:" ..tostring(post_body))
local message = {}
message.code = 200
if  post_body then
	local params = cjson_safe.decode(post_body)
	if params then
		local resp, status = client:search{
		  index = params.index,
		  type = params.type,
		  body = params.body
		}
		message.data = resp
		if not resp then
		    message.code = 500
		    message.error = status
		end
	else
	   message.error = "playload must be a json"
	   message.code = 400
	end
else
	message.error = "illegal playload"
	message.code = 400
end
local body = cjson_safe.encode(message)
ngx.say(body)