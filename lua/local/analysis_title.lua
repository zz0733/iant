local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local content_dao = require("dao.content_dao")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local string_match = string.match;
local ngx_re_gsub = ngx.re.gsub;
local ngx_re_match = ngx.re.match;
local table_insert = table.insert;
local message = {}
message.code = 200

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local body = {
    _source = {"names","article","directors","actors","genres","issueds"},
    query = {
        match_all = {
        }
    }
}

local sourceClient = client_utils.client()
local sourceIndex = "content";
local scroll = "2m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 100
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

function add2Arr(text_arr, source )
   if not source then
      return
   end
   if util_table.is_table(source) then
      for k,v in pairs(source) do
        if v then
           table.insert(text_arr, v)
        end
      end
   else
      table.insert(text_arr, source)
   end
   
end
local function isEmpty(s)
  return s == nil or s == ''
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
             if  source and source.article then
                names = source.names or {}
                table.insert(names, source.article.title)
                for ni,nv in ipairs(names) do
                    if not isEmpty(nv) then
                        local text_arr = {}
                        add2Arr(text_arr, source.article.year)
                        add2Arr(text_arr, nv)
                        if source.directors then
                           add2Arr(text_arr, source.directors)
                        end
                        if source.article.imdb then
                           add2Arr(text_arr, "imdb" .. source.article.imdb)
                        end
                        local splitor = " "
                        local all_txt = table.concat( text_arr , splitor)
                        local aresp = content_dao:analyze(all_txt,nil,nil,'ik_smart')
                        local analyze_arr = {}
                        if aresp and aresp.tokens then
                           for _,tv in ipairs(aresp.tokens) do
                               add2Arr(analyze_arr, tv.token)
                           end
                        end
                        local analyze_txt = table.concat( analyze_arr , splitor)
                        log(CRIT, "STARTBODY:" .. v._id .."_" .. ni .. "=".. analyze_txt .. ":ENDBODY")
                    end
                end
             else
                 log(ERR, "sourceErr:" .. v._id .. ",hit:" .. cjson_safe.encode(v))
             end
             aCount = aCount + 1
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