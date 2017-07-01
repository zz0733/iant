local wxcrypt = require "util.wxcrypt"

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local args = ngx.req.get_uri_args()

if wxcrypt.verify(args.timestamp, args.nonce, args.echostr, args.signature ) then
   -- ngx.exit(ngx.HTTP_FORBIDDEN)
   log(ERR,"verify fail")
else
   log(ERR,"verify success")
end

