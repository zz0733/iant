local util_request = require "util.request"
local data = util_request.post_body(ngx.req)
local resp = ngx.location.capture(
                "/api/collect.json", { 
                   args = {method = "insert" },
                   body = data
                }
)
ngx.say(resp.body)