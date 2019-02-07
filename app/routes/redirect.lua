local cjson_safe = require("cjson.safe")
local lor = require("lor.index")

local redirectRouter = lor:Router()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


redirectRouter:get("/detail/:topic_id.html", function(req, res, next)
    local topic_id = req.params.topic_id
    res:redirect("/topic/" .. topic_id .. "/view?mediaId=2")
end)


return redirectRouter