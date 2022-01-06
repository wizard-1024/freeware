-- Build checksums per any file, version 1.0
-- Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved.
-- Usage: testsum.lua -i <inputdir>

if #arg < 2 then
  print "Build checksums per any file, version 1.0"
  print "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."
  print "Usage: testsum.lua -i <dirname>"
  return 1
end

require 'lfs'

local nums = {}



-- DIR_SEP="\" --should be "/" for Unix platforms (Linux and Mac)
DIR_SEP="/"

printf = function(s,...)
           return io.write(s:format(...))
         end -- function


local indirname = ""

i = 1
while( i < #arg ) do
  if arg[i] == '-i' then
    i = i + 1
    indirname = arg[i]
    print("dirname: ", indirname)
  end
  i = i + 1
end

function GetFileExtension(path)
    return path:match("^.+(%..+)$")
end

function get_file_name(file)
      return file:match("^.+/(.+)$")
end


function FastBytesToString(bytes)
  s = {}
  for i = 1, getn(bytes) do
    s[i] = strchar(bytes[i])
  end
  return concat(s)
end


function crc32(buf, size)
  local crc = 0xFFFFFFFF
  local table = {}
  local rem, c
 
  -- calculate CRC-table
  for i = 0, 0xFF do
    rem = i
    for j = 1, 8 do
      if (rem & 1 == 1) then
        rem = rem >> 1
        rem = rem ~ 0xEDB88320
      else
        rem = rem >> 1
      end
    end
    table[i] = rem
  end
 
   for x = 1, size do
    c = string.byte(buf,x)
    crc = (crc >> 8) ~ table[(crc & 0xFF) ~ c]
  end
  return crc ~ 0xFFFFFFFF
end

function GetFileSize( filename )
    local fp = io.open( filename, "rb" )
    if fp == nil then 
 	return nil 
    end
    local filesize = fp:seek( "end" )
    fp:close()
    return filesize
end


function browseFolder(root)
	for entity in lfs.dir(root) do
		if entity~="." and entity~=".." then
			local fullPath=root..DIR_SEP..entity
			--print("root: "..root..", entity: "..entity..", mode: "..(lfs.attributes(fullPath,"mode")or "-")..", full path: "..fullPath)
			local mode=lfs.attributes(fullPath,"mode")
			if mode=="file" then
				--this is where the processing happens. I print the name of the file and its path but it can be any code
				-- print(root.." > "..entity)
				-- print("file:", fullPath )
				filesize = GetFileSize(fullPath)
                                file_attributes = lfs.attributes(fullPath)
                                filename = get_file_name(fullPath)
                                -- printf("filename=\"%s\"  filesize=\"%s\"  datetime=\"%s\"\n",filename,filesize,os.date("%c",file_attributes.modification))
                                -- printf("filename=\"%s\"  filesize=\"%s\"  datetime=\"%s\"\n",filename,filesize,os.date("%a %b %d %X %Y",file_attributes.modification))
                                filelen = tonumber(filesize)
                                if filelen ~= nil and filelen < 4096*1024*0124 then
				   infile = assert(io.open(fullPath,"rb"))
                                   in_bytes = infile:read("*all")
				   infile:close()
                                   crc32_sum = crc32(in_bytes,filelen)
                                   printf("filename=\"%s\" crc32=\"0x%X\"\n",fullPath,crc32_sum)
                                else 
                                  -- printf("filename=\"%s\"  filesize=\"%s\"\n",filename,filesize)
                                end
			elseif mode=="directory" then
			        -- print("directory ->", fullPath )
			        -- print(fullPath )
				browseFolder(fullPath)
			end
		end
	end
end

print("input dirname:",indirname)
-- print(indirname)
browseFolder(indirname)
