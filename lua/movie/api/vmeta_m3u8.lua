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
local vmeta, err = ssdb_vmeta:get(metaId)
if not vmeta then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

if vmeta.url then
	if string.match(vmeta.url, "blog.zhaiyou.tv") then
		 local newTask = {}
	     newTask.type = "zhaiyou-video-cache"
	     newTask.url = vmeta.url
	     newTask.level = 2
	     local params = {}
	     params.metaId = metaId
	     newTask.params = params
	     local tresp, tstatus = ssdb_task:qretry( newTask.level, newTask )
	     log(ERR,"vmetaTask:" .. cjson_safe.encode(newTask) .. ",resp:" .. cjson_safe.encode(tresp) .. ",status:" .. cjson_safe.encode(tstatus) )
	elseif string.match(vmeta.url, "031a17b699fdebe7a68637c0d0ba1790.mp4") and metaId ~= '546985812' then
		-- fix zhaiyou-video-cache bug's data
		local hasMeta = ssdb_meta:get(metaId)
	    local newTask = {}
	     newTask.type = "odflv-video-cache"
	     newTask.url = hasMeta.url
	     newTask.level = 2
	     local params = {}
	     params.metaId = metaId
	     newTask.params = params
	     local tresp, tstatus = ssdb_task:qretry( newTask.level, newTask )
	     log(ERR,"vmetaTask:" .. cjson_safe.encode(newTask) .. ",resp:" .. cjson_safe.encode(tresp) .. ",status:" .. cjson_safe.encode(tstatus) )
	end
	return ngx.redirect(vmeta.url, ngx.HTTP_MOVED_TEMPORARILY)
end
-- if not vmeta.body and vmeta.url then
-- 	vmeta.body = "#EXTM3U\n#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1080x608\n" .. vmeta.url
-- end

-- end of response,and do something backend
if string.match(vmeta.body, "/odflv/api.php") or string.match(vmeta.body, "/404.mp4") then
	local hasMeta = ssdb_meta:get(metaId)
    hasMeta.id = metaId
    hasMeta.cstatus = bit.bxor(hasMeta.cstatus or 0, 2)
    hasMeta.pstatus = 0
    local modifyArr = {}
	table.insert(modifyArr, hasMeta)
	meta_dao:save_metas( modifyArr )
elseif string.match(vmeta.body, "#EXT%-X%-STREAM%-INF:PROGRAM%-ID=1,BANDWIDTH=") then
	local vmetaURL = string.match(vmeta.body,"http[^\n%s]+")
	if vmetaURL then
		return ngx.redirect(vmetaURL, ngx.HTTP_MOVED_TEMPORARILY) 
	end
end
-- log(ERR,"vmeta:" .. cjson_safe.encode(vmeta))
ngx.say(vmeta.body)