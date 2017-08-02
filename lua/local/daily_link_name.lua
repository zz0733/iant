local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local match_handler = require("handler.match_handler")
local client_utils = require("util.client_utils")
local link_dao = require("dao.link_dao")

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
local to_date = ngx.time()
local from_date = to_date - 1*24*60*60
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
local cur_year = os.date("%Y");
function excludeName( title )
    if not title then
        return true
    end
    if string_match(title,"分享群") then
        return true
    end 
    if string_match(title,"随意赞助") then
        return true
    end
    local mm = ngx_re_match(title,"[^0-9](19[0-9]{2}|2[0-9]{3})[^0-9]")
    if mm and mm[0] then
        if mm[0] ~= cur_year then
            return true
        end
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
    table_insert(nameArr,msg_obj)
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
                  title = ngx_re_gsub(title, "速度。刪！", "")
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
if not scrollId then
    local params = {}
    params.scroll_id = scrollId
    sourceClient:clearScroll(params)
end
function cmp( a, b )
    return b.time < a.time
end
table.sort( name_arr, cmp )
local ignore_tokens = {
  ["动画"] = 1,
  ["高清"] = 1,
  ["连载"] = 1,
  ["更新"] = 1,
  ["第"] = 1,
  ["集"] = 1,
  ["季"] = 1,
  ["至"] = 1,
};

function keep_tokens(tokens )
   if not tokens then
     return
   end
   -- 默认已排序
   local keep_arr = {}
   local offset = 0
   for i,v in ipairs(tokens) do
      if v.start_offset >= offset and (v.end_offset - v.start_offset > 1) then
        if not ignore_tokens[v.token] then
          table_insert(keep_arr,v)
          offset = v.end_offset
        end
      end
   end
   return keep_arr
end
function getJaccard( ltoken,rtoken )
  local union_set = {}
  local inter_set = {}
  for i,v in ipairs(ltoken) do
    union_set[v.token] = 1
  end
  for i,v in ipairs(rtoken) do
    if union_set[v.token] then
      inter_set[v.token] = 1
    end
    union_set[v.token] = 1
  end
  local union_count = 0
  for k,v in pairs(union_set) do
    union_count = union_count + 1
  end  
  local inter_count = 0
  for k,v in pairs(inter_set) do
    inter_count = inter_count + 1
  end
  local jaccard = 0
  if union_count > 0 then
    jaccard = inter_count / union_count
  end
  return jaccard
end
function getGroup( tokens )
  local group = "其他"
  if not tokens then
    return group
  end
  local group_map = {
     ["大陆"] = {"中国","大陆","国剧","中剧"},
     ["日剧"] = {"日剧","日本","日语"},
     ["韩剧"] = {"韩剧","韩国","韩语"},
     ["欧美"] = {"欧美","美剧","英剧","美国","英国","中英"},
     ["泰剧"] = {"泰剧","泰国","泰语","泰版"},
     ["港剧"] = {"港剧","香港","港版"}
  }
  for i,v in ipairs(tokens) do
     local title = v.title
     for gname,garr in pairs(group_map) do
      for _,gmark in ipairs(garr) do
        if string.match(title,gmark) then
          log(ERR,"group:"..gname..",title:" .. title..",mark:"..gmark)
          return gname
        end
      end
     end
  end
  return group
end
local field = "title"
local token_arr = {}
for _,v in ipairs(name_arr) do
    local title = v.title
    title = ngx_re_gsub(title,"\\.[a-z0-9]{2,6}$","")
    title = ngx_re_gsub(title,"【","[")
    title = ngx_re_gsub(title,"】","]")
    title = ngx_re_gsub(title,"《","[")
    title = ngx_re_gsub(title,"》","]")
    local resp = link_dao:analyze(title, field)
    if resp and resp.tokens then
       local tokens = keep_tokens(resp.tokens)
       if tokens and #tokens > 0 then
         local token_obj = {}
         token_obj.id = #token_arr + 1 
         token_obj.title = title
         token_obj.tokens = tokens
         table_insert( token_arr, token_obj )
         -- local shits = cjson_safe.encode(token_obj)
         -- log(ERR,"tokens:" .. shits)
       end
    end

end

local has_similar_map = {}
local similar_token_map = {}
local len = #token_arr
for i=1,len-1 do
  local ltoken = token_arr[i]
  if not has_similar_map[ltoken.id] then
    local similar_arr =  {}
    similar_token_map[ltoken.id] = similar_arr
    table_insert(similar_arr,ltoken)
    has_similar_map[ltoken.id] = 1
    for j=i+1,len do
       local rtoken = token_arr[j]
       if not has_similar_map[rtoken.id] then
           local score = getJaccard(ltoken.tokens,rtoken.tokens)
           if score >= 0.3 then
              local similar_arr = similar_token_map[ltoken.id]
              table_insert(similar_arr,rtoken)
              has_similar_map[rtoken.id] = 1
              -- log(ERR,"ltoken:" ..ltoken.title..",rtoken:"..rtoken.title .. ",score:".. tostring(score))
           end
       end
    end
  end
end
local group_map = {}
for ksimilar,vsimilars in pairs(similar_token_map) do
  local group = getGroup(vsimilars)
  local group_arr = group_map[group]
  if not group_arr then
    group_arr = {}
    group_map[group] = group_arr
  end
  for i,v in ipairs(vsimilars) do
    table_insert(group_arr,ksimilar..":" .. v.title)
  end
end
table.sort( group_map)
local body
for k,garr in pairs(group_map) do
  log(ERR,"Group:"..k..",size:"..#garr)
  local group_key = "@@@@@ " .. k .. " @@@@@"
  local group_val = table.concat( garr , "\n")
  local group_body = group_key .. "\n" .. group_val
  if body then
    body = body .."\n".. group_body
  else
    body = group_body
  end
end
ngx.say(body)