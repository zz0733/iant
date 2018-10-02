local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local link_dao = require "dao.link_dao"
local meta_dao = require "dao.meta_dao"
local context = require "util.context"
local ssdb_piece = require "ssdb.piece"
local util_context = require "util.context"

local decodeURI = ngx.unescape_uri

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local post_body = util_request.post_body(ngx.req)

local message = {}
message.code = 200

local params
if post_body then
  params = cjson_safe.decode(post_body)
end
if not params then
  message.code = 400
  message.error = "bad post params"
  ngx.say(cjson_safe.encode(message))
end
if not params then
  message.status = 400
  message.message = "json param is miss"
  ngx.say(cjson_safe.encode(message))
  return
end

if not params.did or not params.title then
  message.status = 400
  message.message = "did or title is empty"
  ngx.say(cjson_safe.encode(message))
  return
end

local maxCount = 50
if params.from and params.from > maxCount then
  message.data = {}
  message.data.from = params.from
  message.data.hasMore = false
  ngx.say(cjson_safe.encode(message))
  return
end


function byAlbum( params, fields )
    local  size = context.link_page_size
    local  from = params.from or 0
    local must_arr = {}
    table.insert(must_arr, { match = { pstatus = 1 }})
    table.insert(must_arr, { match = { albumId = params.albumId }})
    table.insert(must_arr, { range = { epindex = { gt = params.epindex } }} )

    local sort_arr = {}
    table.insert(sort_arr, { epindex = { order = "desc" }})
    local abody = {
        _source = false,
        from = from,
        size = size,
        sort = sort_arr,
        query = {
            bool = {
               must = must_arr
            }
        }
    }
   local aresp, astatus = meta_dao:search(abody)
   -- log(ERR,"aresp@@@@@@@:" .. cjson_safe.encode(aresp) .. ",size:" .. cjson_safe.encode(size))
   local data = { }
   if aresp and aresp.hits  then
      data.hits = {}
      for _, metaDoc in ipairs(aresp.hits.hits) do
         local ret = meta_dao:get(metaDoc._id)
         if ret then
           local metaObj = {}
           metaObj._id = metaDoc._id
           metaObj._source = {}
           local _source = metaObj._source
           _source.title = ret.title
           _source.space = ret.space
           _source.ctime = ret.ctime
           _source.media = ret.media
           _source.albumId = ret.albumId
           table.insert(data.hits, metaObj)
         end
      end
      if #aresp.hits.hits < size then
        data.hasMore = false
      else 
        data.from = from + size
        data.hasMore = true
      end
   else
     data.hasMore = false
   end
   return data, astatus
end


function byMatch( params, fields )
   local  size = context.link_page_size
   local  from = params.from or 0
   local aresp, astatus = link_dao:query_by_target(params.did, from, size, fields)
   local data = {}
   if aresp and aresp.hits  then
      data = aresp.hits
      data.hasMore = true
      if #aresp.hits.hits < size then
        data.hasMore = false
      else 
        data.from = from + size
      end
   else
      data.hasMore = false
   end
   return data, astatus
end

function bySimilar( params, fields )
    local  size = context.link_page_size
    local  from = params.from or 0

    local must_arr = {}
    table.insert(must_arr, { match = { title = params.title }})

    local sort_arr = {}
    table.insert(sort_arr, { ctime = { order = "desc" }})
    table.insert(sort_arr, { _score = { order = "desc" }})
    local body = {
      from = from,
      size = size,
      sort = sort_arr,
      min_score = 15,
      query = {
         function_score = {
            query = {
              bool = {
                must = must_arr,
                must_not = {
                      match = { status = -1 }
                }
              }
            },
            script_score = {
               script = { inline = "Math.floor(_score)" }
            }
         }
      }
    }
   local aresp, astatus = link_dao:search(body)
   local data = {}
   if aresp and aresp.hits  then
      data = aresp.hits
      data.hasMore = true
      if #aresp.hits.hits < size then
        data.hasMore = false
      else 
        data.from = from + size
      end
   else 
     data.hasMore = false
   end
   return data, astatus
end

local wayDict = {}
table.insert(wayDict, byAlbum)
table.insert(wayDict, byMatch)
table.insert(wayDict, bySimilar)

local way = nil
if util_table.isNull(params.way) then
  if not util_table.isNull(params.albumId) and not util_table.isNull(params.epindex) then
    way = 1
  else
    way = 2
  end
else
  way = params.way
end

local wayMethod = wayDict[way]
if wayMethod then
   local  fields = {"title","space","ctime","issueds"}
   local data, status = wayMethod(params, fields)
   if data.hasMore then
      data.way = way
   elseif way < 3 then
      data.way = way + 1
      data.from = 0
      data.hasMore = true
   else
      data.hasMore = false
   end
   if data.from and data.from > maxCount then
      data.hasMore = false
   end
   if data.hits and util_table.is_empty_table(data.hits) then
      data.hits = cjson_safe.empty_array
   end
   message.data = data
   if status ~= 200 then
      message.code = 500
      message.error = status
   end
else
  message.data = {}
  message.data.hasMore = false
end

ngx.say(cjson_safe.encode(message))