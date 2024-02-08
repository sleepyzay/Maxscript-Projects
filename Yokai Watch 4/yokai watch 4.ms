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

-- fname=@"C:\Users\Xavier\Documents\stuff\projects\tools\XCI_NCA_NSP_v2\ncaDecrypted\data\common\chara\chara_files\data\common\chr\i05010000\i05010000.g4pkm"
-- gname=@"C:\Users\Xavier\Documents\stuff\projects\tools\XCI_NCA_NSP_v2\ncaDecrypted\data\common\chara\chara_files\data\common\chr\i05010000\i05010000.g4mg"
-- fname=@"E:\stuff\tools\XCI_NCA_NSP_v2\yokai watch\data\common\chara\chara_files\data\common\chr\y02380000\y02380000.g4pkm"

fname = GetOpenFileName caption:"" types:" (*.)|*.g4pkm" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FilePath = getFileNamePath fname

gname = (FilePath + FileName + ".g4mg")
g = fopen gname "rb"


clearlistener()
Global fscale=10

print gname

delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

G4PK = ReadFixedString f 4

fseek f 0x48 #seek_set
skelLength = readlong f
modelLength = readlong f

fseek f 0x80 #seek_set
skelOffset = ftell f
G4SK = ReadFixedString f 4
boneOffset = readshort f #unsigned + skelOffset
ukw = readlong f
ukw2 = readshort f
ukw3 = readlong f
fseek f 0x10 #seek_cur	--null
boneCount = readshort f
ukw4 = readshort f

fseek f boneOffset #seek_set

BNArr = #()
for x=1 to boneCount do (
	
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [m14,m24,m34]	
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = tfm
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
-- 	if (ParentID[x] != 0) then (
-- 	newBone.parent = BNArr[ParentID[x]]
-- 	)
	append BNArr newBone
)

for x=1 to boneCount do (
	fseek f 0x30 #seek_cur
)
for x=1 to boneCount do (
	fseek f 0x30 #seek_cur
)

fseek f 0x30 #seek_cur

ukwArr = for x=1 to boneCount collect (readlong f)
boneCount2 = readlong f
boneID = for x=1 to (boneCount * 2) collect (readshort f)
ukwID = for x=1 to boneCount collect (readbyte f)

AlignOffset f (ftell f) 16
fseek f -4 #seek_cur

printHere f
printHex boneCount




fseek f (skelOffset + skelLength) #seek_set

AlignOffset f (ftell f) 16
test = readlong f
if test == 0 then AlignOffset f (ftell f) 16
else fseek f -4 #seek_cur

modelOffset = ftell f
G4MD = ReadFixedString  f 4
meshDataOffset = readshort f #unsigned + modelOffset
ukw = readlong f
ukw2 = readshort f
ukw3 = readlong f
fseek f 0x10 #seek_cur	--null
meshCount = readshort f
ukw4 = readshort f
ukw5 = readshort f
ukw6 = readlong f
ukw7 = readshort f
null = readlong f
fseek f 0x20 #seek_cur
vertBufferLength = readlong f
faceBufferLength = readlong f
vertBufferOffset = readlong f
faceBufferOffset = readlong f

