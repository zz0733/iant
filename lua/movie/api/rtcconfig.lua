local cjson_safe = require "cjson.safe"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local servers = {}
-- table.insert(servers, {urls = "stun:stun.1und1.de"})
-- table.insert(servers, {urls = "stun:stun.voiparound.com"})
-- table.insert(servers, {urls = "stun:stun.xten.com"})
table.insert(servers, {urls = "stun:stun.aa.net.uk:3479?transport=udp"})
-- table.insert(servers, {urls = "stun:stun4.l.google.com:19302"})
-- table.insert(servers, {urls = "stun:global.stun.twilio.com:3478?transport=udp"})
local message = {}
message.code = 200
message.data = { iceServers = servers }
ngx.say(cjson_safe.encode(message))
