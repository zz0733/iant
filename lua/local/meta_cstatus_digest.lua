local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local task_dao = require "dao.task_dao"
local meta_dao = require "dao.meta_dao"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local from_date = tonumber(args.from) or (ngx.time() - 2*60*60)
local size = tonumber(args.size) or (100)

local resp, status = meta_dao:searchUnDigest(from_date, size)
-- log(ERR,"searchUnDigest:" .. cjson_safe.encode(resp) .. ",status:" .. status)
local count = 0
if resp and resp.hits and resp.hits.hits then
   local hits = resp.hits.hits
   for mi,mv in ipairs(hits) do
     local _source = mv._source
     local digests = _source.digests
     -- log(ERR,"digests:" .. cjson_safe.encode(digests) )
     if digests then
       for di,dv in ipairs(digests) do
         if string.match(dv,"^/img/") or string.find(dv, util_context.CDN_URI, 1, true) then
            local metaDocs = {}
            table.insert(metaDocs, mv)
            meta_dao.save_metas(metaDocs)
            break
         end
         local digestTask = {}
         digestTask.type = 'common-image'
         digestTask.url = dv
         digestTask.level = 2
         local params = {}
         params.metaId = mv._id
         params.index = di
         digestTask.params = params
         local taskArr = {}
         table.insert(taskArr, digestTask)
         local tresp, tstatus = task_dao:insert_tasks( taskArr )
         log(ERR,"searchUnDigest.taskArr:" .. cjson_safe.encode(taskArr) )
         count = count + 1
         break
       end
     end
   end
end
message.count = count
local body = cjson_safe.encode(message)
ngx.say(body)