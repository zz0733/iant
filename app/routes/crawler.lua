local pairs = pairs
local ipairs = ipairs

local cjson_safe = require("cjson.safe")
local lor = require("lor.index")
local script_model = require("app.model.script")
local file_util = require("app.libs.util.file")
local util_table = require("app.libs.util.table")
local ssdb_task = require("app.libs.ssdb.task")
local ssdb_version = require("app.libs.ssdb.version")
local ssdb_result = require("app.libs.ssdb.result")

local crawlRouter = lor:Router()

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

-- upload script
crawlRouter:post("/script", function(req, res, next)
    local type = req.query.type
    local path = req.file.path
    local filename = req.file.origin_filename
    local script = file_util.content(path)
    require("os").remove(path)
    if (not type or type == "") and filename then
        type = ngx.re.sub(filename, ".js$", "")
    end

    local script_doc = {}
    -- script_doc.id = type
    script_doc.type = type
    script_doc.script = script
    script_doc.delete = 0
    local input_docs = {}
    table.insert(input_docs, script_doc)
    local resp, status = script_model:insert_scripts(input_docs)
    local message = {}

    if resp then
        -- load_handler.load_types()
        message.data = resp
        message.code = 200
    else
        message.code = 500
        message.error = status
    end
    res:json(message)
end)

crawlRouter:get("/script", function(req, res, next)
    local type = req.query.type
    log(ERR, "type:" .. tostring(type))
    local value, err = script_model:search_by_type(type)
    local message = {}
    if err then
        message.code = 500
        message.error = err
    elseif not value then
        message.code = 404
    else
        message.data = cjson_safe.encode(value)
        message.code = 200
    end
    res:json(message)
end)

crawlRouter:post("/task", function(req, res, next)
    local body = req.body
    local ret, err
    for _, task in ipairs(body) do
        local level = task.level or 0
        if task.params and util_table.is_table(task.params) then
            task.params = cjson_safe.encode(task.params)
        end
        ret, err = ssdb_task:qpush(level, task)
    end
    local message = {}
    message.data = ret
    message.code = 200
    if err then
        message.code = 500
        message.error = err
    end
    res:json(message)
end)

crawlRouter:get("/task", function(req, res, next)
    local client = req.query.client
    local max = 5
    local message = {}
    message.code = 200
    local assignArr, err = ssdb_task:qpop(max)
    if err then
        message.error = err
        message.code = 500
    else
        local typeDict = {}
        for _, task in ipairs(assignArr) do
            if not task or not task.type then
                log(ERR, "assignArr:" .. cjson_safe.encode(assignArr))
            end
            typeDict[task.type] = 1
        end
        for type, _ in pairs(typeDict) do
            local versionDoc = ssdb_version:get(type)
            if versionDoc then
                typeDict[type] = { [type] = versionDoc.version }
                if versionDoc.imports then
                    for _, iv in ipairs(versionDoc.imports) do
                        local iVersionDoc = ssdb_version:get(iv)
                        if iVersionDoc then
                            typeDict[type][iv] = iVersionDoc.version
                        end
                    end
                end
            else
                typeDict[type] = { [type] = 1 }
            end
        end
        for _, task in ipairs(assignArr) do
            task.scripts = typeDict[task.type]
        end
        local count = #assignArr
        log(ERR, "assign:" .. tostring(client) .. ",count:" .. count)
        message.data = assignArr
    end
    res:json(message)
end)

local function can_insert(task, data, status)
    if not task or not data or status ~= 1 then
        return false
    end
    local handlers = data.handlers
    if not handlers or #handlers < 1 then
        return false
    end
    return true
end

crawlRouter:post("/data", function(req, res, next)
    local message = {}
    message.code = 200
    local body_json = req.body
    if not body_json then
        message.code = 400
        message.error = "illegal params"
        res:json(message)
        return
    end
    message.code = 200
    for _, v in ipairs(body_json) do
        local task = v.task
        local data = v.data
        local status = v.status
        task.id = task.id or ("0" .. task.type)
        if can_insert(task, data, status) then
            local level = task.level or 0
            local resp, err = ssdb_result:qpush(level, v)
            log(ERR, "ssdb_result,level:" .. level .. ",resp:" .. cjson_safe.encode(resp) .. ",data:" .. cjson_safe.encode(v))
            if err then
                message.code = 500
                message.error = cjson_safe.encode(resp)
            end
        else
            log(CRIT, "taskErr:" .. tostring(v.task.id) .. ",task:" .. cjson_safe.encode(task))
            if data then
                log(CRIT, "taskErr:" .. tostring(v.task.id) .. ",data:" .. cjson_safe.encode(data))
            end
            if v.error then
                log(CRIT, "taskErr:" .. tostring(v.task.id) .. ",error:" .. cjson_safe.encode(v.error))
            end
        end
    end
    res:json(message)
end)


return crawlRouter