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

local args = ngx.req.get_uri_args()

local qWord = args.q
-- log(ERR,"qWord:" .. cjson_safe.encode(args))
local hits = {}
if qWord then
	local  from = 0
	local  size = 10
	local  fields = {"article","digests","lcount","issueds","evaluates","genres"}
	local resp, status = content_dao:query_by_title(from, size, qWord, fields);
	if resp and resp.hits then
		hits = resp.hits
	end
end
-- log(ERR,"hits:" .. cjson_safe.encode(hits))

local header = {}
header.canonical = "http://www.lezomao.com" .. ngx.var.uri .. "?" .. ngx.var.QUERY_STRING
header.keywords = "狸猫资讯,为你所用,迅雷下载,种子下载,免费下载"
header.description = "《狸猫资讯》(LezoMao.com)是一款智能的资讯软件,已为你寻找关注的内容："..qWord..",为你所用，才是资讯！"
header.title = qWord .. "-搜索结果,为你所用，才是资讯 - 狸猫资讯(LezoMao.com)"

local content_doc = {}
content_doc.header = header
content_doc.version = context.version()
content_doc.hits  = hits
content_doc.qWord  = qWord

template.render("mobile/search.html", content_doc)