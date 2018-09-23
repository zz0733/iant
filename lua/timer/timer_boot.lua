local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local context = require("util.context")
log(ERR,"SNAP_ENV:" .. tostring(context.SNAP_ENV))
if "DEV" ~= context.SNAP_ENV then
	-- require("handler.load_handler").load_types()
	require("timer.load_task")
	require("timer.handle_result")
end
require("timer.load_version")


