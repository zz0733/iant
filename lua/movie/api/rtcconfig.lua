local cjson_safe = require "cjson.safe"
local ssdb_ice = require "ssdb.ice"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local iceConfig = ssdb_content:getValue()
if not iceConfig then
	local servers = {}
	table.insert(servers, {urls = "stun:stun.1und1.de"})
	iceConfig = iceConfig
end
local message = {}
message.code = 200
message.data = { iceServers = iceConfig }
ngx.say(cjson_safe.encode(message))
