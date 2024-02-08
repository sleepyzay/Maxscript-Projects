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
fn triangle_strip bstream count = (
	fArr=#()
	
	face_flip = true
	face_reset=true
	x=1;while x < count Do (
		x+=1
		If face_reset == true then (
			x+=2
			face_reset=false
			face_flip = true
			fa = (ReadBEword bstream ) + 1
			fb = (ReadBEword bstream ) + 1
			fc = (ReadBEword bstream ) + 1
			If face_flip == true then (
				append fArr [fa,fc,fb]
				face_flip=false
			)
			else(
				append fArr [fa,fb,fc]
				face_flip=true
			)
		)
		else(
			fa = fb
			fb = fc
			fc = ReadBEword bstream
			If fc!=0xFFFF then (
				fc += 1
				If face_flip == true then (
					append fArr [fa,fc,fb]
					face_flip=false
				)
				else(
					append fArr [fa,fb,fc]
					face_flip=true
				)
			)
			else(
				face_reset=true
			)
		)
	)
	
	return fArr
)

struct meshData (
	vertOffset,
	vertCount,
	vertSize,
	faceOffset,
	faceCount
)

fname = GetOpenFileName caption:"" types:" (*.)|*.mdc" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=5
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

fseek f 0x10 #seek_cur
headerEnd = readbelong f
fileSize = readbelong f
modelData = readbelong f
vertexData = readbelong f
textureData = readbelong f

fseek f modelData #seek_set
modelDataTable = readbelong f + modelData
modelDataLength = readbelong f
modelDataString = readstring f

fseek f modelDataTable #seek_set
modelDataCount = readbeshort f
ukwCount2 = readbeshort f
ukw = readbelong f	--always 1, prob count
modelDataOffset = for x=1 to modelDataCount collect (readbelong f + modelDataTable)
ukwOffset2 = for x=1 to ukwCount2 collect (readbelong f + modelDataTable)
vertStart = readbelong f
ukwCount3 = readbeshort f
ukwCount4 = readbeshort f

-- printHex ukwCount2
for x=1 to ukwCount2 do (
	fseek f ukwOffset2[x] #seek_set
-- 	ReadFixedByteString f 0x10
-- 	printHex (ukwOffset2[x]-modelDataTable)
)

modelArr=#()
for x=1 to modelDataCount do (	--modelDataCount
	fseek f modelDataOffset[x] #seek_set
	
	modelDataLength = readbeshort f
	modelDataType = readbeshort f
	fseek f 0x18 #seek_cur	--no data
	meshDataCount = readbeshort f
	ukwArrCount = readbeshort f	--bindID?
	meshDataOffset = for y=1 to meshDataCount collect (readbelong f + modelDataOffset[x])
	ukwArr = for y=1 to ukwArrCount collect (readbeshort f)
	
	
	for y=1 to meshDataCount do (
		m = meshData()
		fseek f meshDataOffset[y] #seek_set
		
		meshDataLength = readbeshort f
		meshDataType = readbeshort f
		fseek f 0x24 #seek_cur	--transform info?
		tag = readbeshort f
		null = readbeshort f
		
-- 		backJump = ftell f
-- 		ReadFixedByteString f ((meshDataOffset[y]+meshDataLength)-(ftell f))
-- 		fseek f backJump #seek_set
		
		vSize = readbeshort f	
		ukwTableCount = readbyte f	--decTable?
		ukw4 = readbyte f	#unsigned
		fseek f 0x08 #seek_cur	--null
		uwk5 = readbefloat f
		uwk6 = readbefloat f
		for z=1 to ukwTableCount do (
			ukw = readbelong f	--ID?
			ukw2 = readbelong f	--tag?
			null = readbelong f
		)
		
		fseek f (meshDataOffset[y]+meshDataLength) #seek_set
		meshDataLength2 = readbeshort f
		meshDataType = readbeshort f
		null = readlonglong f
		fseek f 0x10 #seek_cur	--ukwData
-- 		ReadFixedByteString f 0x10
		
		vOffset = readbelong f
		fOffset = readbelong f
		vCount = readbeshort f
		fCount = readbeshort f
		tag = readbelong f
		
		m.vertOffset = vOffset
		m.vertCount = vCount
		m.vertSize = vSize
		m.faceOffset = fOffset
		m.faceCount = fCount
		
		if modelArr[x] == undefined do modelArr[x] = #()
		append modelArr[x] m
	)
	
-- 	format "\n"
)

