local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"
local util_string = require "util.string"
local util_time = require "util.time"

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

function selectCodes( hits, max )
	if not hits then
		return nil
	end
	function comp( left, right )
		local lnum = left.index or left.ticket_rate_tf or 0
		local rnum = right.index or right.ticket_rate_tf or 0
		return lnum < rnum
	end
	local select_ids = {}
	local max_select = max or 30
	for _,hv in ipairs(hits) do
		local elements = hv._source.elements
		if elements then
			table.sort(elements, comp)
			-- log(ERR,"sort.elements:" .. cjson_safe.encode(elements) )
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
	return select_ids
end
function buildSearchWord( hits )
	if not hits or #hits < 1 then
		return
	end
	local channel_index = math.random(1, #hits)
	if hits[channel_index] then
		local channle_doc = hits[channel_index]
		local article = channle_doc._source.article
		return article.title
	end
end
function getContentByChannel( media, channel, maxChannel )
	local v = { media = media, channel = channel }
	local channel_fields = {"timeby","channel","media","total","elements"}
	local resp = channel_dao:query_lastest_by_channel(v.media, v.channel, channel_fields)
	local movie_codes = {}
	if resp and resp.hits then
		movie_codes = selectCodes(resp.hits.hits, maxChannel)
	end
	return movie_codes;
end

local fields = {"article","digests","lcount","issueds","evaluates","genres"}

local year = util_time.year()
local from = 0
local size = 30
local body = {
	  from = from,
	  size = size,
	  sort = { ["lpipe.time"] = { order = "desc"},["article.year"] = { order = "desc"}},
	  query = {
	    bool = {
		  filter = {
		      range = {
		        ["article.year"] = {
		          lte = year
		        }
		      }
		   },
		   must = {
		       range = {
			      lcount = { gte = 0}
			   }
		   }
	    }
	  }
	}
local resp, status = content_dao:search(body)
local contents = {}
if resp then
	contents = resp.hits
else
	log(ERR,"status:"..tostring(status))
	contents.hits = {}
	contents.total = 0
end

local randomWord = buildSearchWord(contents.hits)

local content_doc = {}
content_doc.header = buildHeader()
content_doc.version = context.version()
content_doc.hits  = contents
content_doc.qWord  = randomWord

template.render("mobile/home.html", content_doc)