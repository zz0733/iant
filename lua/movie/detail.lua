local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local dochtml = require "util.dochtml"
local context = require "util.context"
local util_const = require "util.const"
local ssdb_content = require "ssdb.content"
local ssdb_meta = require "ssdb.meta"

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
-- if not content_id then
if util_table.isNull(content_id) then
	log(ERR,"uriErr:" .. tostring(uri) .. ",missId")
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

-- local has_content = ssdb_content:get(content_id)
local has_content = ssdb_meta:get(content_id)
if util_table.isNull(has_content) then
	log(ERR,"uriErr:" .. tostring(uri) .. ",content_id:" .. tostring(content_id) .. ",miss:" .. cjson_safe.encode(has_content))
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

    -- oDoc.id = ""
    -- oDoc.albumId = ""
    -- oDoc.title = ""
    -- oDoc.media = 0
    -- oDoc.sort = 0
    -- oDoc.lang = 0
    -- oDoc.source = 0
    -- oDoc.cost = 0
    -- oDoc.space = 0
    -- oDoc.year = 0
    -- oDoc.imdb = 0
    -- oDoc.season = 0
    -- oDoc.episode = 0
    -- oDoc.epcount = 0
    -- oDoc.epindex = 0
    -- oDoc.cstatus = 0
    -- oDoc.pstatus = 0
    -- oDoc.vip = 0
    -- oDoc.issueds = []
    -- oDoc.regions = []
    -- oDoc.countrys = []
    -- oDoc.genres = []
    -- oDoc.names = []
    -- oDoc.directors = []
    -- oDoc.actors = []

    -- // not index
    -- oDoc.digests = []
    -- oDoc.url = ""
    -- oDoc.html = ""
    -- oDoc.fill = {}

local content_doc = { ["_id"] = content_id }
content_doc._source = has_content
local source = content_doc._source
-- log(ERR,"source:" .. cjson_safe.encode(source) )
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

if not has_content.sort then
   has_content.sort = 0
   if string.len(content_id) > 16 then
   	  has_content.sort =1
   end
end
local sortName = util_const.index2Name("SORT_DICT",has_content.sort)
has_content.sortName = sortName
local year = has_content.year
local regions = has_content.regions
table.insert(crumbs , {name = sortName, link1 = "/media/" .. sortName  ..".html"})
if regions and regions[1] then
	local region = regions[1]
	table.insert(crumbs , {name = region, link = "/movie/region/" .. region  ..".html"})
end
table.insert(crumbs , {name = year, link1 = "/movie/year/" .. tostring(year)  ..".html"})
has_content.header = dochtml.detail_header(has_content)
context.withGlobal(has_content)
has_content.crumbs   = crumbs
-- content_doc.link_hits  = link_hits
has_content.recmd_map  = recmd_map
has_content.config  = {
	jiathis_uid = context.jiathis_uid,
	weibo_uid = context.weibo_uid,
	weibo_app_key = context.weibo_app_key
}
-- log(ERR,"has_content:" .. cjson_safe.encode(has_content))
template.render("detail.html", has_content)