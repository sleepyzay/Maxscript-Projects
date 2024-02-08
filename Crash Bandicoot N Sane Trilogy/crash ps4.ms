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
   if var == 1 do fseek f -fixedLen #seek_cur
   if var2 == 1 do print str
)
fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream as integer))as string))
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
fn ReadUntilOffset bstream offset = (
	local str = ""
	while ((ftell bstream) < offset) do (
		str += bit.intAsChar (ReadByte bstream #unsigned)
	)
   str
)
fn ReadUntilChar bstream char = (
	str = ""
	testChar = ""
	
	t=0
	
	while(testChar != char) 
	do (
		t+=1
		testChar = ReadFixedString bstream 1
		str += testChar
		
		if t > 50 do exit	--failsafe
	)
	str = trimright str char
	str
-- 	print str
	
)
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)
fn ReadHalfFloat fstream = (
    hf=readshort fstream #unsigned
    sign = bit.get hf 16
    exponent = (bit.shift (bit.and hf (bit.hexasint "7C00")) -10) as integer - 16
    fraction = bit.and hf (bit.hexasint "03FF")
    if sign==true then sign = 1 else sign = 0
    exponentF = exponent + 127
    outputAsFloat = bit.or (bit.or (bit.shift fraction 13) \
    (bit.shift exponentF 23)) (bit.shift sign 31)
return bit.intasfloat outputasfloat*2
)
fn Readword fstream = (
return readshort fstream #unsigned
)


fname = GetOpenFileName caption:"Crash PS4" types:"Crash PS4 (*.igz.)|*.igz" historyCategory:""
-- fname=@"C:\Users\Xavier\Desktop\crash pak\AkuAku.igz"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=1
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

dataOffset=#()
dataLength=#()
dataCount=#()

magic = readlong f
fileVer = readlong f
ukw = readlong f	--hash?
ukw2 = readlong f

for x=1 to 3 do (
	dataCount[x] = readlong f
	ukw2 = readlong f
	dataOffset[x] = readlong f
	dataLength[x] = readlong f
)
for o in dataOffset do printHex o
format "\n"

--info
matCount=0
stringArr=#()
stringArr2=#()
fseek f dataOffset[1] #seek_set
for x=1 to dataCount[1] do (
	chunkOffset = ftell f as integer
	chunkTag = ReadFixedString f 4
	chunkDataCount = readlong f
	chunkLength = readlong f
	chunkDataOffset = readlong f
	chunkEnd = chunkOffset + chunkLength
	
	
	case chunkTag of (
		"TSTR":(
			for y=1 to chunkDataCount do (
				stringArr2[y] = readstring f
				AlignOffset f (ftell f) 2
				
-- 				format "%	%\n" (bit.intashex(y-1)) stringArr2[y]
			)
		)
		"EXNM":(
			matCount = chunkDataCount
			for y=1 to chunkDataCount do (
				ukw = readlong f
				ukw2 = readshort f
				ukw3 = readshort f
			)
		)
		default:(
			
		)
	)
	
	format "chunkTag: %	chunkOffset: 0x%	chunkLength: 0x%\n" (chunkTag) (bit.intashex(chunkOffset)) (bit.intashex(chunkLength))	
	fseek f chunkEnd #seek_set
)

--data
fseek f (0x30 + dataOffset[2]) #seek_set
subDataOffset = readlonglong f + dataOffset[2]
fseek f subDataOffset #seek_set
fseek f 0x28 #seek_cur

boneDataOffset = readlonglong f + dataOffset[2]
meshDataOffset = readlonglong f + dataOffset[2]
ukwDataOffset = readlonglong f + dataOffset[2]
null = readlonglong f
fseek f 0x18 #seek_cur	--bb info

fseek f boneDataOffset #seek_set
ukw = readlonglong f	--4
ukw = readlonglong f	--1
ukw = readlonglong f	--count?/ID?/stringRelated?

boneDataTableOffset = readlonglong f + dataOffset[2]
boneDataLength = readlong f	--length of bone matrices
ukw = readlong f
boneOffset = readlonglong f + dataOffset[2]

fseek f boneDataTableOffset #seek_set
ukw = readlonglong f	--5
ukw = readlong f		--1
boneCount = readlong f
boneCount2 = readlong f
null = readlong f
boneTableLength = readlong f
ukw = readlong f		--1001/BE
boneTableOffset = readlonglong f + dataOffset[2]

print boneCount
print boneCount2

