local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_arrays = require "util.arrays"
local util_time = require "util.time"
local util_context = require "util.context"
local util_string = require "util.string"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local channel_dao = require "dao.channel_dao"
local link_dao = require "dao.link_dao"
local meta_dao = require "dao.meta_dao"

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
	log(ERR,"selectCodes:" .. cjson_safe.encode(hits) )
	local select_ids = {}
	local max_select = max or 20
	for _,hv in ipairs(hits) do
		local elements = hv._source.elements
		if elements then
			table.sort(elements, comp)
			for _,v in ipairs(elements) do
				if v.id then
					table.insert(select_ids, v.id)
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
		return channle_doc.title
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

local resp = ngx.location.capture("/api/movie/scroll.json?method=home")
if resp and resp.status ~= 200 then
	return ngx.exit(resp.status)
end
local message = cjson_safe.decode(resp.body)
local data = message.data
if not data then
	log(ERR,"miss data, cause:"..tostring(cjson_safe.encode(message)))
	return ngx.exit(500)
end
-- log(ERR,"data:"..tostring(cjson_safe.encode(message)))
-- log(ERR,"randomWord:"..tostring(randomWord))
local randomWord
if data and  data.contents then
	randomWord = buildSearchWord(data.contents)
end

function makeOrderContents( ... )
	local order_contents = {}
	local torrent = {}
	torrent.video = 1
	torrent.id = 'm02084390122'
	torrent.title = '黑色四叶草EP33'
	torrent.link = 'bea5874f59841cdd4bc738ecb2eaf12a51d62434'
	torrent.img = 'https://icdn.lezomao.com/img/hssyc33.png'
	-- order_contents[5] = torrent
	order_contents = {}
    -- local resp, status = link_dao:latest_feeds_video(0, 20)
    local must_arr = {}
    table.insert(must_arr, { match = { media = 1}})
    table.insert(must_arr, { match = { pstatus = 1}})
    local body = {
	  from = 0,
	  size = 20,
	  sort = {
	    epmax_time = {
	      order = "desc"
	    }
	  },
	  query = {
	    bool = {
		    must = must_arr
	    }
	  }
	}
    local resp, status = meta_dao:search(body, false)
    -- log(ERR,'meta_dao:search.resp:' .. cjson_safe.encode(resp))
    if resp and resp.hits then
    	local hits = resp.hits.hits
    	local keepCount = 2
    	local shuffleArr = util_arrays.sub(hits, keepCount + 1)
    	util_arrays.shuffle(shuffleArr)
    	local orderArr = {1,3,5,7,9}
    	local orderArr = {1,3,5}
    	for index, order in pairs(orderArr) do
    		local _source = nil;
            if index <= keepCount then
            	if hits[index] then
            		-- _source = hits[index]._source
            		_source = meta_dao:get(hits[index]._id)
            		_source.id = hits[index]._id
            	end
            else
            	local destIndex = index - keepCount
            	if shuffleArr[index] then
            		_source = shuffleArr[index]._source
            	end
            end
    		if _source then
				local torrent = {}
				torrent.video = 1
				torrent.id = _source.id
				torrent.title = _source.title
				torrent.albumId = _source.albumId
				-- torrent.link = _source.vmeta.url
				-- torrent.link = util_context.CDN_URI .. "/vmeta/".. _source.id .. ".m3u8"
				torrent.link = "/vmeta/".. _source.id .. ".m3u8"
				torrent.img = _source.digests[1]
				order_contents[order] = torrent

				log(ERR,'torrent:' .. cjson_safe.encode(torrent))
				-- local torrent = _source
				-- torrent.id = _source.lid
				-- torrent.link = 'https://youku163.zuida-bofang.com/20180706/8863_f778785e/index.m3u8'
				-- torrent.img = _source.feedimg
				-- order_contents[order] = torrent
			end
    	end
    end
    -- log(ERR,'order_contents:' .. cjson_safe.encode(order_contents))
	return order_contents
end
local  order_contents = makeOrderContents()
-- local  order_contents = {}
local  contents = data.contents
local iorder = 1
local cindex = 1
local ctotal = #contents
while true do
  if not order_contents[iorder] then
	   order_contents[iorder] = contents[cindex]
	   cindex = cindex + 1
  end
  iorder = iorder + 1
  if cindex == ctotal then
  	break
  end
end
data.contents = order_contents

local movie_codes  = getContentByChannel("movie","热门",15)
log(ERR,'movie_codes:' .. cjson_safe.encode(movie_codes))
local from = 0
local size = #movie_codes
local must_arr = {}
table.insert(must_arr, { match = { media = 1}})
table.insert(must_arr, { match = { pstatus = 1}})
table.insert(must_arr, { terms = { _id = movie_codes }})
local body = {
  from = 0,
  size = 20,
  sort = {
    epmax_time = {
      order = "desc"
    }
  },
  query = {
    bool = {
	    must = must_arr
    }
  }
}
local resp = meta_dao:search(body, true)
local playing_movie = {}
if resp then
	playing_movie = resp.hits
else
	playing_movie.hits = {}
	playing_movie.total = 0
end



local content_doc = {}
content_doc.header = buildHeader()
util_context.withGlobal(content_doc)
content_doc.data  = data or {}
content_doc.playing_movie = playing_movie
content_doc.qWord  = randomWord

template.render("home.html", content_doc)