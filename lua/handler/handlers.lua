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
   log(ERR,"handle[meta],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return meta_dao:bulk_docs(docs)
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
   for _,v in ipairs(docs) do
        if not v.id then
         v.id = tostring(type) .. tostring(id)
        end
         ensure_doc(v)
   end
   log(ERR,"handle[link],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return link_dao:bulk_docs(docs)
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


local commands = {}
commands[#commands + 1] = "link"
commands[#commands + 1] = "content"
commands[#commands + 1] = "channel"
commands[#commands + 1] = "meta"
_M.commands = commands

return _M