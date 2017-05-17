local content_dao = require("dao.content_dao")
local link_dao = require("dao.link_dao")
local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local decode_base64 = ngx.decode_base64


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 6)
_M._VERSION = '0.01'
-- The index
_M.active_cmds = { content=1, logger=1, link=1}

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
   if not _M.active_cmds[cmd] then
   	 return
   end
   if cmd == "content" then
       return _M.content(...)
   elseif cmd == "link" then
   	 return _M.link(...)
   end
end


_M.content = function(id, source)
   if not source then
   	 return nil, "source is nil"
   elseif not source.data then
   	 return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   -- log(ERR,"handleXXXXXXX[content],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
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
   -- log(ERR,"handleXXXXXXX[content],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return content_dao:bulk_docs(docs)
end

_M.link = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   local str_date = decode_base64(source.data)
   local data = cjson_safe.decode(str_date)
   log(ERR,"handleXXXXXXX[content],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
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
   log(ERR,"handleXXXXXXX[link],id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return link_dao:bulk_docs(docs)
end

local commands = {}
for cmd,_ in pairs(_M.active_cmds) do
	commands[#commands + 1] = cmd
	-- _M[cmd] = function ( self, ... )
	-- 	return do_command(self,cmd, ...)
	-- end
end
_M.commands = commands
return _M