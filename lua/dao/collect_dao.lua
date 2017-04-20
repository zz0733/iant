local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"

local es_index = "collect"
local es_type = "table"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'


local client_utils = require("util.client_utils")
local client = client_utils.client()


function _M.check_inserts(collects ) 
	if not collects or not util_table.is_array(collects) then
		return false
	end
	return true
end

function table.removeKey(t, k)
	local i = 0
	local keys, values = {},{}
	for k,v in pairs(t) do
		i = i + 1
		keys[i] = k
		values[i] = v
	end
 
	while i>0 do
		if keys[i] == k then
			table.remove(keys, i)
			table.remove(values, i)
			break
		end
		i = i - 1
	end
 
	local a = {}
	for i = 1,#keys do
		a[keys[i]] = values[i]
	end
 
	return a
end

function _M.inserts(collects )
	if not _M.check_inserts(collects ) then
		return
	end
	local es_body = {}
	for _,v in ipairs(collects) do
		local task = v.task
	    local data = v.data
	    local status = v.status
	    if task and  data and status == 1 then
			es_body[#es_body + 1] = {
		      index = {
		        ["_type"] = es_type,
		        ["_id"] = task.id
		      }
		    }
		    local collect_obj = {}
		    collect_obj.type = task.type

			--  can not use ipairs,iterator by pairs
			--  table.remove(task,index) not work
		    task.id = nil
		    task.type = nil
		    
		    collect_obj.task = cjson_safe.encode(task)
		    collect_obj.data = cjson_safe.encode(data)
	    	collect_obj.create_time = ngx.time()
		    es_body[#es_body + 1] = collect_obj
	    end
	end

	local resp, status = client:bulk{
	  index = es_index,
	  body = es_body
	}
    
	return resp, status
end

return _M

