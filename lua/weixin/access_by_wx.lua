local wxcrypt = require "util.wxcrypt"

local log = ngx.log
local ERR = ngx.ERR

local args = ngx.req.get_uri_args()
args.token = "wxMao"
args.timestamp = "1498886832"
args.nonce = "1306994185"
args.echostr = "6187842269661870075"
args.signature = "2471ca8c2df785c9afe22a38174778639c14278d"
local signature = wxcrypt.signature(args.timestamp, args.nonce, args.echostr)
if args.signature ~=  signature then
   -- ngx.exit(ngx.HTTP_FORBIDDEN)
   log(ERR,"verify fail")
else 
	log(ERR,"verify success")
end


-- 1306994185=1498886832=6187842269661870075=wxMao

-- 1306994185=1498886832=6187842269661870075=wxMao