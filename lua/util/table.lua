local ok, new_tab = pcall(require, "table.new")
if not ok or type(new_tab) ~= "function" then
    new_tab = function (narr, nrec) return {} end
end
local _M = new_tab(0, 2)
_M._VERSION = '0.01'

local next = next

function _M.is_array(t)
    if type(t)~="table" then return nil,"Argument is not a table! It is: "..type(t) end
    --check if all the table keys are numerical and count their number
    local count=0
    for k,v in pairs(t) do
        if type(k)~="number" then return false else count=count+1 end
    end
    --all keys are numerical. now let's see if they are sequential and start with 1
    for i=1,count do
        --Hint: the VALUE might be "nil", in that case "not t[i]" isn't enough, that's why we check the type
        if not t[i] and type(t[i])~="nil" then return false end
    end
    return true
end

function _M.is_table(t)
    return type(t) =="table"
end

-- next 未被jit优化，少用
function _M.is_empty_table(t)
    if t == nil or next(t) == nil then
        return true
    else
        return false
    end
end

function _M.new_table(index_count,key_count)
    return new_tab(index_count, key_count)
end

function _M.equals(left,rigth)
    if not left and not right then
        return true
    elseif left == right then
        return true
    end
    for k,v in pairs(left) do
        if rigth[k] ~= v then
            return false
        end
    end
    return true
end

return _M