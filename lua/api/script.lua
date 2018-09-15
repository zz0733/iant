local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local script_dao = require "dao.script_dao"

local load_handler = require("handler.load_handler")

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local exptime = 600

local find = ngx.re.find

local shared_dict = ngx.shared.shared_dict

if not method then
	ngx.say('empty method')
	return
end
local type = args.type
if 'insert' == method  then
	local script = util_request.post_body(ngx.req)
	if not type or type == "" then
		local filename, err = ngx.re.match(script, "filename=[\"]([\\-0-9a-zA-Z]+).js")
		if filename then
			type = filename[1]
		end
	end
	-- ngx.say('insert_scripts.body,script:' .. script)
	local from, to, err = ngx.re.find(script, "(\r\n\r\n)", "jo")
	script = string.sub(script, to)
	from, to, err = ngx.re.find(script, "(\r\n[\\-]+[0-9a-z]+[\\-]+\r\n)", "jo")
	if not err and from > 0 then
		script = string.sub(script,0, from)
	end

	local script_doc = {}
	-- script_doc.id = type
	script_doc.type = type
	script_doc.script = script
	script_doc.delete = 0
	local input_docs = {}
	table.insert(input_docs, script_doc)
	local resp, status = script_dao:insert_scripts(input_docs)
	local message = {}

    if resp then
       -- load_handler.load_types()
       message.data = resp
       message.code = 200
	else
	   message.code = 500
	   message.error = status
	end
	local body = cjson_safe.encode(message)
    ngx.say(body)
elseif "del" == method then
	local input_docs = {}
	local doc = {}
	doc.id = type
	doc.delete = 1
	input_docs[1] = doc
	local resp, status = script_dao:update_scripts(input_docs )
	local message = {}
    message.data = resp
    message.code = 200
    if not resp then
	   message.code = 500
	   message.error = status
	else
	 	load_handler.load_types()
	end
	local body = cjson_safe.encode(message)
    ngx.say(body)
elseif "get" == method then
    local value, err = script_dao:search_by_type(type)
    local message = {}

    if err then
        message.code = 500
        message.error = err
    else
        message.data = cjson_safe.encode(value)
        message.code = 200
    end
	local body = cjson_safe.encode(message)
    ngx.say(body)
end