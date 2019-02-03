local context = require("app.libs.util.context")

ngx.log(ngx.ERR, "SNAP_ENV:" .. tostring(context.SNAP_ENV))
if "DEV" ~= context.SNAP_ENV then
    require("app.timer.result_timer")
end
require("app.timer.load_version")


