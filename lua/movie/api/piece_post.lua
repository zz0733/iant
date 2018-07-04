local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"
local util_context = require "util.context"
local ssdb_piece = require "ssdb.piece"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local decode_base64 = ngx.decode_base64

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local post_body = util_request.post_body(ngx.req)
-- log(ERR,"params:" ..tostring(post_body))
local message = {}
message.code = 200
if  post_body then
	local params = cjson_safe.decode(post_body)
	if params and params.infoHash and params.data then
	   local start = params.start or 0 
       local ret, err = ssdb_piece:setValue(params.infoHash, start, params.data)
       if err then
       	  message.code = 500
       	  message.error = err
       end
	else
	   message.error = "error params,must have:infoHash,piece"
	   message.code = 400
	end
else
	message.error = "error post params"
	message.code = 400
end
local body = cjson_safe.encode(message)
ngx.say(body)