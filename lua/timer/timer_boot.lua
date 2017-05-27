local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

require("timer.load_task")
require("handler.load_handler").load_types()
require("timer.handle_collect")
require("timer.load_version")
require("timer.match_by_content")



