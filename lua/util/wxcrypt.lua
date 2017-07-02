local util_table = require "util.table"
local context = require "util.context"
local arrays = require "util.arrays"
local resty_sha1 = require "resty.sha1"
local resty_string = require "resty.string"
local aes = require "resty.aes"
local bit = require "bit"


local decode_base64 = ngx.decode_base64
local encode_base64 = ngx.encode_base64

local _M = util_table.new_table(0, 1)
_M._VERSION = '0.01'

local log = ngx.log
local ERR = ngx.ERR
local cjson_safe = require "cjson.safe"


local string_byte = string.byte
local string_sub = string.sub
local string_len = string.len
local table_insert = table.insert

local token = context.AUTH_WX_MSG_TOKEN
local appid = context.AUTH_WX_MSG_APPID
local aesKey = decode_base64(context.AUTH_WX_MSG_AESKEY .. "=")
local ivKey = string_sub(aesKey,1,16)
local cryptor = assert(aes:new(aesKey,nil, aes.cipher(256,"cbc"), {iv=ivKey}))
local block_size = 32

function _M.signature(timestamp, nonce, encrypt)
	log(ERR,"msg.timestamp:", timestamp)
	log(ERR,"msg.nonce:", nonce)
	log(ERR,"msg.encrypt:", encrypt)
	local param_arr = {}
    table_insert(param_arr,token)
    table_insert(param_arr,timestamp)
    table_insert(param_arr,nonce)
    table_insert(param_arr,encrypt)
    function char_sort(a,b) 
    	local str_a = tostring(a)
    	local str_b = tostring(b)
    	return str_a < str_b;
	end
    table.sort(param_arr,char_sort) 
	-- table.sort(param_arr)
	local msg = table.concat(param_arr,"")
	log(ERR,"msg.concat:", table.concat(param_arr,"="))
	local sha1 = resty_sha1:new()
	sha1:update(msg)
	local digest = sha1:final()
	digest = resty_string.to_hex(digest)
	return digest;
end

function _M.encrypt(text)
	local random_txt = string.random(16)
	local len = string_len(text)
	local sizeByteArr = _M.getNetworkBytesOrder(len)
	local size2string = arrays.byte2string(sizeByteArr)
	text =  random_txt .. size2string .. text .. appid
	log(ERR,"pkcs7.in.txt:", text)
	text = _M.encode(text)
	log(ERR,"pkcs7.out.txt:", text)
	local encrypt_text =  cryptor:encrypt(text);
	return encode_base64(encrypt_text);
end

function _M.decrypt(encrypted)
	local decode_txt = decode_base64(encrypted)
	-- 明文加密
	if not decode_txt then
		return encrypted
	end
	local plain_text = cryptor:decrypt(decode_txt)
	 -- 去掉补位字符串
	plain_text = _M.decode(plain_text);
     -- 去除16位随机字符串
    content = string_sub(plain_text,17)
    local len_bytes = {}
	for i=1,4 do
		table_insert(len_bytes,string_byte(content,i))
	end
    log(ERR,"len_bytes:",cjson_safe.encode(len_bytes))
    local xml_len = _M.recoverNetworkBytesOrder(len_bytes)
    local xml_content = string_sub(content,5, xml_len + 4)
    local from_appid = string_sub(content,xml_len + 5)
    assert(appid == from_appid)
	return xml_content
end

-- 对需要加密的明文进行填充补位
function _M.encode(text)
	-- // 计算需要填充的位数
    local text_length = string_len(text)
    local amount_to_pad = block_size - (text_length % block_size)
    if amount_to_pad == 0 then
    	amount_to_pad = 0
    end
    -- 获得补位所用的字符
    log(ERR,"text:",text)
    log(ERR,"amount_to_pad:",amount_to_pad)
    local pad_char = string.char(amount_to_pad)
    local pad_temp = ""
    for i=1,amount_to_pad do
    	pad_temp = pad_temp .. pad_char
    end
    return text .. pad_temp
end
-- 删除解密后明文的补位字符
function _M.decode(decrypted)
	if not decrypted then
		return nil, "bad decrypted"
	end
	local len = string_len(decrypted)
    local pad = string_byte(decrypted, len)
    if pad<1 or pad >32 then
        pad = 0
    end
    return string_sub(decrypted,1,len-pad);
end


-- 生成4个字节的网络字节序
function _M.getNetworkBytesOrder(sourceNumber)
	local orderBytes = {}
	table_insert(orderBytes, bit.band(bit.rshift(sourceNumber,24),0xFF))
	table_insert(orderBytes, bit.band(bit.rshift(sourceNumber,16),0xFF))
	table_insert(orderBytes, bit.band(bit.rshift(sourceNumber,8),0xFF))
	table_insert(orderBytes, bit.band(sourceNumber,0xFF))
	return orderBytes;
end

-- 还原4个字节的网络字节序
function _M.recoverNetworkBytesOrder(orderBytes)
	local sourceNumber = 0
	for _,v in ipairs(orderBytes) do
		sourceNumber  = bit.lshift(sourceNumber,8)
		local vand = bit.band(v,0xFF)
		sourceNumber = bit.bor(sourceNumber,vand)
	end
	return sourceNumber
end

return _M