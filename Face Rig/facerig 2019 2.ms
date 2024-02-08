--sleepyzay--

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
fn ReadFixedByteString bstream fixedLen var var2 = (
   local str = ""
   For i = 1 to fixedLen do
   (
      str += addHexaDecimalPadding (ReadByte bstream #unsigned)
	  If mod i 1 == 0 do str += " "
   )
   str
   if var == 1 do fseek bstream -fixedLen #seek_cur
   if var2 == 1 do print str
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
	
	return currA
)
fn getName bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	str = readstring bstream
	fseek bstream backJump #seek_set
	return str
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

fname = GetOpenFileName caption:"" types:" (*.)|*.fbs" historyCategory:""
-- fname=@"C:\Users\Owner\Downloads\DATA_FLORAN unpacked using offzip\DATA_FLORAN\026ac859.fbs"
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

magic = readlong f
ukw = readlong f
null = readshort f
headerStringLength = readbyte f
headerString = ReadFixedString f headerStringLength
null = readlong f

modelNameLength = readbyte f
modelName = ReadFixedString f modelNameLength
null = readbyte f			--maybe count
matCount = readshort f

format "matCount: %\n" (bit.intashex(matCount as integer))
for x=1 to matCount do (
	matNameLength = readbyte f
	matName = ReadFixedString f matNameLength
 	
	subMatCount = readshort f
	for y=1 to subMatCount do (
		subMatNameLength = readbyte f
		subMatName = ReadFixedString f subMatNameLength
	)
)

-- ukwData = ReadFixedByteString f 0x10 0 1
ukw3 = readshort f
ukw = readlong f	--offset or length/same as modelLength + 0x0a
ukw2 = readshort f
modelLength = readlong f
null = readshort f
ukw3 = readshort f
-- fseek f 0x15B742 #seek_set
meshNameLength = readbyte f
meshName = ReadFixedString f meshNameLength
modelScale = readfloat f
meshCount = readshort f
format "modelName: %	modelScale: %	meshCount: %\n" modelName modelScale meshCount
	
for x=1 to meshCount do (	--meshCount
	Face_array=#()
	Vert_array=#()
	UV_array=#()
	Normal_array=#()
	
	ukwStringLength = readbyte f
	ukwString = ReadFixedString f ukwStringLength	--MeshRSD
	ukwID = readlong f
	null = readshort f
	
	ukwStringLength2 = readbyte f
	ukwString2 = ReadFixedString f ukwStringLength2	--RSDBlendedDX11
	ukw = readlong f	-- 0x0b000b00 
	fvf = readshort f -- fvf?
	ukw3 = readshort f -- 0x21
	
	--			fvf			--
	/**********************
	1 = position
	2 = skin
	3 = uv/normals
	4 = 
	5 = uv/normals
	6 =
	7 =
	8 =
	9 =
	10 =
	**********************/
	
-- 	printBinary fvf 16
-- 	printHex ukw2
	
	boneCount = readlong f 
	boneName = for y=1 to boneCount collect (ReadFixedString f (readbyte f))
	for y=1 to boneCount do (ReadFixedByteString f 0x18 0 0)
-- 	format "boneCount: %\n" (bit.intashex(boneCount as integer))
	
	vertStride = readlong f
	vertCount = readlong f
	vertElmCount = readlong f
	format "vertStride: %	vertCount: %	vertElmCount: %\n" (bit.intashex(vertStride as integer)) (bit.intashex(vertCount as integer)) (bit.intashex(vertElmCount as integer))
	
	vertPos = 0
	vertNorm = 0
	vertSkin = 0
	vertUV = 0
	format "vertOffset: %\n" (bit.intashex((ftell f) as integer))
	for y=1 to vertElmCount do (
		elmSize = readbyte f
-- 		printHex elmSize
		case elmSize of (
			0x04:(
				for z=1 to vertCount do fseek f 0x04 #seek_cur
			)
			0x08:(
				if (bit.get fvf 2) == true and vertSkin == 0 then (
					for z=1 to vertCount do (
-- 						ReadFixedByteString f 0x08 1 1
						w1 = readbyte f
						w2 = readbyte f
						w3 = readbyte f
						w4 = readbyte f
						b1 = readbyte f
						b2 = readbyte f
						b3 = readbyte f
						b4 = readbyte f
					)
					vertSkin = 1
					continue
				)
				if (bit.get fvf 5) == true and vertUV == 0 then (
					for z=1 to vertCount do (
						tu = readfloat f
						tv = readfloat f
						
						append UV_array[tu,1-tv,0]
					)
					vertUV = 1
					continue
				)
				else (
					for z=1 to vertCount do fseek f 0x08 #seek_cur
				)
			)
			0x0c:(
				if (bit.get fvf 1) == true and vertPos == 0 then (
					for z=1 to vertCount do (
						vx = readfloat f
						vy = readfloat f
						vz = readfloat f
						
						append Vert_array([vx,vy,vz]*fscale)
					)
					vertPos = 1
					continue
				)
				if (bit.get fvf 3) == true and vertNorm == 0 then (
					for z=1 to vertCount do (
						nx = readfloat f
						ny = readfloat f
						nz = readfloat f
						
						append Normal_array[nx,ny,nz]
					)
					vertNorm = 1
					continue
				)
				else (
					
					for z=1 to vertCount do fseek f 0x0c #seek_cur
				)
			)
			default:(
				printHere f
				exit
			)
		)
	)
-- 	format "elm4: %	elm8: %	elmC: %	\n" elmSize4 elmSize8 elmSizeC
	format "faceOffset: %\n" (bit.intashex((ftell f) as integer))
	faceCount = readlong f
	for y=1 to faceCount / 3 do(
		fa=readshort f +1
		fb=readshort f +1
		fc=readshort f +1
		append Face_array[fa,fb,fc]
	)
	
	--crashes here sometimes
	format "ukwOffset: %\n" (bit.intashex((ftell f) as integer))
	ukwCount = readlong f
	for y=1 to ukwCount do (
		ukwCount = readbyte f #unsigned
		if ukwCount == 0 then (
			fseek f 0x7 #seek_cur
		)
		else (
			ukw2 = for y=1 to ukwCount collect (readbyte f)
		)
		ukw3 = for y=1 to 6 collect (readlong f)	-- offsets?
	)
	
	msh = mesh vertices:Vert_array faces:Face_array
	msh.numTVerts = UV_array.count
	buildTVFaces msh
	for j = 1 to UV_array.count do setTVert msh j UV_array[j]
	for j = 1 to Face_array.count do setTVFace msh j Face_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	format "\n"
)
	
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f