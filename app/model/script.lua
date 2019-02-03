local cjson_safe = require "cjson.safe"
local ssdb_script = require "app.libs.ssdb.script"
local ssdb_version = require "app.libs.ssdb.version"

local find = ngx.re.find

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local _M = {}
_M._VERSION = '0.01'


function _M:importTypes(script)
    local from, to, err = find(script, "ScriptParser.prototype.getImportScripts", "jo")
    local types = {}
    if not from or (from < 0) then
        return types
    end
    script = string.sub(script, to)
    from, to, err = find(script, "return", "jo")
    script = string.sub(script, to + 1)
    local m, err = ngx.re.match(script, "[0-9a-zA-Z,-]+", "mjo")
    if m then
        local body = cjson_safe.encode(m[0])
        -- rm "
        body = string.sub(body, 2, -2)
        types = string.split(body, ',')
    end
    return types
end

function _M:insert_scripts(params)
    if not params then
        return nil, 400
    end
    local resp = "success"
    local status = 200
    for _, scriptDoc in ipairs(params) do
        local ret, err = ssdb_script:set(scriptDoc.type, scriptDoc)
        if err then
            status = 500
            resp = err
        else
            local versionDoc = {}
            versionDoc.version = ngx.time()
            versionDoc.imports = _M:importTypes(scriptDoc.script)
            ssdb_version:set(scriptDoc.type, versionDoc)
            resp = ret
            status = 200
        end
    end
    return resp, status
end

function _M:search_by_type(taskType)
    local ret, err = ssdb_script:get(taskType)
    local versionDoc = ssdb_version:get(taskType)
    if versionDoc then
        ret.version = versionDoc.version
    end
    return ret, err
end

function _M:search_all_ids()
    local ret, err = ssdb_script:keys(1000)
    return ret, err
end

return _M