ukwID3=#()
ukwID4=#()
boneStringID=#()
fseek f boneTableOffset #seek_set
boneDataOffset = for x=1 to boneCount2 collect (readlonglong f #unsigned + dataOffset[2])
for x=1 to boneCount2 do (
	fseek f boneDataOffset[x] #seek_set
	ReadFixedByteString f 0x30 1 0
	
	ukw = readlonglong f	--6
	ukw2 = readlonglong f --1
	boneStringID[x] = readlonglong f #unsigned + 1 --TSTR
	ukwID3[x] = readlong f #unsigned + 1
	ukwID4[x] = readlong f #unsigned + 1
	ukw = readfloat f
	ukw2 = readfloat f
	ukw3 = readfloat f
	ukw4 = readfloat f
)

BNArr = #()
fseek f boneOffset #seek_set
for x=1 to boneCount2 do (
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [m14,m24,m34]	
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.01
	newBone.height = 0.01
	newBone.wirecolor = yellow
	newbone.showlinks = false
	newBone.transform = tfm
-- 	newBone.name = stringArr2[boneStringID[x]]
	
	pos = [m41,m42,m43]
	pos *= tfm
	newBone.pos += (fscale*-pos)
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
-- 	format "% %\n" ukwID3[x] ukwID4[x]
	
-- 	if (ukwID3[x] != 0) then (
-- 		newBone.parent = BNArr[ukwID3[x]]
-- 	)
	append BNArr newBone
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [0,-1,0] [1,0,0] [0,0,1] [0,0,0])

multiMat = multimaterial()
multiMat.numSubs = matCount
meditMaterials[1] = multiMat

fseek f meshDataOffset #seek_set
fseek f 0x80 #seek_cur	--may change based on file

meshTableOffset = readlonglong f + dataOffset[2]
meshCount = readlonglong f
nullMeshDataLength = readlong f
ukw = readlong f		--1
nullMeshDataOffset2 = readlonglong f + dataOffset[2] --null at offset
fseek f 0x18 #seek_cur	--null
ukwMeshDataCount = readlonglong f
ukwMeshDataLength = readlong f
ukw2 = readlong f		--1
ukwMeshDataOffset = readlonglong f + dataOffset[2]

fseek f meshTableOffset #seek_set
meshDataOffsetArr = for x=1 to meshCount collect (readlonglong f + dataOffset[2])
for x=1 to meshCount do (
	fseek f meshDataOffsetArr[x] #seek_set
	
	fseek f 0x40 #seek_cur
	matID = readshort f + 1
	ukw = readshort f	--8000
	null = readlong f
	vertDataOffset = readlonglong f + dataOffset[2]
	faceDataOffset = readlonglong f + dataOffset[2]
	null = readlonglong f
	ukwStart = readshort f	--offset?
	ukwCount = readshort f	--length, increases by 0x19
	null = readlonglong f
	ukw = readlong f	--17fdc
	
-- 		printHex vertDataOffset
-- 		printHex faceDataOffset
	
	multiMat.materialList[matID].Diffuse = random black white
-- 	multiMat.materialList[matID].name = stringArr2[matID + matCount]
	
	fseek f vertDataOffset #seek_set
	fseek f 0x20 #seek_cur
	subVertDataOffset = readlonglong f + dataOffset[2]
	fseek f subVertDataOffset #seek_set
	
	ukw = readlonglong f	--a
	ukw2 = readlong f		--1/count?
	vertCount = readlong f	--vertbufferCount?
	ukw3 = readlong f	--4
	ukw4 = readlong f	--1/BE
	subVertDataOffset2 = readlonglong f + dataOffset[2]	--vertCountArr?
	vertLength = readlong f	--length of buffer
	ukw5 = readlong f	--3/BE
	vertOffset = (readlonglong f #unsigned - 0x8000000) + dataOffset[3]
	subVertDataOffset3 = readlonglong f #unsigned + dataOffset[2]
-- 	printHex subVertDataOffset3
	
	fseek f subVertDataOffset3 #seek_set
	ukw6 = readlonglong f	--b
	ukw7 = readlong f	--1
	vertStride = readlong f
	
	fseek f faceDataOffset #seek_set
-- 	print (bit.intashex((ftell f) - dataOffset[2]))
	fseek f 0x20 #seek_cur
	subFaceDataOffset = readlonglong f #unsigned + dataOffset[2]
	
	fseek f subFaceDataOffset #seek_set
-- 	ReadFixedByteString f 0x34 1 1
	ukw = readlonglong f	--e
	ukw2 = readlong f	--1
	faceCount = readlong f	--faceBufferCount?
	ukw3 = readlong f	--4
	ukw4 = readlong f	--1/BE
	ukwFaceDataOffset = readlonglong f + dataOffset[2]	--faceCountArr?
	faceLength = readlong f
	ukw5 = readlong f	--3/BE
	faceOffset = (readlonglong f #unsigned - 0x8000000) + dataOffset[3]
	faceSize = readlong f
	
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	MatID_Array=#()
	Color_Array=#()
	
	format "vertOffset: 0x%	vertStride: 0x%\n" (bit.intashex(vertOffset)) (bit.intashex(vertStride))
	
	fseek f vertOffset #seek_set
	if vertStride == 0x30 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			bone1 = readbyte f + 1
			bone2 = readbyte f + 1
			bone3 = readbyte f + 1
			bone4 = readbyte f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x34 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			cr = readbyte f
			cg = readbyte f
			cb = readbyte f
			ca = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			bone1 = readbyte f + 1
			bone2 = readbyte f + 1
			bone3 = readbyte f + 1
			bone4 = readbyte f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
			append Color_Array (color cr cg cb)
		)
	)
	if vertStride == 0x38 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readbyte f + 1
			bone2 = readbyte f + 1
			bone3 = readbyte f + 1
			bone4 = readbyte f + 1
			bone5 = readbyte f + 1
			bone6 = readbyte f + 1
			bone7 = readbyte f + 1
			bone8 = readbyte f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x3c do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			cr = readbyte f
			cg = readbyte f
			cb = readbyte f
			ca = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readbyte f #unsigned
			bone2 = readbyte f #unsigned
			bone3 = readbyte f #unsigned
			bone4 = readbyte f #unsigned
			bone5 = readbyte f #unsigned
			bone6 = readbyte f #unsigned
			bone7 = readbyte f #unsigned
			bone8 = readbyte f #unsigned
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x40 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			cr = readbyte f
			cg = readbyte f
			cb = readbyte f
			ca = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
			append Color_Array (color cr cg cb)
		)
	)
	if vertStride == 0x44 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			tx = readfloat f
			ty = readfloat f
			tz = readfloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readbyte f #unsigned
			bone2 = readbyte f #unsigned
			bone3 = readbyte f #unsigned
			bone4 = readbyte f #unsigned
			bone5 = readbyte f #unsigned
			bone6 = readbyte f #unsigned
			bone7 = readbyte f #unsigned
			bone8 = readbyte f #unsigned
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x4c do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			cr = readbyte f
			cg = readbyte f
			cb = readbyte f
			ca = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			tx = readfloat f
			ty = readfloat f
			tz = readfloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
			append Color_Array (color cr cg cb)
		)
	)
	if vertStride == 0x48 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			w4 = readfloat f
			w5 = readfloat f
			w6 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x50 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			bone5 = readlong f + 1
			bone6 = readlong f + 1
			bone7 = readlong f + 1
			bone8 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x54 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			cr = readbyte f
			cg = readbyte f
			cb = readbyte f
			ca = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			bone5 = readlong f + 1
			bone6 = readlong f + 1
			bone7 = readlong f + 1
			bone8 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
			append Color_Array (color cr cg cb)
		)
	)
	if vertStride == 0x5c do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			tx = readfloat f
			ty = readfloat f
			tz = readfloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			bone5 = readlong f + 1
			bone6 = readlong f + 1
			bone7 = readlong f + 1
			bone8 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
		)
	)
	if vertStride == 0x60 do (
		for x=1 to vertCount do (
			vx = readfloat f
			vy = readfloat f
			vz = readfloat f
			nx = readfloat f
			ny = readfloat f
			nz = readfloat f
			cr = readbyte f
			cg = readbyte f
			cb = readbyte f
			ca = readbyte f
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			tx = readfloat f
			ty = readfloat f
			tz = readfloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			weight5 = readbyte f #unsigned
			weight6 = readbyte f #unsigned
			weight7 = readbyte f #unsigned
			weight8 = readbyte f #unsigned
			bone1 = readlong f + 1
			bone2 = readlong f + 1
			bone3 = readlong f + 1
			bone4 = readlong f + 1
			bone5 = readlong f + 1
			bone6 = readlong f + 1
			bone7 = readlong f + 1
			bone8 = readlong f + 1
			w1 = readfloat f
			w2 = readfloat f
			w3 = readfloat f
			
			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,1-tv,0]
			append Color_Array (color cr cg cb)
		)
	)
	
	fseek f faceOffset #seek_set
	if faceSize == 1 do (
		for b=1 to (faceCount/3) do (
			fa = readshort f #unsigned + 1
			fb = readshort f #unsigned + 1
			fc = readshort f #unsigned + 1
			
			append Face_Array[fa,fb,fc]
			append MatID_Array matID
		)
	)
	if faceSize == 2 do (
		for b=1 to (faceCount/3) do (
			fa = readlong f #unsigned + 1
			fb = readlong f #unsigned + 1
			fc = readlong f #unsigned + 1
			
			append Face_Array[fa,fb,fc]
			append MatID_Array matID
		)
	)
	
	msh = mesh vertices:Vert_Array faces:Face_Array materialIDs:MatID_Array
	msh.name = (bit.intashex(vertStride))
	msh.numTVerts = UV_Array.count
	msh.mat = multiMat
	
	buildTVFaces msh
	setNumCPVVerts msh vertCount
-- 	if Color_array.count > 0 do (
-- 		defaultVCFaces msh
-- 		setCVertMode msh true
-- 		setShadeCVerts msh true
-- 	)
	for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
	for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
	for j = 1 to Color_array.count do setVertColor msh j Color_array[j]
	for j = 1 to Normal_array.count do setNormal msh j Normal_array[j]
	msh.transform = (matrix3 [0,-1,0] [1,0,0] [0,0,1] [0,0,0])
)


fseek f ukwMeshDataOffset #seek_set
ukwMeshDataArr = for x=1 to ukwMeshDataCount collect (readlong f)	--ID's?/Index?


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f