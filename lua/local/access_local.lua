local ip_addr = ngx.var.remote_addr
local local_host = "127.0.0.1"
if local_host ~= ip_addr then
	ngx.exit(ngx.HTTP_FORBIDDEN)
end
