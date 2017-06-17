local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"
local util_string = require "util.string"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local to_region = function ( uri )
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/movie/region/([^/.]{2,})','ijo')
	if m then
		return m[1]
	end
end
local select_title = function (hits )
	if not hits or not hits.hits then
	   return 
	end
	local doc_arr = hits.hits
	if #doc_arr < 1 then
		return
	end
	local index = math.random(1, #doc_arr)
	local doc = doc_arr[index]
	return doc._source.article.title;
end

local uri = ngx.var.uri
local qWord = to_region(uri)
if not qWord then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
local args = ngx.req.get_uri_args()
local cur_page = tonumber(args.page) or 1
if cur_page > context.search_max_page then
   cur_page = context.search_max_page
elseif cur_page < 1 then
   cur_page = 1
end
local  size = context.search_page_size
local  from = (cur_page - 1) * size
-- log(ERR,"region:" .. tostring(qWord))
local hits = {}
local  fields = {"article","digests","lcount","issueds","evaluates","genres"}
local resp, status = content_dao:query_by_region(from, size, qWord, fields);
if resp and resp.hits then
	hits = resp.hits
end
-- log(ERR,"hits:" .. cjson_safe.encode(hits))

local header = {}
header.canonical = "http://www.lezomao.com" .. ngx.var.uri
if ngx.var.QUERY_STRING and cur_page > 1 then
	header.canonical = header.canonical  .. "?" .. ngx.var.QUERY_STRING
end
header.keywords = "狸猫资讯,为你所用,迅雷下载,种子下载,免费下载"
header.description = "《狸猫资讯》(LezoMao.com)是一款智能的资讯软件,已为你寻找关注的内容："..qWord..",为你所用，才是资讯！"
header.title = qWord .. "-搜索结果,为你所用，才是资讯 - 狸猫资讯(LezoMao.com)"

local content_doc = {}
content_doc.header = header
content_doc.version = context.version()
content_doc.hits  = hits
content_doc.qWord  = select_title(hits)
content_doc.region  = qWord
content_doc.base_uri  = ngx.var.uri
content_doc.cur_page  = cur_page
content_doc.page_size  = context.search_page_size
content_doc.max_page  = context.search_max_page
template.render("region.html", content_doc)