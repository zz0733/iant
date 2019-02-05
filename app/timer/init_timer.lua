local context = require("app.libs.util.context")
context.version(ngx.time())
ngx.log(ngx.ERR, "SNAP_ENV:" .. tostring(context.SNAP_ENV))
if "DEV" ~= context.SNAP_ENV then
    require("app.timer.crawl_result"):do_loop()
    --    require("app.timer.channel_newest"):do_loop()
end
