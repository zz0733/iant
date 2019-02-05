local _M = {}
_M._VERSION = '0.01'
local timer_at = ngx.timer.at
local log = ngx.log
local ERR = ngx.ERR

function _M:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function _M:trigger(premature)
    if premature then
        log(ERR, "trigger timer1")
        return
    end
    log(ERR, "trigger timer2")
    if self:can_run() then
        self:run()
    end
    self:do_loop()
end

function _M:run()
    log(ERR, "run timer")
end

function _M:can_run()
    return true
end

function _M:do_loop()
    if not self.loop then
        return
    end
    local target = self
    local _, err = timer_at(self.delay, function()
        target:trigger()
    end)
    local name = self.name or "unknown"
    if err then
        log(ERR, "failed to trigger timer[" .. tostring(name) .. "],cause:", err)
    else
        log(ERR, "success to trigger timer[" .. tostring(name) .. "],delay:" .. tostring(self.delay))
    end
end

return _M