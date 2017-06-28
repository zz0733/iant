local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

require("timer.load_version")

require("handler.load_handler").load_types()
require("timer.load_task")
require("timer.handle_collect")


