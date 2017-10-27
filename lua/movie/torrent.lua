local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local dochtml = require "util.dochtml"
local context = require "util.context"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"
local channel_dao = require "dao.channel_dao"
local util_string = require "util.string"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local to_target_id = function ( uri )
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/movie/torrent/([a-z]?[0-9]{3,})','ijo')
	if m then
		return m[1]
	end
end
local uri = ngx.var.uri
local uri = ngx.var.uri
local target_id = to_target_id(uri)
log(ERR,"uri:" .. tostring(uri) .. ",target_id:" .. tostring(target_id))
if not target_id then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local resp = ngx.location.capture("/api/movie//link.json?id=" .. target_id)
if resp and resp.status ~= 200 then
	return ngx.exit(resp.status)
end
local return_obj = cjson_safe.decode(resp.body)
local link_doc = return_obj.data

-- log(ERR,"cjson_safe:" .. cjson_safe.encode(link_doc))
-- link_doc.secret = 'secret21e'
local content_doc = {}
content_doc.header = {
   title = '免费下载:' .. link_doc.title .. ",为你所用才是资讯"
}
context.withGlobal(content_doc)
content_doc.link_doc  = link_doc
content_doc.config  = {
	jiathis_uid = context.jiathis_uid,
	weibo_uid = context.weibo_uid,
	weibo_app_key = context.weibo_app_key
}
if string.match(uri,"^/m/") then
	template.render("mobile/torrent.html", content_doc)
else
	template.render("torrent.html", content_doc)
end
