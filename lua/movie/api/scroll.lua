local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local context = require "util.context"
local util_time = require "util.time"

local decodeURI = ngx.unescape_uri

local content_dao = require "dao.content_dao"



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
  local fields = {"article","digests","lcount","issueds","evaluates","genres"}
  local year = util_time.year()
  local from = offset
  local size = 30
  local filters = {}
  local filter = {range = {["article.year"] = { lte = year }}}
  table.insert(filters, filter)
  filter = {range = {["lpipe.time"] = { lte = ltime }}}
  table.insert(filters, filter)
  local body = {
      from = from,
      size = size,
      sort = { ["lpipe.time"] = { order = "desc"},["article.year"] = { order = "desc"}},
      query = {
        bool = {
        filter = filters,
        must = {
             range = {
              lcount = { gte = 1}
            }
         }
        }
      }
    }
  resp, status = content_dao:search(body)
  -- log(ERR,"resp:"..tostring(cjson_safe.encode(resp)) .. ",status:" ..tostring(status))
  if resp and resp.hits  then
    local hits = resp.hits
    local data = {}
    local contents = {}
    data.contents = contents
    local mintime = ltime
     for i,v in ipairs(hits.hits) do
        local source = v._source;
        local article = source.article;
        local genres = source.genres;
        local digests = source.digests;
        local evaluates = source.evaluates;
        local lpipe = source.lpipe;
        local rate
        if evaluates and evaluates[1] then
             rate = evaluates[1].rate
        end
        local str_cost
        if article.cost then
           local lcost = article.cost / 60
           str_cost =  math.modf(lcost) .. ":" .. math.fmod(article.cost, 60 ) .. ":00"
        end
        local str_img
        if digests then
           for _,v in ipairs(digests) do
              if v.sort == 'img' then
                 str_img = v.content
                 str_img = ngx.re.sub(str_img, "[%.]webp", ".jpg")
                 break
              end
           end
        end
        local media_names = { 
           tv = "电视剧",
           movie = "电影"
        }
        local media_name = media_names[article.media]
        local content = {}
        content.id = v._id
        content.title = article.title
        content.img = str_img
        content.cost = str_cost
        content.cost = str_cost
        content.media = media_name
        content.rate = rate
        if lpipe and lpipe.epmax then
          content.epmax = epmax
        end
        if lpipe and lpipe.time and lpipe.time < mintime then
           mintime = lpipe.time
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
