local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local link_dao = require "dao.link_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local body = {
    query = {
        match_all = {
        }
    }
}

local sourceClient = client_utils.client()
local targetClient =  sourceClient
local sourceIndex = "link_v2";
local targetIndex = "link_v3";
link_dao.index = targetIndex
local scroll = "5m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 100
scanParams.body = body

local keepFields = {"_doc_cmd","id","title","link","secret","space","directors","ctime","status"}
local makeLinkDoc = function ( doc )
  local newDoc = {}
  for i = 1, #keepFields do
      local fld = keepFields[i]
      newDoc[fld] = doc[fld]
  end
  newDoc.lid = newDoc.id
  -- 清理标题中的广告信息和冗余信息
  local link_title = newDoc.title
  if link_title then
    link_title = ngx.re.gsub(link_title, "(www\\.[a-z0-9\\.\\-]+)|([a-z0-9\\.\\-]+?\\.com)|([a-z0-9\\.\\-]+?\\.net)", "","ijou")
    link_title = ngx.re.gsub(link_title, "(电影天堂|久久影视|阳光影视|阳光电影|人人影视|外链影视|笨笨影视|390影视|转角影视|微博@影视李易疯|66影视|高清影视交流|大白影视|听风影视|BD影视分享|影视后花园|BD影视|新浪微博@笨笨高清影视|笨笨高清影视)", "","ijou")
    link_title = ngx.re.gsub(link_title, "(小调网|阳光电影|寻梦网)", "","ijou")
    link_title = ngx.re.gsub(link_title, "[\\[【][%W]*[】\\]]", "","ijou")
    newDoc.title = link_title
 end
  local code = doc.code
   if code and string.startsWith(code, 'imdbtt') then
       code = ngx.re.sub(code, "imdbtt", "")
       newDoc.imdb = code
   elseif code and string.startsWith(code, 'imdb') then
       code = ngx.re.sub(code, "imdb", "")
       newDoc.imdb = code
   end
   return newDoc
end


local scan_count = 0
local scrollId = nil
local index = 0
local save = 0
local total = nil
local begin = ngx.now()
while true do
     index = index + 1;
     local data,err;
     local start = ngx.now()
     if not scrollId then
         data, err = sourceClient:search(scanParams)
     else
        data, err = sourceClient:scroll{
          scroll_id = scrollId,
          scroll = scroll
        }
     end
     -- local shits = cjson_safe.encode(data)
     -- log(ERR,"data:" .. shits .. ",err:" .. tostring(err))
     if data == nil or not data["_scroll_id"] or #data["hits"]["hits"] == 0 then
        local cost = (ngx.now() - begin)
         cost = tonumber(string.format("%.3f", cost))
        log(ERR, "done.match,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total,save = save,id = doc_id}
        break
     else
         total = data.hits.total
         local hits = data.hits.hits
         local shits = cjson_safe.encode(hits)
         log(ERR,"hits:" .. shits)
         scan_count = scan_count + #hits
         ngx.update_time()
         local cost = (ngx.now() - start)
         cost = tonumber(string.format("%.3f", cost))
         log(ERR,"scrollId["..tostring(scrollId) .. "],total:" .. total ..",hits:" .. tostring(#hits) 
                .. ",scan:" .. tostring(scan_count)..",index:"..index..",cost:" .. cost)
        local elements = {}
     
        local save_docs = {}
        for _,v in ipairs(hits) do
            local doc = v["_source"]
            if doc and doc.status and doc.status > -1 then
                doc.id = v["_id"]
                local newDoc  = makeLinkDoc(doc)
                table.insert(save_docs, newDoc)
            end
        end
        local str_docs = cjson_safe.encode(save_docs)
        local srep,serr = link_dao:bulk_docs(save_docs)
        if srep then
          save = save + #save_docs
        end
        log(ERR,"len:"..tostring(#save_docs)..",str_docs:" .. str_docs .. ",err:" .. tostring(serr))
        scrollId = data["_scroll_id"]
     end
end
local body = cjson_safe.encode(message)
ngx.say(body)