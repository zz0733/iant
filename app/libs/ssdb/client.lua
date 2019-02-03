local cjson_safe = require "cjson.safe"
local table_util = require "app.libs.util.table"
local context = require "app.libs.util.context"
local ssdb = require "resty.ssdb"

local _M = {}
_M._VERSION = '0.01'

-- self.key_prefix
-- self.template
function _M:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- can not share 
-- https://github.com/openresty/lua-resty-redis/#limitations
function _M:open()
    local client = ssdb:new()
    client:set_timeout(1000) -- 1 sec
    local _, err = client:connect(context.SSDB_HOST, context.SSDB_PORT)
    if err then
        ngx.log(ngx.CRIT, "failed to connect ssdb[" .. context.SSDB_HOST .. ":" .. context.SSDB_PORT .. "],cause:", err)
        return nil, err
    end
    return client
end

function _M:close(client)
    if table_util.isNull(client) then
        return
    end
    local _, err = client:set_keepalive(0, 20)
    if err then
        ngx.log(ngx.CRIT, "failed to keepalive ssdb[" .. context.SSDB_HOST .. ":" .. context.SSDB_PORT .. "],cause:",
            err)
    end
end

function _M:to_ssdb_key(key)
    if self.key_prefix then
        return self.key_prefix .. key
    end
    return key
end

function _M:to_origin_key(key)
    if self.key_prefix then
        return string.sub(key, string.len(self.key_prefix) + 1)
    end
    return key
end

function _M:to_ssdb_bean(source)
    if not source or not table_util.is_table(source) then
        return source
    end
    local dest_bean = source
    if self.template then
        dest_bean = {}
        for k, v in pairs(self.template) do
            local value = source[k]
            if table_util.is_table(v) and table_util.is_empty_table(value) then
                value = cjson_safe.empty_array
            end
            dest_bean[k] = value
        end
    end
    return cjson_safe.encode(dest_bean)
end

function _M:to_origin_bean(sVal)
    if not sVal then
        return nil
    end
    local jsonVal = cjson_safe.decode(sVal)
    return jsonVal
end


function _M:set(key, value)
    value = self:to_ssdb_bean(value)
    key = self:to_ssdb_key(key)
    local client = self:open();
    local ret, err = client:set(key, value)
    self:close(client)
    return ret, err
end

function _M:get(content_id)
    local client = self:open();
    local ret, err = client:get(self:to_ssdb_key(content_id))
    self:close(client)
    if err then
        return nil, err
    end
    if ret == ngx.null then
        return nil
    end
    return self:to_origin_bean(ret)
end

function _M:multi_get(keys)
    if not keys then
        return {}
    end
    local ssdb_keys = {}
    for i = 1, #keys do
        table.insert(ssdb_keys, self:to_ssdb_key(keys[i]))
    end
    local client = self:open();
    local ret, err = client:multi_get(unpack(ssdb_keys))
    self:close(client)
    if ret then
        local dest = {}
        for k, v in pairs(ret) do
            k = self:to_origin_key(k)
            dest[k] = self:to_origin_bean(v)
        end
        return dest
    else
        return ret, err
    end
end

function _M:remove(content_id)
    local client = self:open();
    local ret, err = client:del(self:to_ssdb_key(content_id))
    self:close(client)
    return ret, err
end

function _M:exists(key)
    local client = self:open();
    local ret, err = client:exists(self:to_ssdb_key(key))
    self:close(client)
    return ret, err
end

return _M
