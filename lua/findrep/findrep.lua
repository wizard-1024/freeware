-- Search and replace patterns for any files, version 1.0
-- Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved.
-- Usage: findrep.lua -i <inputfile> -o <outputfile> -s <searchpattern> -r <replacepattern>


if #arg < 2 then
  print "Search and replace patterns for any files, version 1.0"
  print "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."
  print "Usage: findrep.lua -i <inputfile> -o <outputfile> -s <searchpattern> -r <replacepattern>"
  return 1
end


-- Helper function to calculate file size.
local function filesize (fd)
   local current = fd:seek()
   local size = fd:seek("end")
   fd:seek("set", current)
   return size
end

-- This function will replace all occurances of 'replaced' in a string with 'replacement'
local function replaceAll(str,replaced,replacement)
    local function sub (a,b)
        if b > a then
            return str:sub(a,b)
        end
        return nil
    end
    a,b = str:find(replaced)
    while a do
        str = str:sub(1,a-1) .. replacement .. str:sub(b+1,#str)
        a,b = str:find(replaced)
    end
    return str
end

-- local ffi = require("ffi")

local infilename = ""
local outfilename = ""
local searchpattern = ""
local replacehpattern = ""

i = 1
while( i < #arg ) do
  if arg[i] == '-i' then
    i = i + 1
    infilename = arg[i]
    print("infilename: ", infilename)
  end
  if arg[i] == '-o' then
    i = i + 1
    outfilename = arg[i]
    print("outfilename: ", outfilename)
  end
  if arg[i] == '-s' then
    i = i + 1
    searchpattern= arg[i]
    print("searchpattern: ", searchpattern)
  end
  if arg[i] == '-r' then
    i = i + 1
    replacepattern= arg[i]
    print("replacepattern: ", replacepattern)
  end
  i = i + 1
end


-- local searchdata = tonumber(searchpattern,16)
-- local replacedata = tonumber(replacepattern,16)

local infile = assert(io.open(infilename,"r"))
local contents = infile:read'*a'
infile:close()

newcontents = replaceAll (contents, searchpattern, replacepattern)

local outfile = assert(io.open(outfilename,"w"))
outfile:write(newcontents)
outfile:close()
