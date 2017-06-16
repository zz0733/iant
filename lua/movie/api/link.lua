local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local link_dao = require "dao.link_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local message = {}
message.code = 200
local method = args.method or "query_by_ids"
local resp, status;
if method == "incr_bury_digg" then
  local id = args.id
  local data = util_request.post_body(ngx.req)
  local inputs = cjson_safe.decode(data)
  if not inputs then
    message.status = 400
    message.message = "json param is miss"
    ngx.say(cjson_safe.encode(message))
    return
  end
  local tid = inputs.tid
  local bury = inputs.bury or 0
  local digg = inputs.digg or 0
  -- log(ERR,"inputs:".. cjson_safe.encode(inputs))
  resp, status = link_dao:incr_bury_digg( id, tid, bury, digg )
elseif method == "query_by_ids" then
  local ids = {}
  local fields = {"link","md5","secret","title"}
  table.insert(ids, args.id)
  resp, status = link_dao:query_by_ids( ids, fields )
  if resp and resp.hits and resp.hits.hits then
    local hits= resp.hits.hits
    for _,v in ipairs(hits) do
        local doc = v._source
        doc.id = v._id
        if string.match(v._id,"^b") then
          doc.jump = true
          if doc.link and not string.match(doc.link,"^http") then
             doc.link = "https://pan.baidu.com/s/" .. doc.link
          end
        end
        message.data = doc
        break
    end
  end
elseif method == "next_links" then
  local inputs = nil
  if args.did and args.title then
     inputs = {}
     inputs.did = args.did;
     inputs.title = args.title;
     inputs.page = tonumber(args.page);
  end
  -- local data = util_request.post_body(ngx.req)
  -- local inputs = cjson_safe.decode(data)
  if not inputs then
    message.status = 400
    message.message = "json param is miss"
    ngx.say(cjson_safe.encode(message))
    return
  end
  if not inputs.did or not inputs.title then
    message.status = 400
    message.message = "did or title is empty"
    ngx.say(cjson_safe.encode(message))
    return
  end
  local page = inputs.page or 1
  if page < 1 then
     page = 1
  elseif page > 100 then
     page = 100
  end
  local  size = 4
  local  from = (page - 1) * size
  local  fields = {"title","space","ctime","issueds"}
  resp, status = link_dao:query_by_target_title(inputs.did, inputs.title1, from, size, fields)
  if resp and resp.hits then
    local hits = resp.hits
    message.data = hits
    message.data.curPage = page
    message.data.hasMore = false
    if hits.total > from + #hits.hits then
      message.data.hasMore = true
    end
  end
end
 
if status ~= 200 then
  message.code = 500
  message.error = status
end
ngx.say(cjson_safe.encode(message))
