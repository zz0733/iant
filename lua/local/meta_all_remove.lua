local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local meta_dao = require "dao.meta_dao"
local ssdb_meta = require "ssdb.meta"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local from_date = tonumber(args.from) or (ngx.time() - 2*60*60)
local size = tonumber(args.size) or (100)

local must_array = {}
if args.albumId then
  table.insert(must_array,{match = { albumId = args.albumId }})
end


table.insert(must_array,{match = { media = 1 }})
table.insert(must_array,{match = { source = 2 }})

local body = {
    size = size,
    query = {
        bool = {
            must = must_array,
        }
    }
}
local count = 0
while true do
  local resp, status = meta_dao:search(body)
  log(ERR,"meta_dao_To_remove:" .. cjson_safe.encode(resp) .. ",status:" .. status)
  if resp and resp.hits and resp.hits.hits then
     local hits = resp.hits.hits
     for _, mv in ipairs(hits) do
        local idArr = {}
        table.insert(idArr, mv._id)
        resp, status = meta_dao:delete_by_ids(idArr)
        ssdb_meta:remove(mv._id)
        count = count + 1
        log(ERR,"removeMeta:" .. mv._id .. ",count:" .. count .. ",resp:" .. cjson_safe.encode(resp) .. ",status:" .. tostring(status))
     end
     if #hits < size then
        break
     end
  else 
    break
  end
end
message.count = count
local body = cjson_safe.encode(message)
ngx.say(body)