local util_table = require "util.table"
local arrays = require "util.arrays"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


function _M.detail_header(doc)
   local header = {}
   local id = doc.id
   local media = doc.media
   local directors = doc.directors
   local actors = doc.actors
   local keywords = "狸猫资讯、lezomao"
   local description = "狸猫资讯(LezoMao.com)"
   if directors then
   	  local str_director = table.concat(arrays.sub(directors,0,2),"、")
   	  keywords = keywords .. ",导演：" .. str_director
   	  description = description .. ",导演：" .. str_director
   end
   if actors then
   	  local str_actors = table.concat(arrays.sub(actors,0,3),"、")
   	  keywords = keywords .. ",主演：" .. str_actors
   	  description = description .. ",主演：" .. str_actors
   end
   local title = doc.title or ""
   local year = doc.year or 1970
   local head_title = title
   if string.match(title, tostring(year)) then
   	keywords = keywords .."," ..  title
   else
   	keywords = keywords .."," ..  title .. "("..year..")"
   	head_title = head_title .. "("..year..")"
   end
   keywords = keywords ..",种子下载,迅雷下载,高清下载"
   description = description ..",免费获取资源：" .. title .. ""
   head_title = head_title ..",种子下载,迅雷下载,高清下载,高清百度云 - 狸猫资讯(LezoMao.com)"
   header.canonical = "http://www.lezomao.com/movie/detail/"..tostring(id) .. ".html"
   header.keywords = keywords
   header.description = description
   header.title = head_title
   return header
end

return _M