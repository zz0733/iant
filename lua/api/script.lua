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
	-- ngx.say('insert_scripts.body,script:' .. script)
	local from, to, err = ngx.re.find(script, "(\r\n\r\n)", "jo")
	script = string.sub(script, to)
	from, to, err = ngx.re.find(script, "(\r\n[\\-]+[0-9a-z]+[\\-]+\r\n)", "jo")
	if not err and from > 0 then
		script = string.sub(script,0, from)
	end

	local script_obj = {}
	script_obj.type = type
	script_obj.script = script
	script_obj.delete = 0
	local scripts = {}
	scripts[#scripts + 1] = script_obj
	local resp, status = script_dao.insert_scripts(scripts )
	local message = {}
    message.data = resp
    message.code = 200
    if status == 200 then
       function importTypes( script )
    		 -- local from, to, err = ngx.re.find(script, "([0-9]+)", "jo")
    		 local m, err = ngx.re.match(script, "ScriptParser.prototype.getImportScrip","jo")
    		 if m then
    		 	local body = cjson_safe.encode(m)
				ngx.say("match:",body)
			 else
			     ngx.say("match not err",err)
			 end
       end
       importTypes(script)
       shared_dict:delete(type)
	else
	   message.code = 500
	   message.error = status
	end
	local body = cjson_safe.encode(message)
    ngx.say(body)
elseif "get" == method then
    local value, flags = shared_dict:get(type)
    local message = {}
    message.data = value
    message.code = 200
    -- add lock
    if not value then
    	local resp, status = script_dao.search_by_type(type)
    	if resp then
    		local hits  = resp.hits.hits
    		for _,v in ipairs(hits) do
    			local script_obj = v._source
				script_obj.version = ngx.time()
				value = cjson_safe.encode(script_obj)
				
				-- seconds
				log(ERR,"set share dict:" .. type .. ",expire:" .. exptime .. "s")
				local ok, err = shared_dict:set(type, value, exptime )
				if ok then
					message.data = value
				end
				message.error = err
    		end
    	elseif status ~= 200 then
    		--todo
    		message.code = 500
    		message.error = status
    	end
    end
	local body = cjson_safe.encode(message)
    ngx.say(body)
end