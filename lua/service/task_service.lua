local cjson_safe = require "cjson.safe"
local util_table = require "util.table"
local task_dao = require "dao.task_dao"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local string_match = string.match

local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

function _M:create_task_by_links( hits, level, retryCount )
	local task_docs = {}
	local lid_map = {}
	if hits then
		 retryCount = retryCount or 3
         for _,lv in ipairs(hits) do
            if not lid_map[lv._id] and string_match(lv._id,"^b") then
                local str_url = lv._source.link
                if not string_match(str_url, "^http") then
                    str_url = "https://pan.baidu.com/s/" .. str_url;
                end
                local task = {}
                task.type = "bdp-link-convert"
                task.url = str_url
                task.level = level or 0
                task.status = 0
                task.params = {tid = target_id,lid = lv._id, retry = { total = retryCount } }
                table.insert(task_docs, task)
                lid_map[lv._id] = 1
            end
         end
     end
     local resp, status =  task_dao:insert_tasks(task_docs)
     return resp, status, #task_docs
end

return _M