local cjson_safe = require("cjson.safe")
local table_util = require("app.libs.util.table")
local status_es = require("app.libs.es.status")
local status_ssdb = require("app.libs.ssdb.status")



local status_model = {}


function status_model:save_by_crawler(source)
    if not source then
        return nil, 400
    end
    local source_array = source
    if not table_util.is_array(source_array) then
        source_array = {}
        table.insert(source_array, source)
    end

    local err_count = 0
    for _, v in ipairs(source_array) do
        local has_status, has_err = status_ssdb:get(v.id)
        ngx.log(ngx.ERR, "status_ssdb:has_status:" .. tostring(cjson_safe.encode(has_status)) .. ",err:" .. cjson_safe.encode(has_status))
        if not has_err then
            local save_source = v
            if has_status then
                save_source = has_status
                for key, _ in pairs(status_ssdb.update_by_crawler) do
                    save_source[key] = v[key]
                end
            end
            save_source.userId = save_source.userId or v.userId or "0"
            local _, es_status = status_es:save(save_source)
            local es_err = status_es:statusErr(es_status)
            if es_err then
                err_count = err_count + 1
                ngx.log(ngx.ERR, "status_es:save:" .. tostring(v.id) .. ",cause:" .. cjson_safe.encode(es_err))
            else
                local _, ssdb_err = status_ssdb:set(v.id, v)
                if ssdb_err then
                    err_count = err_count + 1
                    ngx.log(ngx.ERR, "status_ssdb:set:" .. tostring(v.id) .. ",cause:" .. cjson_safe.encode(es_err))
                end
            end
        else
            ngx.log(ngx.ERR, "status_ssdb:get:" .. tostring(v.id) .. ",cause:" .. cjson_safe.encode(has_err))
        end
    end
    local msg = "success"
    if err_count > 0 then
        msg = "fail"
    else
        err_count = nil
    end
    return msg, err_count
end

function status_model:incr_num(id, incr_dict)
    if not id or not incr_dict then
        return nil, "params is illegal"
    end
    local has_status = status_ssdb:get(id)
    if not has_status then
        has_status = {}
        has_status.id = id
    end
    for k, num in pairs(incr_dict) do
        num = tonumber(num)
        if num then
            local has_num = has_status[k] or 0
            has_num = has_num + num
            has_status[k] = has_num
        end
    end
    local _, status = status_es:save(has_status)
    local statusErr = status_es:statusErr(status)
    if not statusErr then
        local _, err = status_ssdb:set(id, has_status)
        statusErr = err
    end
    local msg = "success"
    if statusErr then
        msg = nil
    end
    return msg, statusErr
end

function status_model:get(id)
    return status_ssdb:get(id)
end

return status_model