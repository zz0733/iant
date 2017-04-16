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
-- ngx.say('method:' .. method)
local data = util_request.post_body(ngx.req)
-- local params = cjson_safe.encode(args)
-- local body = cjson_safe.encode(data)
local body_json = cjson_safe.decode(data)


-- ngx.say('params:' , params)
-- ngx.say('data:' , body_json.a)
-- ngx.say('req_method:' .. req_method)
-- ngx.say('body:' .. type(body))
-- ngx.say('body:' .. body)


if 'insert' == method  then
	local resp, status = task_dao.insert_tasks(es_index, es_type , body_json )
	local message = {}
    message.data = resp
    message.status = status
    local body = cjson_safe.encode(message)
    ngx.say(body)
elseif 'getmore' == method then
    local val, err = shared_dict:rpop(task_queue_key)
    local message = {}
    message.data = val
    message.error = err
    local body = cjson_safe.encode(message)
    ngx.say(body)
elseif 'load' == method then
	ngx.say('delete_by_ids.body:')
	local resp, status = task_dao.load_by_level_status(es_index, es_type , body_json )
	local message = {}
    message.data = resp
    message.status = status
    local body = cjson_safe.encode(message)
    ngx.say(body)
end