local args = ngx.req.get_uri_args()
local resp = ngx.location.capture(
                "/api/task.json", { args={method = "getmore" }}
)
ngx.say(resp.body)