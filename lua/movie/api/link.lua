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
if not args.id then
  message.status = 400
  message.message = "empty id"
  ngx.say(cjson_safe.encode(message))
  return
end

local ids = {}
local fields = {"link","md5","secret","title"}
table.insert(ids, args.id)
local resp, status = link_dao:query_by_ids( ids, fields )
 
if status == 200 then
  message.code = 200
  if resp then
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
else
  message.code = 500
  message.error = status
end
ngx.say(cjson_safe.encode(message))
