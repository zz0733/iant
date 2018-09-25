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
-- 在线视频
local media = 1
-- "豆瓣": 0,
-- "爱奇艺": 1,
-- "腾讯视频": 2,
-- "优酷视频": 3
local source_arr = {}
table.insert(source_arr, 1)
-- table.insert(source_arr, 2)
-- table.insert(source_arr, 3)
local source_type_dict = {
  [1] = "odflv-video-cache",
  [2] = "",
  [3] = ""
}
local resp, status = meta_dao:searchUnVideo(from_date, media, source_arr, size)
-- log(ERR,"searchUnVideo:" .. cjson_safe.encode(resp) .. ",status:" .. status)
local count = 0
if resp and resp.hits and resp.hits.hits then
   local hits = resp.hits.hits
   for mi,mv in ipairs(hits) do
       local vmetaRet, err = meta_dao:get(mv._id)
       if err then
          log(ERR,"getMetaErr:" .. mv._id .. ",cause:" .. cjson_safe.encode(err))
       else
           local destType = source_type_dict[vmetaRet.source]
           if not destType or destType == "" then
              log(ERR,"ignoreUnkownType,id:" .. mv._id .. ",meta:" .. cjson_safe.encode(mv))
           else
             local newTask = {}
             newTask.type = destType
             newTask.url = vmetaRet.url
             newTask.level = 1
             local params = {}
             params.metaId = mv._id
             newTask.params = params
             local tresp, tstatus = ssdb_task:qpush( newTask.level, newTask )
             log(ERR,"searchUnVideo.task:" .. cjson_safe.encode(newTask) )
             count = count + 1
           end
       end
   end
   
end
message.count = count
local body = cjson_safe.encode(message)
ngx.say(body)