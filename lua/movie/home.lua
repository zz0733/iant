local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"
local util_string = require "util.string"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local channel_dao = require "dao.channel_dao"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

function buildHeader( )
	local header = {}
	header.canonical = "http://www.lezomao.com/"
	header.keywords = "狸猫资讯,为你所用,迅雷下载,种子下载,免费下载"
	header.description = "《狸猫资讯》(LezoMao.com)是一款智能的资讯软件,它会对信息加工提炼，为你推荐有价值的内容，让你更好更快获取资讯。为你所用，才是资讯！"
	header.title = "《狸猫资讯》为你所用，才是资讯！- LezoMao.com"
	return header;
end

function selectContents( hits )
	local contents = {}
	if not hits then
		contents.hits = {}
		contents.total = 0
		return contents
	end
	function comp( left, right )
		if not left.index then
			return true
		end
		if not right.index then
			return false
		end
		return left.index < right.index
	end
	local select_ids = {}
	local max_select = 30
	for _,hv in ipairs(hits) do
		local elements = hv._source.elements
		if elements then
			table.sort(elements, comp)
			log(ERR,"sort.elements:" .. cjson_safe.encode(elements) )
			for _,v in ipairs(elements) do
				if v.code then
					table.insert(select_ids, v.code)
					if #select_ids >= max_select then
						break
					end
				end
			end
		end
	end
	local  fields = {"article","digests","lcount","issueds","evaluates","genres"}
	local resp =  content_dao:query_by_ids(select_ids,fields);
	if resp then
		contents = resp.hits
	end
	return contents
end
function buildSearchWord( hits )
	if not hits or #hits < 1 then
		return
	end
	local channel_index = math.random(1, #hits)
	if hits[channel_index] and hits[channel_index]._source.elements then
		local channle_doc = hits[channel_index]
		local elements = channle_doc._source.elements
		if elements and #elements > 0 then
			local index = math.random(1, #elements)
			local content_obj = elements[index]
			return content_obj.title
		end
	end
end
local channel_ids = {"hotest"}
local resp = channel_dao:query_by_ids(channel_ids)
local contents = selectContents(resp.hits.hits)

local movie_ids = {"movie;douban;recommend;201705;热门"}
resp = channel_dao:query_by_ids(movie_ids)
local playing_movie = selectContents(resp.hits.hits)
log(ERR,"playing_movie.elements:" .. cjson_safe.encode(resp) )
local content_doc = {}
content_doc.header = buildHeader()
content_doc.version = context.version()
content_doc.hits  = contents
content_doc.playing_movie = playing_movie
content_doc.qWord  = buildSearchWord(resp.hits.hits)

template.render("home.html", content_doc)