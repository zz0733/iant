local util_table = require "util.table"
local bit = require("bit")  

local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT

local gmatch = ngx.re.gmatch

function _M.makeId(linkURL)
    if not linkURL then
       return nil
    end
    local it = gmatch(linkURL, "magnet:.*?btih:(?<id>[0-9a-zA-Z]+)","joi")
    local matchArr = _M.iterator_regex(it,'id', 1)
    if matchArr  and matchArr[1] then
      local id = string.upper(matchArr[1])
      local hash = _M.toHashCode(id)
      local sCode = tostring(hash)
      sCode = sCode:gsub("^-","0")  
      sCode = "m"  .. sCode
      log(ERR,'hash:' .. hash .. ",sCode:" .. sCode)
      return sCode
    end
    
end

function _M.toHashCode(source)
    local hash = 0
    if not source then
      return hash
    end
    for i=1,#source do  
        local chr = source:byte(i)  
        hash = (bit.lshift(hash, 5) - hash) + chr
        hash = bit.bor(hash)
    end  
    return hash
end

function _M.iterator_regex( iterator,index,limit )
    local matchArr = {}
    if not iterator then
        return matchArr
    end
    while true do
      local m, err = iterator()
      if not m or err then
         break
      else
         local match = m[index]
         if match then
            table.insert(matchArr,match)
         end
      end
      limit = limit - 1
      if limit < 0 then
         break
      end
    end
    return matchArr
end

return _M


-- ScriptParser.prototype.toLinkId = function(link) {
--   if (!link) {
--     return
--   }
--   var linkId = null
--   if (link.startWith("ftp:")) {
--     var sCode = '' + toHashCode(link);
--     sCode = sCode.replace('-', '0');
--     linkId = "f" + sCode;
--   } else if (link.startWith("magnet:")) {
--     if (/magnet:.*?btih:([0-9a-zA-Z]+)/.test(link)) {
--       var hash = RegExp.$1
--       hash = hash.toUpperCase()
--       var sCode = '' + toHashCode(hash);
--       sCode = sCode.replace('-', '0');
--       linkId = "m" + sCode;
--     }
--   } else if (link.startWith("ed2k:")) {
--     var unitArr = link.split("|")
--     if (unitArr && unitArr.length >= 5) {
--       var hash = unitArr[4]
--       hash = hash.toUpperCase()
--       var sCode = '' + toHashCode(hash);
--       sCode = sCode.replace('-', '0');
--       linkId = "e" + sCode;
--     }
--   }
--   return linkId
-- }