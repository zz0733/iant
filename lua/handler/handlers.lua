local content_dao = require("dao.content_dao")
local link_dao = require("dao.link_dao")
local channel_dao = require "dao.channel_dao"
local meta_dao = require "dao.meta_dao"
local task_dao = require "dao.task_dao"

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


_M.retry = function(id, source)
   local status = source.status
   local task = source.task
   local taskErr = source.error
   if status ~= 0 then
      return nil, "OK"
   end
   if task and task.params then
        local params_obj = cjson_safe.decode(task.params)
        if params_obj and params_obj.retry then
          local retry_obj = params_obj.retry
          if not util_table.is_table(retry_obj) then
            retry_obj = {}
          end
          local index = retry_obj.index or 0
          local total = retry_obj.total or 3
          if total > 5 then
            total = 5
          end
          if index < total then
            index = index + 1
            params_obj.retry = { index = index, total = total }
            task.params = cjson_safe.encode(params_obj)
            retry_count = retry_count + 1
            local task_val = cjson_safe.encode(task)
            local data_val = cjson_safe.encode(taskErr)
            log(ERR,"retry["..task.id .."](".. index.."),task:" .. task_val..",error:" .. data_val)
            local len, err = shared_dict:lpush(task_queue_key, task_val)
            if err then
                log(CRIT,"shared_dict:lpush:" .. task_val .. ",cause:", err)
                return err, 500
            else
               return "OK", 200
            end
          else
            local data_val = cjson_safe.encode(v)
            log(ERR,"fail.retry["..task.id .."](".. index.."),return:" .. data_val)
          end
        end
    end
    return "OK", 200
    
end

_M.logger = function(id, source)
   local status = source.status
   local task = source.task
   local data = source.data
   local taskErr = source.error
   log(ERR,"handle_logger:" .. tostring(task.type) .. ",id:" .. tostring(task.id) .. ",task:" .. cjson_safe.encode(task))
   if taskErr then
       log(ERR,"handle_logger:" .. tostring(task.type) .. ",id:" .. tostring(task.id) .. ",taskErr:" .. cjson_safe.encode(taskErr))
   else 
       log(ERR,"handle_logger:" .. tostring(task.type) .. ",id:" .. tostring(task.id) .. ",result:" .. cjson_safe.encode(data))
   end
   return "OK", 200
end

