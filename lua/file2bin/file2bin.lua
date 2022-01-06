-- Extract binary portion from file, version 1.0
-- Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved.
-- Usage: file2bin.lua -i <inputfile> -o <outputfile> -s <fileoffset> -l <filelen>

if #arg < 2 then
  print "Extract binary portion from file, version 1.0"
  print "Copyright (C) 2022 Dmitry Stefankov. All Rights Reserved."
  print "Usage: file2bin.lua -i <inputfile> -o <outputfile> -s <fileoffset> -l <filelen>"
  return 1
end

local infilename = ""
local outfilename = ""
local infilelen = 0
local infileofs = 0

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
  if arg[i] == '-l' then
    i = i + 1
    infilelen = arg[i]
    print("infilelen: ", infilelen)
  end
  if arg[i] == '-s' then
    i = i + 1
    infileofs = arg[i]
    print("infileofs: ", infileofs)
  end
  i = i + 1
end


local infile = assert(io.open(infilename,"rb"))
infile:seek( "set",tonumber(infileofs) )
local in_bytes = infile:read(tonumber(infilelen))
infile:close()

local outfile = assert(io.open(outfilename,"wb"))
outfile:write(in_bytes)
outfile:close()
