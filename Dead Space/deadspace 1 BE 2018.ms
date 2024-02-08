--sleepyzay--

fn convertTo32 input16 = (
      inputAsInt = input16
      sign = bit.get inputAsInt 16
      exponent = (bit.shift (bit.and inputAsInt (bit.hexasint "7C00")) -10) as integer - 16
      fraction = bit.and inputAsInt (bit.hexasint "03FF")
      if sign==true then sign = 1 else sign = 0
      exponentF = exponent + 127
      --Ouput 32 bit integer representing a 32 bit float
      outputAsFloat = bit.or (bit.or (bit.shift fraction 13) (bit.shift exponentF 23)) (bit.shift sign 31)
      --Output Check   
      return bit.intasfloat outputasfloat
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)
fn ReadBEShort fstream = (
short = readshort fstream #unsigned
short = bit.swapBytes short 2 1
b = (bit.get short 16)
for i = 17 to 32 do short = bit.set short i b
return short
)
fn ReadBEword fstream = (
return (bit.swapBytes (readshort fstream #unsigned) 1 2)
)
fn ReadBEHalfFloat fstream = (
return convertTo32(ReadBEword fstream)
)
fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)
fn paddstring len instring = (
	instring=instring as string
	local str=""
	if instring.count <=len then (
		for i = 1 to (len-instring.count) do(
			str+="0"
		)
		str = (str+instring)
	)
	else (
		for i = 1 to len do(
			str+="0";str[i]=instring[i]
		)
	)
	str
)
fn addHexaDecimalPadding nr = (
	case of (
		(nr <= 15): ("0" + ((bit.intAsHex(nr))as string))
		(nr > 15): ((bit.intAsHex(nr))as string)
	)
)
fn ReadFixedString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str0 = ReadByte bstream #unsigned
      If str0!=0xFD AND str0!=0xFC do str+= bit.intAsChar str0
   )
   str
)
fn ReadFixedByteString bstream fixedLen = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   print str
)
fn reverseString s = (
    local reversed = ""
    for i in s.count to 1 by -1 do reversed += s[i]
	reversed
)
fn printBinary val size = (
	str = ""
	for i=1 to size do (
		if (bit.get val i)  then str += "1"
		else str += "0"
		
		if ((mod i 8) == 0) and (i < size) do str+=" "
	)
	
	str = reverseString str
	print str
)
fn printHex num = (
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	bb = box()
	bb.width = abs(currA[1])
	bb.length = abs(currA[2])
	bb.height = abs(currA[3])
-- 	hide bb
	delete bb
)
fn GetName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
)
fn signVal x size= (
	if (bit.get x size) do (
		bitMask = 0
		for i=1 to size do bitMask = bit.set bitMask i true
		
		x = bit.xor x bitMask
		x += 1	--because of 2's complement
		x *= -1
	)
	return x
)
fn readbits pos range num = (
	local i = 0, result = 0, c = 1
	local val = num
	for i = pos to ((pos - 1) + range) do (
		result = bit.set result c (bit.get val i);c+=1
		)
	result
)
fn get32bitNormal format divisor val = (
	result = [0,0,0]
	pos = 1
	for x=1 to 3 do (
		result[x] = signVal (readBits pos format[x] val) format[x]
		pos+=format[x]
	)
	result/=divisor
)

fname = GetOpenFileName caption:"Dead Space X360/PS3" types:" (*.geo)|*.geo" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

magic = readbelong f
ukw = readbelong f	--always 0x21
ukw2 = readbelong f
fileSize = readbelong f
fseek f 0x10 #seek_cur	--hash
modelName = GetName f (readbelong f)
ukw3 = readbelong f
fseek f 0xc #seek_cur	--null
tableCount = readbelong f
boneCount = readbelong f
ukwArr = for x=1 to 6 collect (readbeshort f)
refCount = readbelong f
refTableOffset = readbelong f
tableOffset = readbelong f
ukwOffset = readbelong f	--uv's?
fseek f 0x8 #seek_cur	--null
boneDataOffset = readbelong f
boneOffset = readbelong f
uvBufferInfo = readbelong f
faceBufferInfo = readbelong f

