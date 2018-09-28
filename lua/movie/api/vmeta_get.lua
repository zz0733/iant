local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"
local util_context = require "util.context"
local ssdb_vmeta = require "ssdb.vmeta"
local ssdb_meta = require "ssdb.meta"
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
	local m = ngx.re.match(uri, '/vmeta/([0-9a-zA-Z]+)\\.m3u8','ijo')
	if m then
		return m[1]
	end
end
local uri = ngx.var.uri
local metaId = toMetaId(uri)
-- log(ERR,"uri:" ..uri..",metaId:".. cjson_safe.encode(metaId))
if not metaId then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
if "1252287066" == metaId then
	return ngx.redirect("https://video.fjhps.com/20180531/HbXbMD0i/index.m3u8", ngx.HTTP_MOVED_TEMPORARILY)
end
local vmeta, err = ssdb_vmeta:get(metaId)
if not vmeta then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
if vmeta.url then
	return ngx.redirect(vmeta.url, ngx.HTTP_MOVED_TEMPORARILY)
end
-- if not vmeta.body and vmeta.url then
-- 	vmeta.body = "#EXTM3U\n#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1080x608\n" .. vmeta.url
-- end
if string.match(vmeta.body, "/odflv/api.php") or string.match(vmeta.body, "/404.mp4") then
	local hasMeta = ssdb_meta:get(metaId)
    hasMeta.id = metaId
    hasMeta.cstatus = bit.bxor(hasMeta.cstatus or 0, 2)
    hasMeta.pstatus = 0
    local modifyArr = {}
	table.insert(modifyArr, hasMeta)
	meta_dao:save_metas( modifyArr )
elseif string.match(vmeta.body, "#EXT%-X%-STREAM%-INF:PROGRAM%-ID=1,BANDWIDTH=") then
	local vmetaURL = string.match(vmeta.body,"(http.+)[\n]")
	if vmetaURL then
		return ngx.redirect(vmetaURL, ngx.HTTP_MOVED_TEMPORARILY) 
	end
end
-- log(ERR,"vmeta:" .. cjson_safe.encode(vmeta))
ngx.say(vmeta.body)
