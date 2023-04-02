-- stylua: ignore start

-- zzlib - zlib decompression in Lua - Implementation-independent code

-- Copyright (c) 2016-2023 Francois Galea <fgalea at free.fr>
-- This program is free software. It comes without any warranty, to
-- the extent permitted by applicable law. You can redistribute it
-- and/or modify it under the terms of the Do What The Fuck You Want
-- To Public License, Version 2, as published by Sam Hocevar. See
-- the COPYING file or http://www.wtfpl.net/ for more details.


local unpack = table.unpack or unpack
local infl

local lua_version = tonumber(_VERSION:match("^Lua (.*)"))
if not lua_version or lua_version < 5.3 then
  -- older version of Lua or Luajit being used - use bit/bit32-based implementation
  infl = require("mason-vendor.zzlib.inflate-bit32")
else
  -- From Lua 5.3, use implementation based on bitwise operators
  infl = require("mason-vendor.zzlib.inflate-bwo")
end

local zzlib = {}

local function arraytostr(array)
  local tmp = {}
  local size = #array
  local pos = 1
  local imax = 1
  while size > 0 do
    local bsize = size>=2048 and 2048 or size
    local s = string.char(unpack(array,pos,pos+bsize-1))
    pos = pos + bsize
    size = size - bsize
    local i = 1
    while tmp[i] do
      s = tmp[i]..s
      tmp[i] = nil
      i = i + 1
    end
    if i > imax then
      imax = i
    end
    tmp[i] = s
  end
  local str = ""
  for i=1,imax do
    if tmp[i] then
      str = tmp[i]..str
    end
  end
  return str
end

local function inflate_gzip(bs)
  local id1,id2,cm,flg = bs.buf:byte(1,4)
  if id1 ~= 31 or id2 ~= 139 then
    error("invalid gzip header")
  end
  if cm ~= 8 then
    error("only deflate format is supported")
  end
  bs.pos=11
  if infl.band(flg,4) ~= 0 then
    local xl1,xl2 = bs.buf.byte(bs.pos,bs.pos+1)
    local xlen = xl2*256+xl1
    bs.pos = bs.pos+xlen+2
  end
  if infl.band(flg,8) ~= 0 then
    local pos = bs.buf:find("\0",bs.pos)
    bs.pos = pos+1
  end
  if infl.band(flg,16) ~= 0 then
    local pos = bs.buf:find("\0",bs.pos)
    bs.pos = pos+1
  end
  if infl.band(flg,2) ~= 0 then
    -- TODO: check header CRC16
    bs.pos = bs.pos+2
  end
  local result = arraytostr(infl.main(bs))
  local crc = bs:getb(8)+256*(bs:getb(8)+256*(bs:getb(8)+256*bs:getb(8)))
  bs:close()
  if crc ~= infl.crc32(result) then
    error("checksum verification failed")
  end
  return result
end

-- compute Adler-32 checksum
local function adler32(s)
  local s1 = 1
  local s2 = 0
  for i=1,#s do
    local c = s:byte(i)
    s1 = (s1+c)%65521
    s2 = (s2+s1)%65521
  end
  return s2*65536+s1
end

local function inflate_zlib(bs)
  local cmf = bs.buf:byte(1)
  local flg = bs.buf:byte(2)
  if (cmf*256+flg)%31 ~= 0 then
    error("zlib header check bits are incorrect")
  end
  if infl.band(cmf,15) ~= 8 then
    error("only deflate format is supported")
  end
  if infl.rshift(cmf,4) ~= 7 then
    error("unsupported window size")
  end
  if infl.band(flg,32) ~= 0 then
    error("preset dictionary not implemented")
  end
  bs.pos=3
  local result = arraytostr(infl.main(bs))
  local adler = ((bs:getb(8)*256+bs:getb(8))*256+bs:getb(8))*256+bs:getb(8)
  bs:close()
  if adler ~= adler32(result) then
    error("checksum verification failed")
  end
  return result
end

local function inflate_raw(buf,offset,crc)
  local bs = infl.bitstream_init(buf)
  bs.pos = offset
  local result = arraytostr(infl.main(bs))
  if crc and crc ~= infl.crc32(result) then
    error("checksum verification failed")
  end
  return result
end

function zzlib.gunzipf(filename)
  local file,err = io.open(filename,"rb")
  if not file then
    return nil,err
  end
  return inflate_gzip(infl.bitstream_init(file))
end

function zzlib.gunzip(str)
  return inflate_gzip(infl.bitstream_init(str))
end

function zzlib.inflate(str)
  return inflate_zlib(infl.bitstream_init(str))
end

local function int2le(str,pos)
  local a,b = str:byte(pos,pos+1)
  return b*256+a
end

local function int4le(str,pos)
  local a,b,c,d = str:byte(pos,pos+3)
  return ((d*256+c)*256+b)*256+a
end

local function nextfile(buf,p)
  if int4le(buf,p) ~= 0x02014b50 then
    -- end of central directory list
    return
  end
  -- local flag = int2le(buf,p+8)
  local packed = int2le(buf,p+10)~=0
  local crc = int4le(buf,p+16)
  local namelen = int2le(buf,p+28)
  local name = buf:sub(p+46,p+45+namelen)
  local offset = int4le(buf,p+42)+1
  p = p+46+namelen+int2le(buf,p+30)+int2le(buf,p+32)
  if int4le(buf,offset) ~= 0x04034b50 then
    error("invalid local header signature")
  end
  local size = int4le(buf,offset+18)
  local extlen = int2le(buf,offset+28)
  offset = offset+30+namelen+extlen
  return p,name,offset,size,packed,crc
end

function zzlib.files(buf)
  local p = #buf-21
  if int4le(buf,p) ~= 0x06054b50 then
    -- not sure there is a reliable way to locate the end of central directory record
    -- if it has a variable sized comment field
    error(".ZIP file comments not supported")
  end
  local cdoffset = int4le(buf,p+16)+1
  return nextfile,buf,cdoffset
end

function zzlib.unzip(buf,arg1,arg2)
  if type(arg1) == "number" then
    -- mode 1: unpack data from specified position in zip file
    return inflate_raw(buf,arg1,arg2)
  end
  -- mode 2: search and unpack file from zip file
  local filename = arg1
  for _,name,offset,size,packed,crc in zzlib.files(buf) do
    if name == filename then
      local result
      if not packed then
        -- no compression
        result = buf:sub(offset,offset+size-1)
      else
        -- DEFLATE compression
        result = inflate_raw(buf,offset,crc)
      end
      return result
    end
  end
  error("file '"..filename.."' not found in ZIP archive")
end

return zzlib
