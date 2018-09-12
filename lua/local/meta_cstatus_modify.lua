local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local util_movie = require "util.movie"
local util_context = require "util.context"
local task_dao = require "dao.task_dao"
local meta_dao = require "dao.meta_dao"
local ssdb_vmeta = require "ssdb.vmeta"

local bit = require("bit") 


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local message = {}
message.code = 200

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local from_date = tonumber(args.from) or (ngx.time() - 2*60*60)
local dest_size = tonumber(args.size) or (10)
-- 在线视频
local must_arr = {}
local cstatus_arr = {}

table.insert(cstatus_arr, 2)
table.insert(cstatus_arr, 3)

table.insert(must_arr, { match = { media = 1}})
table.insert(must_arr, { terms = { cstatus = cstatus_arr }})
local body = {
  from = 0,
  size = dest_size,
  query = {
    bool = {
      must = must_arr
    }
  }
}
local resp, status = meta_dao:search(body, true)
-- log(ERR,"searchVideoMeta:" .. cjson_safe.encode(resp) .. ",status:" .. status)
local count = 0
if resp and resp.hits and resp.hits.hits then
   local hits = resp.hits.hits
   for mi,mv in ipairs(hits) do
       local _source = mv._source
       if _source.vmeta and _source.vmeta.url then
         local vmeta = _source.vmeta
          _source.id = mv._id
         if string.match(_source.vmeta.url, "/odflv/api.php") then
            _source.cstatus = bit.bxor(_source.cstatus, 2)
            _source.pstatus = 0
         else
             local vmetaURL = vmeta.url
             local vmetaCode = util_movie.toUnsignHashCode(vmetaURL)
             local copyMeta = {}
             copyMeta.site = vmeta.site
             copyMeta.body = '#EXTM3U\n#EXT-X-STREAM-INF:PROGRAM-ID=1,BANDWIDTH=800000,RESOLUTION=1080x608\n@' .. vmetaCode .. "@"
             copyMeta.prefixs = {}
             table.insert(copyMeta.prefixs, vmetaURL)
             ssdb_vmeta:set(mv._id, copyMeta)
         end
         count = count + 1

         _source.vmeta = nil
         _source._cover = 1
         local modifyArr = {}
         table.insert(modifyArr, _source)
         local str_modify_arr = cjson_safe.encode(modifyArr)
         local tresp, tstatus = meta_dao:save_metas( modifyArr )
         log(ERR,"modifyCStatus.modifyArr:" .. str_modify_arr )
       end
   end
end
message.count = count
local body = cjson_safe.encode(message)
ngx.say(body)