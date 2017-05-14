local elasticsearch = require "elasticsearch"
local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local task_dao = require "dao.task_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local es_index = "task"
local es_type = "table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local shared_dict = ngx.shared.shared_dict
local task_queue_key = "task_queue"

if not method then
	ngx.say('empty method')
	return
end
local data = util_request.post_body(ngx.req)
local body_json = cjson_safe.decode(data)


if 'insert' == method  then
	local resp, status = task_dao.insert_tasks(es_index, es_type , body_json )
	local message = {}
    message.data = resp
    message.code = 200
    if status ~= 200 then
        message.code = 500
        message.error = status
    end
    local body = cjson_safe.encode(message)
    ngx.say(body)
elseif 'retry' == method  then
  local total_count = 0
  local retry_count = 0
  local err_count = 0
  for _,v in ipairs(body_json) do
      local task = v.task
      local status = v.status
      total_count = total_count + 1
      if status == 0 and task and task.params then
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
            index = index + 1
            if index <= total then
              params_obj.retry = { index = index, total = total }
              task.params = cjson_safe.encode(params_obj)
              retry_count = retry_count + 1
              local task_val = cjson_safe.encode(task)
              local data_val = cjson_safe.encode(v.data)
              log(ERR,"retry["..task.id .."](".. index.."),task:" .. task_val..",data:" .. data_val)
              local len, err = shared_dict:lpush(task_queue_key, task_val)
              if err then
                  err_count = err_count + 1
                  log(CRIT,"shared_dict:lpush:" .. task_val .. ",cause:", err)
              end
            else
              local data_val = cjson_safe.encode(v)
              index = index - 1
              log(ERR,"fail.retry["..task.id .."](".. index.."),return:" .. data_val)
            end
          end
          
      end
  end
  local message = {}
  message.data = {err_count = err_count, total_count = total_count, retry_count = retry_count}
  message.code = 200
  local body = cjson_safe.encode(message)
  ngx.say(body)
elseif 'nexts' == method then
    function contains( table, value )
      if table then
        for _,v in ipairs(table) do
            if value == v then
              return true
            end
        end
      end
      return false
    end
    local fields = {"type","url","batch_id","job_id","level"}
    local param_fields = {"_acceptor","_localize"}
    local task_array = {}
    for _,v in ipairs(body_json) do
      local task = v.task
      local data = v.data
      local status = v.status
      if status == 1 and task and data and data.nextTasks and not data.localize and data.handlers then
        local nextTasks = data.nextTasks
        local handlers = data.handlers
        if contains(handlers, "CreateNextTask") then
          local oParams = {}
          if task.params then
             oParams = cjson_safe.decode(task.params)
          end
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
        end

      end
    end
    local resp, status = task_dao.insert_tasks(es_index, es_type , task_array )
    local message = {}
    message.data = resp
    message.code = 200
    if status ~= 200 then
        message.code = 500
        message.error = status
    end
    local body = cjson_safe.encode(message)
    ngx.say(body)
elseif 'getmore' == method then
    local max = 20
    local tasks = {}
    local message = {}
    message.data = tasks
    message.code = 200
    for i = 1, max do
      local val, err = shared_dict:rpop(task_queue_key)
      if not val then
          if err ~= 200 then
              message.error = err
          end
          break
      end
      tasks[#tasks + 1] = val
    end
    if message.error then
        message.code = 500
    end
    local body = cjson_safe.encode(message)
    ngx.say(body)
end