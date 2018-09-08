local content_dao = require("dao.content_dao")
local link_dao = require("dao.link_dao")
local channel_dao = require "dao.channel_dao"
local meta_dao = require "dao.meta_dao"

local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local decode_base64 = ngx.decode_base64


local _M = util_table.new_table(0, 5)
_M._VERSION = '0.01'
-- The index


local CHECK_FIELDS = {"evaluates","names","genres","actors","directors","images","tags","digests","contents","issueds"}

local ensure_doc = function ( doc )
  if not doc then
    return 
  end
  for _,key in ipairs(CHECK_FIELDS) do
    local val_obj = doc[key]
    if val_obj and util_table.is_empty_table(val_obj) then
      doc[key] = cjson_safe.empty_array
    end
  end
end

local keepFields = {"_doc_cmd","id","title","link","secret","space","directors","ctime","status"}
local makeLinkDoc = function ( doc )
  local newDoc = {}
  for i = 1, #keepFields do
      local fld = keepFields[i]
      newDoc[fld] = doc[fld]
  end
  newDoc.lid = newDoc.id
  -- 清理标题中的广告信息和冗余信息
  local link_title = newDoc.title
  if link_title then
    link_title = ngx.re.gsub(link_title, "(www\\.[a-z0-9\\.\\-]+)|([a-z0-9\\.\\-]+?\\.com)|([a-z0-9\\.\\-]+?\\.net)", "","ijou")
    link_title = ngx.re.gsub(link_title, "(电影天堂|久久影视|阳光影视|阳光电影|人人影视|外链影视|笨笨影视|390影视|转角影视|微博@影视李易疯|66影视|高清影视交流|大白影视|听风影视|BD影视分享|影视后花园|BD影视|新浪微博@笨笨高清影视|笨笨高清影视)", "","ijou")
    link_title = ngx.re.gsub(link_title, "(小调网|阳光电影|寻梦网)", "","ijou")
    link_title = ngx.re.gsub(link_title, "[\\[【][%W]*[】\\]]", "","ijou")
    newDoc.title = link_title
 end
  local code = doc.code
   if code and string.startsWith(code, 'imdbtt') then
       code = ngx.re.sub(code, "imdbtt", "")
       newDoc.imdb = code
   elseif code and string.startsWith(code, 'imdb') then
       code = ngx.re.sub(code, "imdb", "")
       newDoc.imdb = code
   end
   return newDoc
end

_M.execute = function (cmd, ... )
  local do_cmd = _M[cmd]
   if not do_cmd then
   	 return
   end
   return do_cmd( ... )
end


_M.content = function(id, source)
   if not source then
   	 return nil, "source is nil"
   elseif not source.data then
   	 return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   log(ERR,"handle[content],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
   if not data then
   	 return nil, "es[source.data] is not json"
   elseif not data.data then
   	 return nil, "content[data] is nil"
   elseif not data.data.docs  then
	 return nil, "content[data].docs is nil"
   end
   local docs = data.data.docs
   local type = source.type
   for _,v in ipairs(docs) do
   	  if not v.id then
   	  	v.id = tostring(type) .. tostring(id)
   	  end
      ensure_doc(v)
   end
   log(ERR,"handle[content],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return content_dao:save_docs(docs)
end


_M.meta = function(id, source)
   if not source then
     return nil, "source is nil"
   elseif not source.data then
     return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   log(ERR,"handle[meta],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
   if not data then
     return nil, "es[source.data] is not json"
   elseif not data.data then
     return nil, "content[data] is nil"
   end
   local docs = data.data
   local type = source.type
   for _,v in ipairs(docs) do
      if not v.id then
        v.id = tostring(type) .. tostring(id)
      end
      ensure_doc(v)
   end
   local resp, status = meta_dao:save_metas(docs)
   log(ERR,"handle[meta],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs) )
   log(ERR,"handle[meta],id:" .. id .. ",resp:" .. cjson_safe.encode(resp) .. ",status:" .. status)
   return resp, status
end


_M.link = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   log(ERR,"handle[link],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
   if not data then
       return nil, "es[source.data] is not json"
   elseif not data.data then
       return nil, "content[data] is nil"
   elseif not data.data.docs  then
    return nil, "content[data].docs is nil"
   end
   local docs = data.data.docs
   local type = source.type
   local newDocs = {}
   for _,v in ipairs(docs) do
        if not v.id then
         v.id = tostring(type) .. tostring(id)
        end
        -- 只保留主要字段,减少ES空间的占用。
        local newDoc = makeLinkDoc(v)
        ensure_doc(newDoc)
        table.insert(newDocs,newDoc)
   end
   log(ERR,"handle[link],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return link_dao:bulk_docs(newDocs)
end

_M.channel = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   if not data then
       return nil, "es[source.data] is not json"
   elseif not data.data then
       return nil, "content[data] is nil"
   elseif not data.data.docs  then
    return nil, "content[data].docs is nil"
   end
   local docs = data.data.docs
   local type = source.type
   for _,v in ipairs(docs) do
        if not v.id then
         v.id = tostring(type) .. tostring(id)
        end
   end
   log(ERR,"handle[channel],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return channel_dao:save_docs(docs)
end

_M.digest = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   if not data then
       return nil, "es[source.data] is not json"
   elseif not data.data then
       return nil, "content[data] is nil"
   end
   local oDoc = data.data
   log(ERR,"handle[digest],id:" .. id )
   return meta_dao:corpDigest(oDoc)
end



local commands = {}
commands[#commands + 1] = "link"
commands[#commands + 1] = "content"
commands[#commands + 1] = "channel"
commands[#commands + 1] = "meta"
commands[#commands + 1] = "digest"
_M.commands = commands

return _M