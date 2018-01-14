local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local dochtml = require "util.dochtml"
local context = require "util.context"

local template = require "resty.template"

local content_dao = require "dao.content_dao"
local link_dao = require "dao.link_dao"
local channel_dao = require "dao.channel_dao"
local util_string = require "util.string"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local to_target_id = function ( uri )
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/movie/play/([a-z]?[0-9]{3,})','ijo')
	if m then
		return m[1]
	end
end
local uri = ngx.var.uri
local uri = ngx.var.uri
local target_id = to_target_id(uri)
log(ERR,"uri:" .. tostring(uri) .. ",target_id:" .. tostring(target_id))
if not target_id then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end

local resp = ngx.location.capture("/api/movie//link.json?id=" .. target_id)
if resp and resp.status ~= 200 then
	return ngx.exit(resp.status)
end
function queryVMetas( sCode, from, size )
	if not sCode then
		return nil
	end
    local shoulds = {}
    table.insert(shoulds,{
      match = { 
        code = sCode
      }
    })
    local sorts = {}
    -- local sort = {_score = {order = "desc"}}
    -- table.insert(sorts, sort)
    sort = {episode = {order = "asc"}}
    table.insert(sorts, sort)
    local body = {
      from = from,
      size = size,
      sort = sorts,
      query = {
          bool = {
            must = shoulds,
            must_not = {
              match = { status = -1 }
            }
          }
      }

    }
    return link_dao:search(body)
end
local return_obj = cjson_safe.decode(resp.body)
local link_doc = return_obj.data
local sCode = link_doc.code
local vResp = queryVMetas(sCode ,0 , 100)

-- log(ERR,"cjson_safe:" .. cjson_safe.encode(link_doc))

if link_doc.link then
	local parserArr = {}
	-- table.insert(parserArr, 'https://aikanapi.duapp.com/odflv1217/index.php?url={URL}') --error
	-- table.insert(parserArr, 'https://odflvapi.duapp.com/odflv/index.php?url={URL}')  -- ban
	table.insert(parserArr, 'http://aikan-tv.com/?url={URL}')
	-- table.insert(parserArr, 'https://vipflv.duapp.com/x1/tong.php?url={URL}')
	-- table.insert(parserArr, 'https://jx.maoyun.tv/index.php?id={URL}') --2
	-- table.insert(parserArr, 'http://api.xfsub.com/index.php?url={URL}') --recheck
	-- table.insert(parserArr, 'http://qtv.soshane.com/ko.php?url={URL}') --recheck
	local index = math.random(#parserArr)
	local templateURL = parserArr[index]
	templateURL = ngx.re.sub(templateURL, "{URL}", link_doc.link)
	link_doc.link = templateURL
end
-- link_doc.secret = 'secret21e'
local content_doc = {}
content_doc.header = {
   title = '免费下载:' .. link_doc.title .. ",为你所用才是资讯"
}
context.withGlobal(content_doc)
content_doc.link_doc  = link_doc
content_doc.config  = {
	jiathis_uid = context.jiathis_uid,
	weibo_uid = context.weibo_uid,
	weibo_app_key = context.weibo_app_key
}
if vResp and vResp.hits then
	local vmeta_docs = vResp.hits
	content_doc.vmeta_docs = vmeta_docs
end


if string.match(uri,"^/m/") then
	template.render("mobile/play.html", content_doc)
else
	template.render("play.html", content_doc)
end
