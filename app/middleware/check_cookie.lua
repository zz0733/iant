local uuid = require('resty.jit-uuid')
uuid.seed() --- > automatic seeding with os.time(), LuaSocket, or ngx.time()

local KEY_VISITOR_ID = "visitor"
local create_visit_id = function()
    return ngx.re.gsub(uuid(), "-", "")
end

local function check_cookie()
    return function(req, res, next)
        local visitor_id = req.cookie.get(KEY_VISITOR_ID)
        if not visitor_id then
            local _, err = req.cookie.set({
                key = KEY_VISITOR_ID,
                value = create_visit_id(),
                path = "/",
            })
            if err then
                string.error("initVisitorIdErr,cause", err)
            end
        end
        next()
    end
end

return check_cookie