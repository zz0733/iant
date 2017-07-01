local util_table = require "util.table"
local context = require "util.context"
local resty_sha1 = require "resty.sha1"
local resty_string = require "resty.string"
local aes = require "resty.aes"
local decode_base64 = ngx.decode_base64

local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR

local token = context.AUTH_WX_MSG_TOKEN
local aesKey = decode_base64(context.AUTH_WX_MSG_KEY .. "=")
local cryptor = aes:new(aesKey)
function _M.verify(timestamp, nonce, encrypt, signature)
	local param_arr = {}
    table.insert(param_arr,token)
    table.insert(param_arr,timestamp)
    table.insert(param_arr,nonce)
    table.insert(param_arr,encrypt)
    table.sort(param_arr)
	local msg = table.concat(param_arr)
	local sha1 = resty_sha1:new()
	sha1:update(msg)
	local digest = sha1:final()
	digest = resty_string.to_hex(digest)

	log(ERR,"msg:", msg)
	log(ERR,"digest:", digest)
	log(ERR,"signature:", signature)
	log(ERR,"signature = digest:", tostring(signature == digest))
	return digest == signature
end

function _M.encrypt(randomStr, text)
end

function _M.decrypt(encrypted)
	local decode_txt = decode_base64(encrypted)
	local origin = cryptor:decrypt(decode_txt)
	log(ERR,"encrypted:", encrypted)
	log(ERR,"decode_txt:", decode_txt)
	log(ERR,"origin:", origin)
	return origin
end

return _M