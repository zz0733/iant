local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require("dao.content_dao")
local link_dao = require("dao.link_dao")
local meta_dao = require("dao.meta_dao")
local ssdb_vmeta = require("ssdb.vmeta")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local string_match = string.match;
local ngx_re_gsub = ngx.re.gsub;
local ngx_re_match = ngx.re.match;
local table_insert = table.insert;

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local message = {}
message.code = 200


local body = {
    _source = false,
    query = {
        match_all = {
        }
    }
}

local sourceClient = client_utils.client()
local sourceIndex = "content";
local scroll = "5m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 50
scanParams.body = body

local scan_count = 0
local scrollId = nil
local index = 0
local aCount = 0
local total = nil
local begin = ngx.now()
local md5_set = {}
local name_set = {}
local name_arr = {}
local cur_year = os.date("%Y");

local SOURCE_DICT = {
    ["豆瓣"]= 0,
    ["douban"]= 0,
    ["爱奇艺"]= 1,
    ["腾讯视频"]= 2,
    ["优酷视频"]= 3
}

local SORT_DICT = {
    ["电影"]= 0,
    ["movie"]= 0,
    ["电视剧"]= 1,
    ["tv"]= 1
}

local LANG_DICT = {
    ["英语"]= 10,
    ["英文"]= 10,
    ["汉语"]= 20,
    ["普通话"]= 20,
    ["汉语普通话"]= 20,
    ["中文"]= 20,
    ["粤语"]= 21,
}

function isNull( val )
   return (not val) or (val == ngx.null)
end

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
        log(ERR, "done.match,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",aCount:" .. tostring(aCount) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total, aCount =  aCount}
        break
     else
         content_dao:addOnlySSDBFields(data)
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
         -- match_handler.build_similars(hits)
         for _,v in ipairs(hits) do
             local source = v._source
             if  source  and source.article then
                local article = source.article
                local metaDoc = {}
                metaDoc.id  = v._id
                -- metaDoc.albumId = ""
                metaDoc.title = article.title
                metaDoc.media = 0
                metaDoc.sort = SORT_DICT[article.media]
                metaDoc.lang = LANG_DICT[article.lang]
                metaDoc.source = SOURCE_DICT[article.template]
                if article.cost then
                   metaDoc.cost = article.cost * 60
                end
                -- metaDoc.space = 0
                metaDoc.year = article.year
                metaDoc.imdb = article.imdb
                -- metaDoc.season = 0
                -- metaDoc.episode = 0
                metaDoc.epcount = article.epcount
                -- metaDoc.epindex = 0
                metaDoc.cstatus = 0
                metaDoc.pstatus = 0
                -- metaDoc.vip = 0
                metaDoc.issueds = {}
                metaDoc.regions = {}
                metaDoc.countrys = {}
                if source.issueds then
                    for ii,iv in ipairs(source.issueds) do
                        table_insert(metaDoc.issueds, iv.time)
                        table_insert(metaDoc.regions, iv.region)
                        table_insert(metaDoc.countrys, iv.country)
                    end
                end
                metaDoc.genres = source.genres
                metaDoc.names = source.names
                metaDoc.directors = source.directors
                metaDoc.actors = source.actors

                -- not index
                metaDoc.digests = {}
                if source.digests then
                   for di,dv in ipairs(source.digests) do
                       local imgURL = ngx.re.sub(dv.content, util_context.CDN_URI, "")
                       table_insert(metaDoc.digests, imgURL)
                        if string.match(imgURL,"^/img/") then
                            metaDoc.cstatus = bit.bor(metaDoc.cstatus, 1)
                        end
                   end
                end
                if source.evaluates then
                   for ei,ev in ipairs(source.evaluates) do
                       metaDoc[ev.source] = ev
                       ev.source = nil
                   end
                end
                
                metaDoc.url = article.url
                if source.contents then
                    for ci,cv in ipairs(source.contents) do
                        metaDoc.html = cv.text
                    end
                end
                if source.lcount and source.lcount > 0 then
                   metaDoc.cstatus = bit.bor(metaDoc.cstatus, 2)
                end

                local lpipe = source.lpipe
                if lpipe then
                   for lk,lv in pairs(lpipe) do
                       if isNull(lv) then
                         lpipe[lk] = nil
                       end
                   end
                   local epmax = {}
                   epmax.index = lpipe.epmax
                   epmax.lid = lpipe.lid
                   metaDoc.epmax = epmax
                   metaDoc.epmax_time = lpipe.time
                   if epmax.lid and (not epmax.index) then
                        local  lidArr = {}
                        table.insert(lidArr, epmax.lid)
                        local lresp = link_dao:query_by_ids(lidArr,"episode")
                        if lresp and lresp.hits and lresp.hits.hits then
                            local lHit = lresp.hits.hits[1]
                            if lHit and not isNull(lHit._source.episode) then
                                epmax.index = lHit._source.episode
                            end
                        end
                   end

                end
                -- metaDoc.fill = {}
                log(ERR, "toMetaDoc:" .. cjson_safe.encode(metaDoc))
                local metaDocArr = {}
                local id = metaDoc.id
                table_insert(metaDocArr, metaDoc)
                local mresp, mstatus = meta_dao:save_metas(metaDocArr)
                aCount = aCount + 1
                log(ERR, "save_metas,count:" .. aCount .. ",id:" .. id .. ",mresp:" .. cjson_safe.encode(mresp) .. ",status:" .. tostring(mstatus))
             else
                log(ERR, "sourceErr:" .. v._id .. ",hit:" .. cjson_safe.encode(v))
             end
         end
         scrollId = data["_scroll_id"]
     end
end
if not scrollId then
    local params = {}
    params.scroll_id = scrollId
    sourceClient:clearScroll(params)
end
local body = cjson_safe.encode(message)
ngx.say(body)