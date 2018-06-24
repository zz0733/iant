local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local post_body = util_request.post_body(ngx.req)
log(ERR,"args:" ..tostring(cjson_safe.encode(args)))
log(ERR,"params:" ..tostring(cjson_safe.encode(post_body)))