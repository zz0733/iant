local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local dochtml = require "util.dochtml"
local context = require "util.context"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local to_target_id = function ( uri )
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/movie/jumper/([a-z][0-9]{3,})','ijo')
	if m then
		return m[1]
	end
end

local uri = ngx.var.uri
local target_id = to_target_id(uri)
log(ERR,"uri:" .. tostring(uri) .. ",target_id:" .. tostring(target_id))
if not target_id then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local resp = ngx.location.capture("/movie/api/link.json?id=" .. target_id)
if resp and resp.status ~= 200 then
	return ngx.exit(resp.status)
end
local return_obj = cjson_safe.decode(resp.body)
local link_doc = return_obj.data
local content_doc = {}
log(ERR,"cjson_safe:" .. cjson_safe.encode(link_doc))
content_doc.header = {
   title = "正在前往百度云"
}
content_doc.version = context.version()
content_doc.link_doc  = cjson_safe.encode(link_doc)

template.render("jumper.html", content_doc)