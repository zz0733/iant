local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local string_match = string.match;
local ngx_re_gsub = ngx.re.gsub;
local message = {}
message.code = 200

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local to_date = ngx.time()
local from_date = to_date - 24*60*60
local body = {
    _source = {"title","format","ctime"},
    query = {
        bool = {
            filter = {
              range = {
                ctime ={
                  gte = from_date
                }
              }
            }
        }
      }
}

local sourceClient = client_utils.client()
local sourceIndex = "link";
local scroll = "1m";
local scanParams = {};
scanParams.index = sourceIndex
scanParams.scroll = scroll
-- scanParams.sort = {"_doc"}
scanParams.size = 100
scanParams.body = body

local scan_count = 0
local scrollId = nil
local index = 0
local total = nil
local begin = ngx.now()
local md5_set = {}
local name_set = {}
local name_arr = {}
function excludeName( title )
    if not title then
        return true
    end
    if string_match(title,"分享群") then
        return true
    end
    return false
end
function excludeFormat( format )
    if not format then
        return false
    end
    local excludeSet = {}
    excludeSet["ppt"] = 1
    excludeSet["mup"] = 1
    excludeSet["exe"] = 1
    if excludeSet[format] then
        return true
    end
    return false
end
function addMsg(nameArr,msg_obj,source)
    local md5 = source.md5
    if md5 and string.len(md5) > 1 then
       if md5_set[md5]  then
         return
       else
         md5_set[md5] = 1
       end
    end
    if name_set[msg_obj.title] then
        return
    end
    name_set[msg_obj.title] = 1
    table.insert(nameArr,msg_obj)
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
        log(ERR, "done.match,index:"..index..",scan:"..scan_count..",total:" .. tostring(total) .. ",cost:" .. cost)
        message.data = {cost = cost,index = index, scan = scan_count, total = total}
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
             local title = source.title
             local format = source.format
             if not excludeName(title) and not excludeFormat(format) then
                  local msg_obj = {}
                  title = ngx_re_gsub(title, "★", "")
                  title = ngx_re_gsub(title, "【微博@.*?】", "")
                  msg_obj.title = title
                  local now_time = ngx.time()
                  local near_time = source.ctime;
                  local issueds = source.issueds
                  if issueds  then
                      local min_gap = ngx.time()
                      for _,v in ipairs(issueds) do
                          local gap = now_time - v.time
                          if gap < min_gap then
                              min_gap = gap
                              near_time = v.time
                          end
                      end
                  end
                  msg_obj.time = near_time
                  addMsg(name_arr,msg_obj,source)
             end
         end
         scrollId = data["_scroll_id"]
     end
end
function cmp( a, b )
    return b.time < a.time
end
table.sort( name_arr, cmp )
local title_arr = {}
for _,v in ipairs(name_arr) do
    table.insert(title_arr,v.title)
end
local shits = cjson_safe.encode(name_arr)
log(ERR,"name_arr:" .. shits)
local body = table.concat( title_arr , "\n")
-- local body = cjson_safe.encode(message)
ngx.say(body)