local rematch = ngx.re.match
local find_year = function ( name )
    if not name then
        return
    end
    local m, err = rematch(name, "(^|[^0-9])(19[0-9]{2}|20[0-9]{2})([^0-9]|$)")
    if m then
        return m[2]
    end
end
local name = [[继承人2017]]
local name = [[1901继承人2017]]
local name = [[190继承人2017.ab]]
local name = [[190继承人22017.ab]]
local year = find_year(name)
ngx.say("name["..name.."],year:" .. tostring(year))