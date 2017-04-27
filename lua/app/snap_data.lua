local util_request = require "util.request"
local data = util_request.post_body(ngx.req)
local resp, _ = ngx.location.capture_multi{
      {"/api/collect.json", { args = { method = "insert" }, body = data }},
      {"/api/task.json", { args = { method = "nexts" }, body = data }}
}
ngx.say(resp.body)