boneName=#()
parentID=#()
fseek f boneDataOffset #seek_set
for x=1 to boneCount do (
	boneName[x] = GetName f (readbelong f)
	ukw = readbeword f
	ukw2 = readbeword f
	null = readbelong f
	parentID[x] = readbelong f	--may not be parentID
)

polyInfoOffset=#()
meshName=#()
vertOffset=#()
vertOffset2=#()
vertCount=#()
faceOffset=#()
faceCount=#()

fseek f uvBufferInfo #seek_set
ukwLength = readbelong f
totalUnkCount = readbelong f
ukwSize = readbeshort f
ukw = readbeshort f
ukwOffset = readbelong f

uvBufferLength = readbelong f
totalUVBufferCount = readbelong f
uvSize = readbeshort f
ukw = readbeshort f
uvBufferOffset = readbelong f

fseek f faceBufferInfo #seek_set
faceBufferLength = readbelong f
totalFaceCount = readbelong f
faceSize = readbeshort f
ukw = readbeshort f
faceBufferOffset = readbelong f


format "tableCount: %\n" tableCount

fseek f tableOffset #seek_set
for x=1 to tableCount do (
	meshName[x] = GetName f (readbelong f)
	fseek f 0x1c #seek_cur
	ukwOffset = readbelong f	--data is 0x80 long
	ukw = readbelong f	--always 1
	ukw2 = readbeshort f
	ukw3 = readbyte f
	uvSize = readbyte f
	ukw4 = readbelong f	--always 1
	polyInfoOffset[x] = readbelong f
	null = readbelong f
	vertOffset[x] = readbelong f
	null = readbelong f
	faceOffset[x] = readbelong f
	null = readbelong f
	ukwOffset2 = readbelong f	--bind ID array?
	fseek f 0x54 #seek_cur
)

for x=1 to tableCount do (
	fseek f polyInfoOffset[x] #seek_set
	faceCount[x] = readbelong f
	faceOffset2 = readbelong f	--in reference from face buffer
	vertOffset2[x] = readbeshort f
	vertCount[x] = readbeshort f
	ukw = readbeshort f	--may be vertType
	ukw2 = readbeshort f	--believe it has something to do with the uv's
)

for x=1 to tableCount do (
	Vert_array=#()
	Face_array=#()
	UV_array=#()
	Normal_array=#()
	
	fseek f vertOffset[x] #seek_set
	for y=1 to vertCount[x] do (
		vx=ReadBEfloat f
		vy=ReadBEfloat f
		vz=ReadBEfloat f
		normals = (get32bitNormal [10,10,10] 512.0 (readbelong f))
		tangents = (get32bitNormal [8,8,8] 127.0 (readbelong f))
		bone1 = readbyte f
		bone2 = readbyte f
		bone3 = readbyte f
		bone4 = readbyte f
		weight1 = readbeword f
		weight2 = readbeword f
		weight3 = readbeword f
		weight4 = readbeword f
		
		append Vert_array([vx,vy,vz]*fscale)
		append Normal_array normals
	)
	
	fseek f ((vertOffset2[x]*uvSize)+(uvBufferOffset)) #seek_set
	for x=1 to vertCount[x] do (
		tu = readbefloat f
		tv = readbefloat f
		
		append UV_array[tu,1-tv,0]
	)
	
	
	fseek f faceOffset[x] #seek_set
	for y=1 to faceCount[x]/3 do(
		fa = ((readbeword f + 1) - vertOffset2[x])
		fb = ((readbeword f + 1) - vertOffset2[x])
		fc = ((readbeword f + 1) - vertOffset2[x])
		
		append Face_array [fa,fb,fc]
	)
	
	msh = mesh vertices:Vert_array faces:Face_Array name:meshName[x]
	msh.numTVerts = UV_array.count
	msh.wirecolor = random black white
	buildTVFaces msh
	for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count Do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
)

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f