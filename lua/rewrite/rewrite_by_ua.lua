local log = ngx.log
local ERR = ngx.ERR

local uri = ngx.var.uri
if string.match(uri, "^/assets/") then
	return
end
if string.match(uri, "^/api/") then
	return
end
if string.match(uri, "^/snap/") then
	return
end
local user_agent = ngx.req.get_headers().user_agent
if not user_agent then
	return
end
user_agent = string.lower(user_agent)

function is_mobile_user_agent( ua )
	if not ua then
		return false
	end
	local mobile_ua_arr = {
	    "mobile","android","iphone",
	    "blackberry", "webos", "ipod", "lge vx", "midp", "maemo", "mmp", "mobile",
	    "netfront", "hiptop", "nintendo DS", "novarra", "openweb", "opera mobi",
	    "opera mini", "palm", "psp", "phone", "smartphone", "symbian", "up.browser",
	    "up.link", "wap", "windows ce"
	}
	for _,v in ipairs(mobile_ua_arr) do
	    if string.match(ua,v) then
	    	return true
	    end
	end
	return false
end
-- local reg = "iphone"
local is_mobile = is_mobile_user_agent(user_agent)
log(ERR,"uri:" .. uri .. "ua:"..user_agent..",is_mobile:" .. tostring(is_mobile))
local target = uri
if is_mobile and not string.match(uri,"^/m/") then
	target = "/m" .. uri
elseif not is_mobile and string.match(uri,"^/m/") then
	target = ngx.re.sub(uri,"^/m/","/")
end
if uri ~= target then
	-- log(ERR,"uri:" .. uri .. ",redirect:" .. target)
	ngx.redirect(target,ngx.HTTP_MOVED_TEMPORARILY)
end
