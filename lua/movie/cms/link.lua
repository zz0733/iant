local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"
local util_string = require "util.string"

local template = require "resty.template"

local ssdb_content = require "ssdb.content"
local link_dao = require "dao.link_dao"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local args = ngx.req.get_uri_args() or {}
local cur_page = tonumber(args.page) or 1
if cur_page > context.search_max_page then
   cur_page = context.search_max_page
elseif cur_page < 1 then
   cur_page = 1
end
local  size = context.search_page_size
local  from = (cur_page - 1) * size
log(ERR,"qWord:" .. cjson_safe.encode(args))
local  fields = {"article","digests","lcount","issueds","evaluates","genres"}
local sorts = {}
table.insert(sorts,{ utime = { order = "desc" } } )
local body = {
		from = from,
		size = size,
		sort = sorts,
		query = {
		  ["match_all"] = {}
		}
	}
local resp, status = link_dao:search(body);
local hits = {}
if resp and resp.hits then
	hits = resp.hits
end
local data = {}
local contents = {}
data.contents = contents
for _,v in ipairs(hits.hits) do
	local _source = v._source
    local imgURL = _source.feedimg
    if imgURL then
    	_source.feedimg = ngx.re.sub(imgURL, ".*?/img/", "")
    end
	local torrent = _source
	-- torrent.video = _source.webRTC
	torrent.title = _source.title
	torrent.link = _source.link
	torrent.json = cjson_safe.encode(torrent)
    torrent.img = imgURL
    torrent.id = _source.lid
	if torrent.target then
	   torrent.targetDoc = ssdb_content:get(torrent.target)
	   if not torrent.img and torrent.targetDoc and torrent.targetDoc.digests then
	   	  local digests = torrent.targetDoc.digests
	   	  for _,dv in ipairs(digests) do
  				if dv.sort == 'img' then
  					torrent.img = dv.content
  					break
  				end
  			end
	   end
	end
	table.insert(contents, torrent)
end
log(ERR,"data:" .. cjson_safe.encode(data))

local header = {}
header.canonical = "http://www.lezomao.com" .. ngx.var.uri
if ngx.var.QUERY_STRING and cur_page > 1 then
	header.canonical = header.canonical  .. "?" .. ngx.var.QUERY_STRING
end
header.keywords = "狸猫资讯,为你所用,迅雷下载,种子下载,免费下载"
header.description = "《狸猫资讯》(LezoMao.com)是一款智能的资讯软件！"
header.title = "资源管理列表页 - 狸猫资讯(LezoMao.com)"

local content_doc = {}
content_doc.header = header
context.withGlobal(content_doc)
content_doc.data  = data
content_doc.cur_page  = cur_page
content_doc.page_size  = context.search_page_size
content_doc.max_page  = context.search_max_page

template.render("cms/link.html", content_doc)