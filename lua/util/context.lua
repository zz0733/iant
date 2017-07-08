local util_table = require "util.table"
local util_string = require "util.string"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local shared_dict = ngx.shared.shared_dict
local key_version = "app_verion"
_M.jiathis_uid = "2129651"
_M.weibo_app_key = "942886765"
_M.weibo_uid = "1766676277"


_M.search_page_size = 30
_M.search_max_page = 100
_M.link_page_size = 10
_M.link_max_page = 100

_M.AUTH_WX_MSG_APPID = os.getenv("AUTH_WX_MSG_APPID")
_M.AUTH_WX_MSG_AESKEY = os.getenv("AUTH_WX_MSG_AESKEY")
_M.AUTH_WX_MSG_TOKEN = os.getenv("AUTH_WX_MSG_TOKEN")

_M.WX_REPLY_TEMPLATE = '<xml><ToUserName><![CDATA[{toUser}]]></ToUserName><FromUserName><![CDATA[{fromUser}]]></FromUserName><CreateTime>{createTime}</CreateTime><MsgType><![CDATA[{MsgType}]]></MsgType><Content><![CDATA[{content}]]></Content></xml>'


_M.SNAP_ENV = os.getenv("SNAP_ENV")
function _M.version(new_ver)
    if new_ver then
        shared_dict:set(key_version,new_ver) 
        return new_ver
    end
    local ver =  shared_dict:get(key_version)
   
   return ver or _M.version(ngx.time())
end

return _M