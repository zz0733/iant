local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local dochtml = require "util.dochtml"
local context = require "util.context"
local ssdb_content = require "ssdb.content"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"
local channel_dao = require "dao.channel_dao"
local util_string = require "util.string"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local to_content_id = function ( uri )
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/movie/detail/([0-9]{3,})','ijo')
	if m then
		return m[1]
	end
end

local uri = ngx.var.uri
local content_id = to_content_id(uri)
-- log(ERR,"uri:" .. tostring(uri) .. ",content_id:" .. tostring(content_id))
if not content_id then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local content_val = ssdb_content:get(content_id)
if not content_val then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local content_doc = { ["_id"] = content_id}
content_doc._source = content_val
local source = content_doc._source

local ids = {}
table.insert(ids,"hotest")
local resp,status = channel_dao:query_by_ids(ids)
-- log(ERR,"query_by_ids:" .. cjson_safe.encode(resp) )
local recmd_map = {}
if resp and resp.hits.hits[1] then
	local channel_doc = resp.hits.hits[1]
	local max_count = 10
	local count = 0
	local elements = channel_doc._source.elements
	if elements and #elements > 0 then
		local add_count = max_count - count
		local max_index = math.min(100,#elements)
		add_count = math.min(add_count,#elements)
		while add_count > 0 do
			local index = math.random(1, max_index)
			local ele = elements[index]
			if not recmd_map[ele.code] then
				recmd_map[ele.code] = ele
				count = count + 1
				add_count = add_count - 1
			end
		end

	end
end

-- log(ERR,"recmd_map:" .. cjson_safe.encode(recmd_map) )

local crumbs = {}
local issueds = source.issueds[1]

local media_names = { 
   tv = "电视剧",
   movie = "电影"
}
local media = source.article.media
local year = source.article.year
crumbs[#crumbs + 1] = {name = media_names[media], link1 = "/media/" .. media  ..".html"}
if issueds then
	crumbs[#crumbs + 1] = {name = issueds.region, link = "/movie/region/" .. issueds.region  ..".html"}
end
crumbs[#crumbs + 1] = {name = year, link1 = "/movie/year/" .. tostring(year)  ..".html"}
content_doc.header = dochtml.detail_header(content_doc)
context.withGlobal(content_doc)
content_doc.crumbs   = crumbs
-- content_doc.link_hits  = link_hits
content_doc.recmd_map  = recmd_map
content_doc.config  = {
	jiathis_uid = context.jiathis_uid,
	weibo_uid = context.weibo_uid,
	weibo_app_key = context.weibo_app_key
}
template.render("detail.html", content_doc)