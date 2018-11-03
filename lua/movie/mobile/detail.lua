local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_dochtml = require "util.dochtml"
local util_context = require "util.context"
local util_string = require "util.string"
local util_const = require "util.const"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"
local channel_dao = require "dao.channel_dao"


local ssdb_meta = require "ssdb.meta"

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

-- local has_content = ssdb_content:get(content_id)
local has_content = ssdb_meta:get(content_id)
if not has_content then
	log(ERR,"uri:" .. tostring(uri) .. ",content_id:" .. tostring(content_id) .. ",miss:" .. cjson_safe.encode(has_content))
	if has_content == false then
		 -- 500 error
		return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
	else
		return ngx.exit(ngx.HTTP_NOT_FOUND)
	end
end

-- local ids = {}
-- table.insert(ids,"hotest")
-- local resp,status = channel_dao:query_by_ids(ids)
-- -- log(ERR,"query_by_ids:" .. cjson_safe.encode(resp) )
-- local recmd_map = {}
-- if resp and resp.hits.hits[1] then
-- 	local channel_doc = resp.hits.hits[1]
-- 	local max_count = 10
-- 	local count = 0
-- 	local elements = channel_doc._source.elements
-- 	if elements and #elements > 0 then
-- 		local add_count = max_count - count
-- 		local max_index = math.min(100,#elements)
-- 		add_count = math.min(add_count,#elements)
-- 		while add_count > 0 do
-- 			local index = math.random(1, max_index)
-- 			local ele = elements[index]
-- 			if not recmd_map[ele.code] then
-- 				recmd_map[ele.code] = ele
-- 				count = count + 1
-- 				add_count = add_count - 1
-- 			end
-- 		end

-- 	end
-- end

function titleWithEpIndex(title, epindex )
   if epindex and epindex > 0 then
    if not string.contains(title,  "" .. epindex ) then 
      title = title .. " " .. epindex .."集"
    end
   end
   return title
end

has_content.title = titleWithEpIndex(has_content.title, has_content.epindex)

-- log(ERR,"recmd_map:" .. cjson_safe.encode(recmd_map) )
local crumbs = {}
if not has_content.sort then
   has_content.sort = 0
   if string.len(content_id) > 16 then
   	  has_content.sort =1
   end
end
local sortName = util_const.index2Name("SORT_DICT", has_content.sort)
has_content.sortName = sortName
local year = has_content.year or 0
local regions = has_content.regions
table.insert(crumbs , {name = sortName, link1 = "/media/" .. sortName  ..".html"})
if regions and regions[1] then
	local region = regions[1]
	table.insert(crumbs , {name = region, link = "/movie/region/" .. region  ..".html"})
end
table.insert(crumbs , {name = tostring(year), link1 = "/movie/year/" .. tostring(year)  ..".html"})

has_content.header = util_dochtml.detail_header(has_content)
has_content.header.canonical = "http://www.lezomao.com/m/movie/detail/"..tostring(content_id) .. ".html"
util_context.withGlobal(has_content)
has_content.crumbs   = crumbs
-- has_content.recmd_map  = recmd_map
has_content.config  = {
	jiathis_uid = util_context.jiathis_uid,
	weibo_uid = util_context.weibo_uid,
	weibo_app_key = util_context.weibo_app_key
}

template.render("mobile/detail.html", has_content)