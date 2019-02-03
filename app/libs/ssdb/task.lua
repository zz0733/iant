local cjson_safe = require "cjson.safe"
local util_table = require "app.libs.util.table"
local ssdb_client = require "app.libs.ssdb.client"

local uuid = require 'resty.jit-uuid'
uuid.seed() --- > automatic seeding with os.time(), LuaSocket, or ngx.time()


local _M = {}
_M._VERSION = '0.02'

local KEY_PREFIX = "T_"

local levelArr = {}
table.insert(levelArr, 2)
table.insert(levelArr, 1)
table.insert(levelArr, 0)

local CAN_MIXED_COUNT = 10
local RANDOM_MIXED_INDEX = math.modf(CAN_MIXED_COUNT / 2) - 1

function _M:toSSDBKey(key)
    return KEY_PREFIX .. tostring(key)
end

function _M:toBean(sVal)
    if not sVal then
        return nil
    end
    local jsonVal = cjson_safe.decode(sVal)
    if jsonVal and not util_table.is_table(jsonVal) then
        jsonVal = nil
    end
    return jsonVal
end


function _M:taskUUID()
    local taskId = ngx.re.gsub(uuid(), "-", "")
    taskId = string.sub(taskId, -8)
    return taskId
end

function _M:qpush(level, ...)
    level = level or 1
    local tasks = { ... }
    local mixArr = {}
    local qpushArr = {}
    for ti, task_val in ipairs(tasks) do
        if util_table.is_table(task_val) then
            if task_val.params and util_table.is_table(task_val.params) then
                task_val.params = cjson_safe.encode(task_val.params)
            end
            task_val.id = task_val.id or self:taskUUID()
            task_val = cjson_safe.encode(task_val)
            tasks[ti] = task_val
        end
        -- mixed task type
        if math.random(5) == 5 then
            table.insert(mixArr, tasks[ti])
        else
            table.insert(qpushArr, tasks[ti])
        end
    end
    local ret = "empty", err
    if #qpushArr > 0 then
        local client = ssdb_client:open();
        ret, err = client:qpush_back(self:toSSDBKey(level), unpack(qpushArr))
        ssdb_client:close(client)
    end
    for _, mtask in ipairs(mixArr) do
        ret, err = self:qretry(level, mtask)
    end
    return ret, err
end

function _M:qretry(level, task_val)
    level = level or 1
    if util_table.is_table(task_val) then
        if task_val.params and util_table.is_table(task_val.params) then
            task_val.params = cjson_safe.encode(task_val.params)
        end
        task_val = cjson_safe.encode(task_val)
    end
    local ssdbKey = self:toSSDBKey(level)
    local client = ssdb_client:open();
    local count = client:qsize(ssdbKey)
    local ret, err
    if count > CAN_MIXED_COUNT then
        local index = math.modf(count / 2) + math.random(RANDOM_MIXED_INDEX)
        local indexVal, _ = client:qget(ssdbKey, index)
        ret, err = client:qset(ssdbKey, index, task_val)
        if indexVal then
            ret, err = client:qpush_front(ssdbKey, task_val)
        end
    else
        ret, err = client:qpush_back(ssdbKey, task_val)
    end
    ssdb_client:close(client)
    return ret, err
end

function _M:qpop(size)
    size = size or 1
    local client = ssdb_client:open();
    local assignArr = {}
    local count = size
    for _, level in ipairs(levelArr) do
        local ssdbKey = self:toSSDBKey(level)
        local ret, err = client:qpop_front(ssdbKey, count)
        if not util_table.isNull(ret) then
            for _, tv in ipairs(ret) do
                local tvObj = self:toBean(tv)
                if not tvObj.id then
                    for _, task in ipairs(tvObj) do
                        if type(task) == "string" then
                            task = self:toBean(task)
                        end
                        table.insert(assignArr, task)
                    end
                else
                    table.insert(assignArr, tvObj)
                end
            end
        end
        count = size - #assignArr
        if count < 1 then
            break
        end
    end
    ssdb_client:close(client)
    -- log(ERR,"assignArr:" .. cjson_safe.encode(assignArr))
    return assignArr
end

return _M