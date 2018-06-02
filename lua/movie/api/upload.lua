local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local link_dao = require("dao.link_dao")

local post_body = util_request.post_body(ngx.req)
-- log(ERR,"params:" ..tostring(post_body))
local message = {}
message.code = 200
if  post_body then
	local params = cjson_safe.decode(post_body)
	if params then
		-- upload webrtc torrent source
		params.id = params.id or util_movie.makeId(params.link)
		if params.id and params.title then
			params.lid = params.id
			params.webRTC = params.webRTC or 1
			params.status = params.status or 0
			log(ERR,"params:" .. cjson_safe.encode(params))
			local ids = {}
			table.insert(ids, params.id)
			local resp = link_dao:query_by_ids(ids)
			local bSave = true
			if resp and resp.hits and resp.hits.hits and resp.hits.hits[1] then
			   	 local hasOne = resp.hits.hits[1]._source
			   	 if hasOne.status and hasOne.status ~= 0 then
			   	 	bSave = false
			   	 end
			end
			local ret = { save = bSave, id =  params.id}
			if bSave then
			   local saveDocs = {}
			   table.insert(saveDocs, params)
			   local sresp, status = link_dao:update_docs(saveDocs)
               message.code = status
               if not sresp then
				    message.code = 500
				    message.error = status
				end
			end
			message.data = ret
	    else
	    	message.error = 'miss id or title'
	    end
		
	else
	   message.error = "error post params"
	   message.code = 400
	end
else
	message.error = "error post params"
	message.code = 400
end
local body = cjson_safe.encode(message)
ngx.say(body)