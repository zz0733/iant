local wxcrypt = require "util.wxcrypt"

local log = ngx.log
local ERR = ngx.ERR

local args = ngx.req.get_uri_args()

if not wxcrypt.verify(args.timestamp, args.nonce, args.echostr, args.signature ) then
   -- ngx.exit(ngx.HTTP_FORBIDDEN)
   log(ERR,"verify fail")
end

