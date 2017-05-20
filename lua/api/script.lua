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
	script_doc.id = type
	script_doc.type = type
	script_doc.script = script
	script_doc.delete = 0
	local input_docs = {}
	input_docs[#input_docs + 1] = script_doc
	local resp, status = script_dao:insert_scripts(input_docs)
	local message = {}
    message.data = resp
    message.code = 200
    if resp then
       shared_dict:delete(type)
       load_handler.load_types()
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
    local value, err = shared_dict:get(type)
    local message = {}
    message.data = value
    message.code = 200
    -- add lock
    -- log(ERR,"shared_dict_script get[" .. type .. "],value:".. tostring(value) ..",cause:",err)
    if not value then
    	local resp, status = script_dao:search_by_type(type)
    	if resp then
    		local hits  = resp.hits.hits

		    string.split = function(s, p)
			    local rt= {}
			    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
			    return rt
			end
			function importTypes(type, script )
		    	 	 local from, to, err = find(script, "ScriptParser.prototype.getImportScripts", "jo")
		    		 if not from or (from < 0) then
		    		 	return
		    		 end
		    		 script = string.sub(script, to)
		    		 from, to, err = find(script, "return", "jo")
		    		 script = string.sub(script, to + 1)
		    		 local m, err = ngx.re.match(script, "[0-9a-zA-Z,-]+","mjo")
		    		 if m then
		    		 	local body = cjson_safe.encode(m[0])
		    		 	-- rm "
		    		 	body = string.sub(body, 2,-2)
			    		local types= string.split(body, ',')
			    		local key = "import:" .. type 
			    		local val = cjson_safe.encode(types)
			    		local ok, err = shared_dict:set(key, val )
			    		log(ERR,"shared_dict_import[" .. key .. "],value:".. val ..",success:" .. tostring(ok))
					 end
	        end
    		-- log(ERR,"hits_type:" .. type .. ",hits:" .. cjson_safe.encode(hits))
    		for _, v in ipairs(hits) do

    			local script_obj = v._source
    			importTypes(type, script_obj.script)

				script_obj.version = ngx.time()
				value = cjson_safe.encode(script_obj)
				
				-- seconds
				local ok, err = shared_dict:set(type, value, exptime )
				log(ERR,"shared_dict_script[" .. type .. "],expire:" .. exptime .. "s,success:" .. tostring(ok))
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