local wxcrypt = require "util.wxcrypt"

local log = ngx.log
local ERR = ngx.ERR

local args = ngx.req.get_uri_args()
local signature = wxcrypt.signature(args.timestamp, args.nonce, args.echostr)
if args.signature ~=  signature then
   log(ERR,"verify fail")
   ngx.exit(ngx.HTTP_FORBIDDEN)
else 
	log(ERR,"verify success")
end