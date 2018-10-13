local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local task_dao = require "dao.task_dao"
local meta_dao = require "dao.meta_dao"
local ssdb_task = require "ssdb.task"

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
       -- log(ERR,"meta_dao:get:" .. mv._id .. ",meta:" .. cjson_safe.encode(mv))
       local vmetaRet, err = meta_dao:get(mv._id)
       if err then
          log(ERR,"getMetaErr:" .. mv._id .. ",cause:" .. cjson_safe.encode(err))
       elseif vmetaRet  then
            if vmetaRet.digests then
                for di,imgURL in ipairs(vmetaRet.digests) do
                 if string.match(imgURL,"^/img/") or string.find(imgURL, util_context.CDN_URI, 1, true) then
                    local metaDocs = {}
                    vmetaRet.cstatus = vmetaRet.cstatus or 0
                    vmetaRet.cstatus = bit.bor(vmetaRet.cstatus, 1)
                    table.insert(metaDocs, vmetaRet)
                    meta_dao.save_metas(metaDocs)
                    break
                 end
                 local digestTask = {}
                 digestTask.type = 'common-image'
                 digestTask.url = imgURL
                 digestTask.level = 1
                 local params = {}
                 params.metaId = mv._id
                 params.index = di
                 digestTask.params = params
                 local tresp, tstatus = ssdb_task:qpush( digestTask.level, digestTask )
                 log(ERR,"searchUnDigest.task:" .. cjson_safe.encode(digestTask) )
                 count = count + 1
                 break
               end
            else
                log(ERR,"emptyDigest:" .. mv._id)
                local metaDocs = {}
                vmetaRet.cstatus = vmetaRet.cstatus or 0
                vmetaRet.cstatus = bit.bor(vmetaRet.cstatus, 1)
                table.insert(metaDocs, vmetaRet)
                meta_dao.save_metas(metaDocs)
            end
       else
          log(ERR,"deleteMeta:" .. mv._id)
          local idArr = {}
          table.insert(idArr, mv._id)
          meta_dao:delete_by_ids(idArr)
          -- ssdb_vmeta:remove(mv._id)
       end
   end
   
end
message.count = count
local body = cjson_safe.encode(message)
ngx.say(body)