fseek f meshDataOffset #seek_set
for x=1 to meshCount do (
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	
	vertOffset = readlong f #unsigned
	faceOffset = readlong f #unsigned
	vertCount = readlong f #unsigned
	faceCount = readlong f #unsigned
	fseek f 0x20 #seek_cur
	ukw = readlong f
	ukw2 = readlong f	--ff's
	ukw3 = readshort f
	ukw4 = readshort f
	ukw5 = readbyte f
	ukw6 = readbyte f
	vertStride = readbyte f
	ukw9 = readbyte f
	null = readshort f
	ukw7 = readbyte f
	ukw8 = readbyte f
	fseek f 0x0c #seek_cur	--null
	
	printHex vertStride
	printHex (vertOffset + vertBufferOffset)
	format "\n"
	
	fseek g (vertOffset + vertBufferOffset) #seek_set
	if vertStride == 0x30 do (--
		for y=1 to vertCount do (
			vx = readfloat g
			vy = readfloat g
			vz = readfloat g
			ukw = readlong g
			weight1 = readbyte g
			weight1b = readbyte g
			weight2 = readbyte g
			weight2b = readbyte g
			weight3 = readbyte g
			weight3b = readbyte g
			weight4 = readbyte g
			weight4b = readbyte g
			fseek g 0x08 #seek_cur	--null/prob more boneID's
			bone1 = readbyte g
			bone1b = readbyte g
			bone2 = readbyte g
			bone2b = readbyte g
			bone3 = readbyte g
			bone3b = readbyte g
			bone4 = readbyte g
			bone4b = readbyte g
			dontCare = readlong g
			tu = readshort g #unsigned /65535.0
			tv = readshort g #unsigned /65535.0

			append Vert_Array([vx,vy,vz]*fscale)
			append UV_Array[tu,tv,0]
		)
	)
	if vertStride == 0x3c do (--
		for y=1 to vertCount do (
			vx = readfloat g
			vy = readfloat g
			vz = readfloat g
			nx = readshort g
			ny = readshort g
			nz = readshort g
			nw = readshort g
			tx = readshort g
			ty = readshort g
			tz = readshort g
			tw = readshort g
			weight1 = readbyte g
			weight1b = readbyte g
			weight2 = readbyte g
			weight2b = readbyte g
			weight3 = readbyte g
			weight3b = readbyte g
			weight4 = readbyte g
			weight4b = readbyte g
			fseek g 0x08 #seek_cur	--null/prob more boneID's
			bone1 = readbyte g
			bone1b = readbyte g
			bone2 = readbyte g
			bone2b = readbyte g
			bone3 = readbyte g
			bone3b = readbyte g
			bone4 = readbyte g
			bone4b = readbyte g
			dontCare = readlong g
			tu = readshort g #unsigned /65535.0
			tv = readshort g #unsigned /65535.0

			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,tv,0]
		)
	)
	if vertStride == 0x40 do (--
		for y=1 to vertCount do (
			vx = readfloat g
			vy = readfloat g
			vz = readfloat g
			nx = readshort g
			ny = readshort g
			nz = readshort g
			nw = readshort g
			tx = readshort g
			ty = readshort g
			tz = readshort g
			tw = readshort g
			weight1 = readbyte g
			weight1b = readbyte g
			weight2 = readbyte g
			weight2b = readbyte g
			weight3 = readbyte g
			weight3b = readbyte g
			weight4 = readbyte g
			weight4b = readbyte g
			fseek g 0x08 #seek_cur	--null/prob more boneID's
			bone1 = readbyte g
			bone1b = readbyte g
			bone2 = readbyte g
			bone2b = readbyte g
			bone3 = readbyte g
			bone3b = readbyte g
			bone4 = readbyte g
			bone4b = readbyte g
			fseek g 0x08 #seek_cur
			tu = readshort g #unsigned /65535.0
			tv = readshort g #unsigned /65535.0

			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,tv,0]
		)
	)
	if vertStride == 0x44 do (--
		for y=1 to vertCount do (
			vx = readfloat g
			vy = readfloat g
			vz = readfloat g
			nx = readshort g
			ny = readshort g
			nz = readshort g
			nw = readshort g
			tx = readshort g
			ty = readshort g
			tz = readshort g
			tw = readshort g
			weight1 = readbyte g
			weight1b = readbyte g
			weight2 = readbyte g
			weight2b = readbyte g
			weight3 = readbyte g
			weight3b = readbyte g
			weight4 = readbyte g
			weight4b = readbyte g
			fseek g 0x08 #seek_cur	--null/prob more boneID's
			bone1 = readbyte g
			bone1b = readbyte g
			bone2 = readbyte g
			bone2b = readbyte g
			bone3 = readbyte g
			bone3b = readbyte g
			bone4 = readbyte g
			bone4b = readbyte g
			fseek g 0x08 #seek_cur
			tu = readshort g #unsigned /65535.0
			tv = readshort g #unsigned /65535.0
			tu2 = readshort g #unsigned /65535.0
			tv2 = readshort g #unsigned /65535.0

			append Vert_Array([vx,vy,vz]*fscale)
			append Normal_Array[nx,ny,nz]
			append UV_Array[tu,tv,0]
		)
	)
	if vertStride == 0x48 do (
		for y=1 to vertCount do (
			vx = readfloat g
			vy = readfloat g
			vz = readfloat g
			
			fseek g (vertStride - 0x0c) #seek_cur
			
			append Vert_Array([vx,vy,vz]*fscale)
			append UV_Array[0,0,0]
		)
	)
	if vertStride == 0x4c do (
		for y=1 to vertCount do (
			vx = readfloat g
			vy = readfloat g
			vz = readfloat g
			
			fseek g (vertStride - 0x0c) #seek_cur
			
			append Vert_Array([vx,vy,vz]*fscale)
			append UV_Array[0,0,0]
		)
	)
	
	fseek g (faceOffset + faceBufferOffset) #seek_set
	for b=1 to (faceCount/3) do (
		fa = readshort g #unsigned + 1
		fb = readshort g #unsigned + 1
		fc = readshort g #unsigned + 1
		
		append Face_Array[fa,fb,fc]
	)
	
	msh = mesh vertices:Vert_Array faces:Face_Array
	msh.name = (bit.intashex(vertStride))
	msh.numTVerts = UV_Array.count
	buildTVFaces msh
	for j = 1 to UV_Array.count do setTVert msh j UV_Array[j]
	for j = 1 to Face_Array.count do setTVFace msh j Face_Array[j]
	for j = 1 to Normal_Array.count do setNormal msh j Normal_Array[j]
	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
)


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
fclose g