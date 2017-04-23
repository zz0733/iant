local args = ngx.req.get_uri_args()
local cjson_safe = require "cjson.safe"
local resp = ngx.location.capture(
                "/api/script.json", {args={method = "get", type = args.type }}
)
ngx.say(resp.body)