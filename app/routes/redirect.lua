local lor = require("lor.index")

local redirectRouter = lor:Router()

local to_topic_id = function(uri)
    if not uri then
        return
    end
    local m = ngx.re.match(uri, '/movie/detail/([0-9]{3,})', 'ijo')
    if m then
        return m[1]
    end
end

redirectRouter:get("/detail/:suffix", function(req, res, next)
    local topic_id = to_topic_id(req.path)
    res:redirect("/topic/" .. topic_id .. "/view?mediaId=1")
end)


return redirectRouter