local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local dochtml = require "util.dochtml"
local context = require "util.context"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"
local channel_dao = require "dao.channel_dao"

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

local ids = {}
ids[1] = content_id
local resp, status = content_dao:query_by_ids(ids)
if not resp or resp.hits.total < 1 then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local content_doc = resp.hits.hits[1]
local source = content_doc._source
local lcount = source.lcount or 0
local  from = 0
local  size = 10
local  fields = {"title","space","ctime","issueds"}
local resp
if lcount > 0 then
	resp  = link_dao:query_by_target(content_doc._id, from, size, fields)
else
	resp  = link_dao:query_by_titles(source.names, from, size, fields)
end
local link_hits = {}
if resp and resp.hits then
	link_hits = resp.hits
end
-- log(ERR,"link_hits:" .. cjson_safe.encode(link_hits) ..",lcount:" .. lcount)

local ids = {"hottest"}
local resp = channel_dao:query_by_ids(ids)
local recmd_map = {}
if resp then
	local channel_hist = resp.hits.hits
	local max_count = 10
	local count = 0
	for i,v in ipairs(channel_hist) do
		local elements = v._source.elements
		if elements and #elements > 0 then
			local add_count = max_count - count
			local max_index = math.min(100,#elements)
			add_count = math.min(add_count,#elements)
			while add_count > 0 do
				local index = math.random(1, max_index)
				local ele = elements[index]
				if not recmd_map[ele.id] then
					recmd_map[ele.id] = ele
					count = count + 1
					add_count = add_count - 1
				end
			end

		end
		
		for i=1,max_count do
			
		end
	end
end


local crumbs = {}
local issueds = source.issueds[1]

log(ERR,"link_hits:" .. cjson_safe.encode(source.issueds) ..",lcount:" .. lcount)

local media_names = { 
   tv = "电视剧",
   movie = "电影"
}
local media = source.article.media
local year = source.article.year
crumbs[#crumbs + 1] = {name = media_names[media], link1 = "/media/" .. media}
if issueds then
	crumbs[#crumbs + 1] = {name = issueds.region, link1 = "/region/" .. issueds.region }
end
crumbs[#crumbs + 1] = {name = year, link1 = "/year/" .. tostring(year)}
content_doc.header = dochtml.detail_header(content_doc)
content_doc.version = context.version()
content_doc.crumbs   = crumbs
content_doc.link_hits  = link_hits
content_doc.recmd_map  = recmd_map

template.render("detail.html", content_doc)

