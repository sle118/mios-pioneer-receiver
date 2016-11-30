--[[

  This script will attempt to download PioneerReceiver plugin  
  from GitHub and install it on your vera box. 


  using multi-part upload from 
  https://github.com/catwell/lua-multipart-post

  original script written by @akbooer
  http://forum.micasaverde.com/index.php?topic=38511.0
]]--

-- first-time download and install of openLuup files from GitHub

local lua = "lua5.1"     -- change this to "lua" if required
local x = os.execute
local p = print

p "openLuup_install   2017.11.29   @sle118 (originally @akbooer)"
package.path = '/tmp/?.lua;' .. package.path
local http  = require "socket.http"
local https = require "ssl.https"
local ltn12 = require "ltn12"
local lfs   = require "lfs"

local success = true


p "getting https://raw.githubusercontent.com/catwell/lua-multipart-post/master/multipart-post.lua..."
local a, code = https.request{
    url = "https://raw.githubusercontent.com/catwell/lua-multipart-post/master/multipart-post.lua",
    sink = ltn12.sink.file(io.open("/tmp/multipart-post.lua", "wb"))
  }

assert (code == 200, "GitHub download failed with code " .. code)
local mp = (require "multipart-post")

local function upload_file(file_path, port,name)
  
    local f = io.open(file_path, "rb")
    local content = f:read("*all")
    f:close()
    assert(content~=nil,"error loading file for upload")
    local attachment,boundary = mp.encode({
                                              upnp_file_1 = {name = 'blob', data = content,content_type='text/xml' },
                                              upnp_file_1_name = name                                             
                                           })
    local url = 'http://127.0.0.1:'..port..'/cgi-bin/cmh/upload_upnp_file.sh'
    p (string.format('uploading file %s to port %u using url %s ', file_path or '?', port or 0,url))
    
    -- need to overwrite content-disposition for openLuup
    local sourceString = attachment:gsub('(content--disposition)','Content-Disposition')
    sourceString = sourceString:gsub('(content--type)','Content-Type')
    local req = {
        url = url,
        method = "POST",
        source = ltn12.source.string(sourceString),
        headers = {
            ["Content-Length"] = #sourceString,
            ["Content-Type"] = string.format('multipart/form-data; boundary=%s', boundary)
        }}
    local b,c,h = http.request(req)
        
  return b or 0,c or '?',h or '?'
end

local function try_upload(file_path, name)
  -- try to upload on port 80
  local r,c,h,response_body = upload_file(file_path,'80',name)
  if(r~=1) then
    -- is this openLuup?
    r,c,h,response_body = upload_file(file_path,'3480',name)
  end
  
  return r,c,h
end
p "getting latest PioneerReceiver version tar file from GitHub..."

local _, code = https.request{
  url = "https://codeload.github.com/sle118/mios-pioneer-receiver/tar.gz/master",
  sink = ltn12.sink.file(io.open("/tmp/latest.tar.gz", "wb"))
}

if(code ~= 200) then
  p("GitHub download failed with code " .. code)
  success = false
end

p "un-zipping download files..."

x "tar -xf /tmp/latest.tar.gz --directory=/tmp/"
x "mv /tmp/mios-pioneer-receiver-master/*Pio* /tmp"
x "rm -r /tmp/mios-pioneer-receiver-master/"

for file in lfs.dir('/tmp') do
  
  local r,c,h
  if lfs.attributes('/tmp/'..file,"mode") == "file" and
    (string.find(file,'._PioneerReceiver.*xml') ~= nil or
    string.find(file,'._PioneerReceiver.*lua') ~= nil or
    string.find(file,'._PioneerReceiver.*json') ~= nil or
    string.find(file,'._PioneerReceiver.*js') ~= nil) then
    p("found file : "..'/tmp/'..file)
    r,c,h = try_upload('/tmp/'..file, file)
    if(r == 1 and c==200 or c==201) then
      os.remove('/tmp/'..file)
    else
      p('file upload error : '..c or '?')
      success = false
      break
    end

  end
end
x "rm /tmp/*Pio* "
assert(success,'error installing plugin.')

p "PioneerReceiver plugin downloaded and installed ..."