fseek f vertexData #seek_set
vertexDataStart = readbelong f + vertexData
vertexDataLength = readbelong f
vertexDataString = readstring f

fseek f vertexDataStart #seek_set
faceStart = ftell f
vertStart += vertexDataStart

for x=1 to modelDataCount do (	--modelDataCount
	vertSum = 0
	
	for a in modelArr[x] do (
		Vert_array=#()
		UV_array=#()
		Face_array=#()
		Normal_array=#()
		
-- 		format "% % \n" (bit.intashex(a.vertSize)) (bit.intashex(a.vertOffset + vertStart))
		
		fseek f (a.faceOffset + faceStart) #seek_set
		Face_array = triangle_strip f (a.faceCount + 1)
		
		fseek f (a.vertOffset + vertStart) #seek_set
		if a.vertSize == 0x00 do (
			for y=1 to a.vertCount do (
				vx = readbefloat f
				vy = readbefloat f
				vz = readbefloat f
				
				fseek f 0x54 #seek_cur
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array[0,0,0]
			)
		)
		if a.vertSize == 0x01 do (
			for y=1 to a.vertCount do (
				vx = readbefloat f
				vy = readbefloat f
				vz = readbefloat f
				fseek f 0x0c #seek_cur	--null
				nx = readbefloat f
				ny = readbefloat f
				nz = readbefloat f
				fseek f 0x0c #seek_cur	--null
				p1 = readfloat f
				fseek f 0x0c #seek_cur	--null
				tx = readbefloat f
				ty = readbefloat f
				tz = readbefloat f
				ukw = readbelong f	--may be 4 bytes
				tu = readbefloat f
				tv = readbefloat f
				tu2 = readbefloat f
				tv2 = readbefloat f
				tu3 = readbefloat f
				tv3 = readbefloat f
				tu4 = readbefloat f
				tv4 = readbefloat f
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array[tu,1-tv,0]
				append Normal_array[nx,ny,nz]
			)
		)
		if a.vertSize == 0x03 do (
			for y=1 to a.vertCount do (
				vx = readbefloat f
				vy = readbefloat f
				vz = readbefloat f
				fseek f 0x0c #seek_cur	--null
				nx = readbefloat f
				ny = readbefloat f
				nz = readbefloat f
				bone1 = readbyte f #unsigned + 1
				bone2 = readbyte f #unsigned + 1
				bone3 = readbyte f #unsigned + 1
				bone4 = readbyte f #unsigned + 1
				fseek f 0x08 #seek_cur	--null
				weight1 = readbefloat f
				weight2 = readbefloat f
				weight3 = readbefloat f
				weight4 = readbefloat f
				tx = readbefloat f
				ty = readbefloat f
				tz = readbefloat f
				null = readbelong f
				tu = readbefloat f
				tv = readbefloat f
				fseek f 0x08 #seek_cur	--null
				
				append Vert_array([vx,vy,vz]*fscale)
				append UV_array[tu,1-tv,0]
				append Normal_array[nx,ny,nz]
			)
		)
		
		msh = mesh vertices:Vert_array faces:Face_array
		msh.numTVerts = UV_array.count	--uvs's look broken as shit but still work lol
		msh.name = (bit.intAsHex(a.vertSize))as string
		msh.wirecolor = random black white
		buildTVFaces msh
		for j = 1 to UV_array.count Do setTVert msh j UV_array[j]
		for j = 1 to Face_array.count Do setTVFace msh j Face_array[j]
		for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
		msh.transform=(matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
	)
-- 	format "\n"
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f