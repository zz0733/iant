local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"
local util_time = require "util.time"
local util_const = require "util.const"

local decodeURI = ngx.unescape_uri

local content_dao = require "dao.content_dao"
local ssdb_content = require "ssdb.content"

local meta_dao = require "dao.meta_dao"

local ngx_re_sub = ngx.re.sub

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local message = {}
message.code = 200
local method = args.method or "home"
local resp, status;
if method == "home" then
  local offset = tonumber(args.offset) or 0
  local ltime = tonumber(args.ltime) or ngx.time()
  local year = util_time.year()
  local from = offset
  local size = 30
  local filters = {}
  local filter = {range = { year = { lte = year }}}
  table.insert(filters, filter)
  filter = {range = { issueds = { lte = ltime }}}
  table.insert(filters, filter)
  local must_arr = {}
  table.insert(must_arr, { match = { media = 0 }})
  table.insert(must_arr, { match = { pstatus = 1 }})

  local sort_arr = {}
  -- table.insert(sort_arr, { issueds = { order = "desc" }})
  table.insert(sort_arr, { year = { order = "desc" }})
  table.insert(sort_arr, { epmax_time = { order = "desc" }})
  local body = {
      from = from,
      size = size,
      sort = sort_arr,
      query = {
        bool = {
           filter = filters,
           must = must_arr
        }
      }
    }
  -- resp, status = content_dao:search(body)
  resp, status = meta_dao:search(body, true)
  -- log(ERR,"resp:"..tostring(cjson_safe.encode(resp)) .. ",status:" ..tostring(status))
  if resp and resp.hits and resp.hits.total > 0  then
    local hits = resp.hits
    local data = {}
    local contents = {}
    data.contents = contents
    local mintime = ltime
   
    for _,v in ipairs(hits.hits) do
        local _id = v._id
        local _es_source = v._source
        local source = _es_source
        -- local source = kv_doc[_id]
        local article = source.article;
        local genres = source.genres;
        local digests = source.digests;
        -- local evaluates = source.evaluates;
        -- local lpipe = source.lpipe;
        local rate 
        if source.douban and source.douban.rate then
             rate = source.douban.rate
        end
        local str_cost
        if source.cost then
           local minute = source.cost / 60
           local hour = minute / 60
           str_cost =  math.modf(hour) .. ":" .. math.fmod(minute, 60 ) .. ":00"
        end
        local str_img
        if digests then
           for _,v in ipairs(digests) do
              str_img = v
              str_img = ngx_re_sub(str_img, "[%.]webp", ".jpg")
              str_img = ngx_re_sub(str_img, "http:", "https:")
           end
        end
        local media_names = { 
           tv = "电视剧",
           movie = "电影"
        }
        local sortName = util_const.index2Name("SORT_DICT",source.sort)
        local content = {}
        content.id = _id
        content.title = source.title
        content.img = str_img
        content.cost = str_cost
        content.media = sortName
        content.rate = rate
        if source.epmax then
          local epmax = source.epmax
          content.epmax = epmax.index
        end
        if source.issueds and source.issueds[1] and source.issueds[1] < mintime then
           mintime = source.issueds[1]
        end
        if genres then
          local link_genres = {}
          local toIndex = math.min(3,#genres)
          for i=1,toIndex do
             table.insert(link_genres,genres[i])
          end
          content.genres = link_genres
        end
        table.insert(contents,content)
    end
    local content_size = #hits.hits
    local next_offset = 0
    if mintime == ltime then
      next_offset = offset + content_size 
    end
    data.hasmore = false
    data.ltime = mintime
    data.offset = next_offset
    message.data = data
    if hits.total > from + content_size then
       data.hasmore = true
    end
    local max_offset = 100
    if next_offset >= max_offset then
      data.hasmore = false
    end
  end
end
 
if status ~= 200 then
  message.code = 500
  message.error = status
end
ngx.say(cjson_safe.encode(message))