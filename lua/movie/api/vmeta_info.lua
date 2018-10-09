local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"
local util_context = require "util.context"
local ssdb_vmeta = require "ssdb.vmeta"
local ssdb_meta = require "ssdb.meta"
local ssdb_task = require "ssdb.task"
local meta_dao = require "dao.meta_dao"

local bit = require("bit") 

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local decode_base64 = ngx.decode_base64

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local toMetaId = function ( uri )
    -- /vmeta/461866823.m3u8
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/vmeta/([0-9a-zA-Z]+)\\.info','ijo')
	if m then
		return m[1]
	end
end

function doReturn( message, code )
	if code then
		message.code = code
	end
	local body = cjson_safe.encode(message)
	ngx.say(body)
end

local message = {}
message.code = 200

local uri = ngx.var.uri
local metaId = toMetaId(uri)
-- log(ERR,"uri:" ..uri..",metaId:".. cjson_safe.encode(metaId))
if not metaId then
	message.error = 'miss metaId'
	return doReturn(message, 400)
end
local vmeta, err = ssdb_vmeta:get(metaId)
if not vmeta then
	message.error = 'miss meta:' .. tostring(metaId)
	return doReturn(message, 400)
end

log(ERR,"uri:" ..uri..",vmeta:".. cjson_safe.encode(vmeta))
local oData = {}
message.data = oData
if vmeta.body or vmeta.play == "m3u8" then
   -- oData.player = 'm3u8's
   oData.url =  util_context.BASE_URI .. "/vmeta/" .. metaId ..".m3u8"
elseif vmeta.url then
	if string.match(vmeta.url, ".m3u8$")  then
		-- oData.player = 'm3u8'
		-- CDN ignore 302 to 200, miss baseURI
   		oData.url =  util_context.BASE_URI .. "/vmeta/" .. metaId ..".m3u8"
   	else
       	-- oData.player = 'link'
   		oData.url =  vmeta.url
	end
else
	log(ERR,"metaErr:" .. metaId .. ",url:" .. tostring(vmeta.url))
end
if metaId == '8648741367097258531' then
	oData.url = 'https://vjs.zencdn.net/v/oceans.mp4'
end

doReturn(message, 200)
