local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"
local util_context = require "util.context"
local ssdb_vmeta = require "ssdb.vmeta"

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
	local m = ngx.re.match(uri, '/vmeta/([0-9a-zA-Z]+)\\.m3u8','ijo')
	if m then
		return m[1]
	end
end
local uri = ngx.var.uri
local metaId = toMetaId(uri)
log(ERR,"uri:" ..uri..",metaId:".. cjson_safe.encode(metaId))
if not metaId then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
local vmeta, err = ssdb_vmeta:get(metaId)
if not vmeta then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
-- log(ERR,"vmeta:" .. cjson_safe.encode(vmeta))
ngx.say(vmeta.body)
-- ngx.say("#EXTM3U\n#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1080x608\nhttps://video.fjhps.com/20180501/XMOKD4BQ/index.m3u8")