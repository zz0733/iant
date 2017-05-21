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
	local m = ngx.re.match(uri, '/movie/target/([a-z][0-9]{3,})','ijo')
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

local ids = {}
ids[1] = target_id
local fields = {"title","link"}
local resp, status = link_dao:query_by_ids(ids, fields)

if not resp or resp.hits.total < 1 then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local link_doc = resp.hits.hits[1]
link_doc.header = {}

   -- header.canonical = "http://www.lezomao.com/"..tostring(media).."/detail/"..tostring(id) .. ".html"
   -- header.keywords = keywords
   -- header.description = description
   -- header.title = head_title
template.render("target.html", link_doc)