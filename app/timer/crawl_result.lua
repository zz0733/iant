if not (0 == ngx.worker.id()) then
    return
end

local cjson_safe = require("cjson.safe")
local util_table = require("app.libs.util.table")
local handlers = require("app.libs.handler.handlers")
local ssdb_result = require "app.libs.ssdb.result"

local max_delay = 60
local min_delay = 5 -- in seconds

local LIMIT_SIZE = 2
local MAX_GC_MEM = 6000

local log = ngx.log
local ERR = ngx.ERR

local _M = require("app.timer.worker"):new({
    name = "crawl_result",
    loop = true,
    delay = min_delay, -- in seconds
})
_M._VERSION = '0.01'

function _M:can_run()
    local gcMem = gcinfo()
    return gcMem < MAX_GC_MEM
end

function _M:run()
    local gcMem = gcinfo()
    local start = ngx.now()
    local resultArr = ssdb_result:qpop(LIMIT_SIZE)
    for _, ret in ipairs(resultArr) do
        -- log(ERR,"handle_result,ret:" .. cjson_safe.encode(ret) )
        if not util_table.isNull(ret) and not util_table.isNull(ret.data) then
            local task = ret.task
            local data = ret.data
            local cur_handlers = data.handlers
            task.id = task.id or ("0" .. task.type)
            for _, cmd in ipairs(cur_handlers) do
                local resp, estatus = handlers.execute(cmd, task.id, ret)
                if estatus ~= 200 then
                    log(ERR, "handle_" .. cmd .. ",id:" .. tostring(task.id) .. ",type:" .. tostring(task.type)
                            .. ",status:" .. cjson_safe.encode(estatus) .. ",resp:" .. cjson_safe.encode(resp))
                end
            end
        end
    end
    if #resultArr < 1 then
        self.delay = self.delay + 1
        self.delay = math.min(self.delay, max_delay)
    else
        self.delay = min_delay
    end
    ngx.update_time()
    local cost = (ngx.now() - start)
    cost = tonumber(string.format("%.3f", cost))
    log(ERR, "crawl_result,limit:" .. LIMIT_SIZE .. ",data:" .. #resultArr .. ",cost:" .. cost .. ",gc:" .. gcMem)
end

return _M