local util_table = require "util.table"
local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local util_context = require("util.context")
local magick = require("magick.gmwand")
local lfs = require("lfs_ffi")


local resty_md5 = require "resty.md5"
local resty_string = require "resty.string"

local string_sub = string.sub
local string_len = string.len


local log = ngx.log
local ERR = ngx.ERR
local CRIT = ngx.CRIT


function _M.toImgSuffix(imgURL)
    local m = ngx.re.match(imgURL, "(\\.[a-zA-Z0-9]+)$")
    local suffix = ".jpg"
    if m then
        suffix = m[0]
    end
    return suffix
end

function _M.toMD5(strBody)
    local md5 = resty_md5:new()
	md5:update(strBody)
	local digest = md5:final()
	digest = resty_string.to_hex(digest)
	digest = string_sub(digest,9, 24)
	return digest
end

function _M.toImageName(strBody, imgURL)
  return _M.toMD5(strBody) .. _M.toImgSuffix(imgURL)
end

function _M.toImage(strBody)
  return magick.load_image_from_blob(strBody)
end

function _M.saveCorpImage(img, width, height, saveName)
	 local sizeDir
	 if width < 1 or height < 1 then
	    sizeDir = util_context.IMG_DIR .."/origin"
	 else
	    sizeDir = util_context.IMG_DIR .."/" .. tostring(width) .."x"..tostring(height)
	    -- img:resize(sv.w, sv.h)
	    -- img:crop(sv.w, sv.h, x, y)
	    img:resize_and_crop(width, height)
	 end
	 lfs.mkdir(sizeDir)
	 local newPath = sizeDir.."/".. saveName
	 local resp, err = img:write(newPath)
	 if err then
	    return saveName, err
	 else
	 	return saveName
	 end
end

return _M