local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local script_dao = require "dao.script_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local method = args.method

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local exptime = 600

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
	ngx.say('insert_scripts.body,script:' .. script)
	local from, to, err = ngx.re.find(script, "(\r\n\r\n)", "jo")
	script = string.sub(script, to)
	from, to, err = ngx.re.find(script, "(\r\n[\\-]+[0-9a-z]+[\\-]+\r\n)", "jo")
	if not err and from > 0 then
		script = string.sub(script,0, from)
	end

	local script_obj = {}
	script_obj.type = type
	script_obj.script = script
	local scripts = {}
	scripts[#scripts + 1] = script_obj
	local resp, status = script_dao.insert_scripts(scripts )
	local message = {}
    message.status = status
	if resp then
		local cache = {}
		cache.script = script
		cache.utime = ngx.time
		local script_val = cjson_safe.encode(cache)
		-- seconds
		local ok, err = shared_dict:set(type, script_val, exptime )
		message.error = err
        if err then
        	log(CRIT,"script,update[" .. type .. "],cause:",err)
    	else
    		log(ERR,"script,update[" .. type .. "],expire:" .. exptime .. "s")
        end
	end
	local body = cjson_safe.encode(message)
    ngx.say(body)
elseif "get" == method then
    local value, flags = shared_dict:get(type)
    if not value then
    	local resp, err = script_dao.search_by_type(type)
    	if resp then
    		local hits  = resp.hits.hits
    		for _,v in ipairs(hits) do
	    		local script_obj = v._source
	    		-- local cache = {}
				-- cache.script = script_obj.script
				-- cache.utime = ngx.time
	    		value = cjson_safe.encode(script_obj)
			    ngx.say("cjsdsds:",value)
	    		-- local ok, err = shared_dict:set(type, value, exptime )
    		end
    		
    	end
    end
    ngx.say(value)
end