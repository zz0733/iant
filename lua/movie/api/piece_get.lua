local cjson_safe = require "cjson.safe"
local util_request = require "util.request"
local util_movie = require "util.movie"
local util_context = require "util.context"
local ssdb_piece = require "ssdb.piece"

local req_method = ngx.req.get_method()
local args = ngx.req.get_uri_args()

local decode_base64 = ngx.decode_base64

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local args = ngx.req.get_uri_args()
if not args.start and not (args.start  == 0)then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
local to_infoHash = function ( uri )
    -- /piece/3b23dec44200ff11ec7efdf6a887c026c00d75e1.mp4
	if not uri then
		return
	end
	local m = ngx.re.match(uri, '/piece/([0-9a-zA-Z]{20,})','ijo')
	if m then
		return m[1]
	end
end
local uri = ngx.var.uri
local infoHash = to_infoHash(uri)
if not infoHash or not args.start then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
local start = args.start
local ret, err = ssdb_piece:getValue(infoHash, start)
if not ret then
	return ngx.exit(ngx.HTTP_NOT_FOUND)
end
-- local pieceRaw = decode_base64(ret)
ngx.say(ret)