local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_context = require "util.context"
local task_dao = require "dao.task_dao"
local meta_dao = require "dao.meta_dao"

local ssdb_task = require "ssdb.task"
local ssdb_vmeta= require "ssdb.vmeta"


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local from_date = tonumber(args.from) or (ngx.time() - 2*60*60)
local task_level = tonumber(args.level) or 1
local size = tonumber(args.size) or (100)
-- 在线视频
local media = 1
-- "豆瓣": 0,
-- "爱奇艺": 1,
-- "腾讯视频": 2,
-- "优酷视频": 3
local source_arr = {}
table.insert(source_arr, 1)
table.insert(source_arr, 2)
-- table.insert(source_arr, 3)
local source_type_dict = {
  -- [1] = "odflv-video-cache",
  [1] = "common-video-cache",
  [2] = "common-video-cache",
  [3] = ""
}
local must_array = {}
table.insert(must_array,{range = { utime = { gte = fromDate } }})
table.insert(must_array,{match = { media = media }})
if args.albumId then
  table.insert(must_array,{match = { albumId = args.albumId }})
end
if not util_table.is_empty_table(source_arr) then
   table.insert(must_array,{terms = { source = source_arr }})
end
if not (args.albumId and args.force) then
 local cstatus_video_arr = {}
 table.insert(cstatus_video_arr,0)
 table.insert(cstatus_video_arr,1)
 table.insert(must_array,{terms = { cstatus = cstatus_video_arr }})
end

-- local must_nots = {}
-- -- 获取视频资源所有取值，新增cstatus需改动,cstatus=2
-- local cstatus_video_arr = {}
-- table.insert(cstatus_video_arr,2)
-- table.insert(cstatus_video_arr,3)
-- table.insert(cstatus_video_arr,6)
-- table.insert(cstatus_video_arr,7)
-- table.insert(must_nots,{terms = { cstatus = cstatus_video_arr }})

local body = {
    size = size,
    query = {
        bool = {
            must = must_array
        }
    }
}
local resp, status = meta_dao:search(body)
-- log(ERR,"searchUnVideo:" .. cjson_safe.encode(resp) .. ",status:" .. status)
local count = 0
if resp and resp.hits and resp.hits.hits then
   local hits = resp.hits.hits
   for mi,mv in ipairs(hits) do
       -- log(ERR,"meta_dao:get:" .. mv._id .. ",meta:" .. cjson_safe.encode(mv))
       local vmetaRet, err = meta_dao:get(mv._id)
       if err then
          log(ERR,"getMetaErr:" .. mv._id .. ",cause:" .. cjson_safe.encode(err))
       elseif vmetaRet and vmetaRet.url and not string.contains(vmetaRet.url,"/cover/undefined/") then
           local destType = source_type_dict[vmetaRet.source]
           if not destType or destType == "" then
              log(ERR,"ignoreUnkownType,id:" .. mv._id .. ",meta:" .. cjson_safe.encode(mv))
           else

             local newTask = {}
             newTask.type = destType
             newTask.url = vmetaRet.url
             newTask.level = task_level
             local params = {}
             params.metaId = mv._id
             newTask.params = params
             local tresp, tstatus = ssdb_task:qpush( newTask.level, newTask )
             log(ERR,"searchUnVideo.task:" .. cjson_safe.encode(newTask) )
             count = count + 1
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