_M.nexts = function(id, source)
    local task = source.task
    local data = source.data
    local status = source.status
    if status ~= 1 then
       return "OK", 200
    end
    local nextTasks = data.nextTasks
    if util_table.isNull(nextTasks) then
       return "OK", 200
    end
    local oParams = {}
    if task.params then
         oParams = cjson_safe.decode(task.params)
    end
      -- log(ERR,"task:" .. cjson_safe.encode(task))
    local fields = {"type","url","batch_id","job_id","level"}
    local param_fields = {"_acceptor","_localize"}
    local task_array = {}
    for _,v in ipairs(nextTasks) do
        -- log(ERR,"next:" .. v)
        local new_task = {}
        new_task.status = 0
        new_task.creator = "nexts"
        new_task.parent_id = v.parent_id or task.id
        for _,key in ipairs(fields) do
          new_task[key] = v[key]
          v[key] = nil
          if not new_task[key] then
            new_task[key] = task[key]
          end
        end
        for _,pkey in ipairs(param_fields) do
          if not v[pkey] then
            v[pkey] = oParams[pkey]
          end
        end
        new_task.params = v
        task_array[#task_array + 1] = new_task
    end
    local resp, status = task_dao:insert_tasks(task_array )
    return resp, status
end
_M.content = function(id, source)
   if not source then
   	 return nil, "source is nil"
   elseif not source.data then
   	 return nil, "source.data is nil"
   end
   -- local str_date = decode_base64(source.data)
   -- local data = cjson_safe.decode(str_date)
   local data = source.data
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
   log(ERR,"handle_content,id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return content_dao:save_docs(docs)
end


_M.meta = function(id, source)
   if not source then
     return nil, "source is nil"
   elseif not source.data then
     return nil, "source.data is nil"
   end
   -- local str_date = decode_base64(source.data)
   -- local data = cjson_safe.decode(str_date)
   local data = source.data
   -- log(ERR,"handle[meta],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
   if not data then
     return nil, "es[source.data] is not json"
   elseif not data.data then
     return nil, "content[data] is nil"
   end
   local saveIds = {}
   local docs = data.data
   local type = source.type
   for _,v in ipairs(docs) do
      if not v.id then
        v.id = tostring(type) .. tostring(id)
      end
      ensure_doc(v)
      table.insert(saveIds, v.id)
   end
   log(ERR,"handle_meta,id:" .. id .. ",count:" ..  #saveIds .. ",saveIds:" .. cjson_safe.encode(saveIds) )
   log(ERR,"handle_meta,id:" .. id .. ",docs:" .. cjson_safe.encode(docs) )
   local resp, status = meta_dao:save_metas(docs)
   return resp, status
end


_M.link = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   -- local str_date = decode_base64(source.data)
   -- local data = cjson_safe.decode(str_date)
   -- log(ERR,"handle[link],id:" .. id .. ",content:" ..  cjson_safe.encode(data.data))
   if not source.data then
       return nil, "source.data is not json"
   elseif not source.data.docs  then
       return nil, "source.data.docs is nil"
   end
   local saveIds = {}
   local docs = source.data.docs
   local type = source.task.type
   local newDocs = {}
   for _,v in ipairs(docs) do
        if not v.id then
         v.id = tostring(type) .. tostring(id)
        end
        -- 只保留主要字段,减少ES空间的占用。
        local newDoc = makeLinkDoc(v)
        ensure_doc(newDoc)
        table.insert(newDocs,newDoc)
        table.insert(saveIds, v.id)
   end
   log(ERR,"handle_link:" .. tostring(type) ..",id:" .. id .. ",count:" .. #saveIds .. ",saveIds:" ..  cjson_safe.encode(saveIds))
   return link_dao:bulk_docs(newDocs)
end

_M.channel = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   -- local str_date = decode_base64(source.data)
   -- local data = cjson_safe.decode(str_date)
   local data = source.data
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
   log(ERR,"handle_channel,id:" .. id .. ",docs:" ..  cjson_safe.encode(docs))
   return channel_dao:save_docs(docs)
end

_M.digest = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   elseif not source.data.data then
       return nil, "source.data.data is nil"
   end
   local task = source.task
   local oDoc = source.data.data
   log(ERR,"handle_digest:" .. tostring(task.type) .. ",id:" .. id  .. ",metaId:" .. tostring(oDoc.id))
   return meta_dao:corpDigest(oDoc)
end

_M.vmeta = function(id, source)
   if not source then
       return nil, "source is nil"
   elseif not source.data then
       return nil, "source.data is nil"
   end
   -- local str_date = decode_base64(source.data)
   -- local data = cjson_safe.decode(str_date)
   local data = source.data
   if not data then
       return nil, "es[source.data] is not json"
   elseif not data.data then
       return nil, "content[data] is nil"
   end
   local task = source.task
   local oDoc = data.data
   log(ERR,"handle_vmeta:" .. tostring(task.type) .. ",id:" .. id  .. ",metaId:" .. tostring(oDoc.id))
   return meta_dao:fillVideoMeta(oDoc)
end


-- local commands = {}
-- table.insert(commands, "link")
-- table.insert(commands, "content")
-- table.insert(commands, "channel")
-- table.insert(commands, "meta")
-- table.insert(commands, "digest")
-- table.insert(commands, "vmeta")
-- table.insert(commands, "retry")
-- table.insert(commands, "nexts")
-- _M.commands = commands

return _M