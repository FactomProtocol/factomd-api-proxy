local cors = require('cors')
local health_check = require('health_check')

local function global_headers(config)
  ngx.header['Content-Security-Policy'] = "default-src 'none'"
  ngx.header['Content-Type'] = 'application/json; charset=utf-8'
  ngx.header['Referrer-Policy'] = 'same-origin'
  ngx.header['X-Content-Type-Options'] = 'nosniff'
  ngx.header['X-Frame-Options'] = 'SAMEORIGIN'
  ngx.header['X-XSS-Protection'] = '1; mode=block'

  if config.ssl_enabled then
    ngx.header['Strict-Transport-Security'] = 'max-age=63072000;'
  end
end

local function passthrough_api_call()
  local options = {
    always_forward_body = true,
    method = ngx.HTTP_POST,
  }

  ngx.req.read_body()
  local res = ngx.location.capture('/factomd', options)

  ngx.status = res.status
  ngx.header['Content-Length'] = res.header['Content-Length']
  ngx.print(res.body)
end

local function go(config)
  local method = ngx.req.get_method()
  local uri = ngx.var.uri

  global_headers(config)

  cors.go(config)

  if uri == '/' and method == 'GET' then
    health_check.go(config)
    ngx.exit(ngx.OK)

  elseif (uri == '/' or uri == '/v2') and method == 'OPTIONS' then
    ngx.exit(ngx.HTTP_OK)

  elseif uri == '/v2' and method == 'POST' then
    passthrough_api_call()
    ngx.exit(ngx.OK)

  else
    ngx.exit(ngx.HTTP_NOT_FOUND)
  end
end

return {
  go = go,
}