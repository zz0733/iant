local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_table = require "util.table"
local channel_dao = require "dao.channel_dao"
local content_dao = require "dao.content_dao"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()
local channel = args.channel

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT
local accepts = { 
    latest = 1, 
    hotest = 1, 
    score = 1,
    comment = 1,
    classical = 1
}

local message = {}
message.code = 200
if not channel or not accepts[channel] then
	message.status = 400
	message.message = "bad channel[" .. channel .."]"
	ngx.say(cjson_safe.encode(message))
	return
end
function toElements( hits, code_map)
	if not hits or not code_map then
		return
	end
	local elements = {}
	for i,v in ipairs(hits) do
		local code = v._source.article.code
        local cele = code_map[code]
        local ele = {}
        ele.code = v._id
        ele.title = v._source.article.title
        if cele then
	       ele.index = cele.index
        end
        table.insert(elements, ele)
	end
    return elements
end
function build_channel(channel, code_set, code_map)
	local fields = {"article"}
	local from = 0
    local size = #code_set
	local resp, status = content_dao:query_by_codes(from,size,code_set,fields);
	local str_resp = cjson_safe.encode(hits_arr)
	if not resp then
		return
	end
	local elements = toElements(resp.hits.hits, code_map)
	local str_resp = cjson_safe.encode(elements)
	-- log(ERR,"elements:" .. str_resp )

	if elements and #elements > 0 then
	        local channel_obj = {}
	        channel_obj.id = channel
	        channel_obj.source = "maker"
	        channel_obj.elements = elements
	        channel_obj.total = #elements
	        channel_obj.ctime = ngx.time()
	        channel_obj.utime = channel_obj.ctime
			local str_resp = cjson_safe.encode(channel_obj)
			log(ERR,"channel_obj:" .. str_resp )
	        local docs = {}
	        table.insert(docs, channel_obj)
	        channel_dao:update_docs(docs)
	end
end
if "hotest" == channel then
	local params = {}
	table.insert(params, { media = "movie", channel = "热门" })
	table.insert(params, { media = "tv", channel = "热门" })
	local hits_arr = {}
	local fields = {"timeby","channel","media","total","elements"}
	for _,v in ipairs(params) do
		local resp, status = channel_dao:query_lastest_by_channel(v.media, v.channel, fields)
		log(ERR,"hits_arr.resp:" .. cjson_safe.encode(resp))
		if resp and resp.hits.hits[1] then
			table.insert(hits_arr, resp.hits.hits[1])
		end
	end
	local code_map = {}
	local code_set = {}
	local batch_size = 100
	for _,doc in ipairs(hits_arr) do
		if doc._source and doc._source.elements then
			for _,v in ipairs(doc._source.elements) do
				code_map[v.code] = v
				table.insert(code_set, v.code)
				if #code_set >= batch_size then
					build_channel(channel, code_set, code_map)
					code_set = {}
				end
			end
		end
	end
	if code_set and #code_set > 0 then
		build_channel(channel, code_set, code_map)
	end
end