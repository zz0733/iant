local wxcrypt = require "util.wxcrypt"
local util_request = require "util.request"
local cjson_safe = require "cjson.safe"

local log = ngx.log
local ERR = ngx.ERR

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

if req_method == "POST" then
	local post_body = util_request.post_body(ngx.req)
	log(ERR,"post_body:",post_body)
	wxcrypt.encrypt(post_body)
elseif req_method == "GET" then
	local echostr = args.echostr;
	local dest = wxcrypt.decrypt(echostr)
	dest = dest or ""
	log(ERR,"echostr:",echostr .. ",decrypt:" .. tostring(dest))
	ngx.say(dest)
end


