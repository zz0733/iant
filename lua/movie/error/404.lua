local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_arrays = require "util.arrays"
local util_time = require "util.time"
local context = require "util.context"
local util_string = require "util.string"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local channel_dao = require "dao.channel_dao"
local link_dao = require "dao.link_dao"

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
local error = {}
error.code = 404
error.message = "内容迷失在宇宙中了..."

local content_doc = {}
content_doc.header = buildHeader()
content_doc.error = error
context.withGlobal(content_doc)

template.render("error/404.html", content_doc)