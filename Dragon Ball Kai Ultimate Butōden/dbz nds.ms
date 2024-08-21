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
	print (bit.intashex(num as integer))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
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
fn buildFaces vertexCount vertSum sectionType matID &Face_Array &MatID_Array= (	
	if sectionType == 4 do (
		a = 0
		b = 0
		c = 0
		d = 0
		
		for x=1 to vertexCount by 4 do (
			a = x
			b = x + 1
			c = x + 2
			d = x + 3
			
			append Face_array ([a,b,c] + vertSum)
			append Face_array ([a,c,d]  + vertSum)
			append MatID_Array (matID + 1)
			append MatID_Array (matID + 1)
		)
	)

	if sectionType == 3 do (
		
		a=0
		b=0
		c=0
		
		for x=1 to vertexCount by 3 do (
			a = x
			b = x + 1
			c = x + 2
			append Face_Array ([a,b,c] + vertSum)
			append MatID_Array (matID + 1)
		)
	)
	
	return Face_Array
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
fn AlignOffset fstream relativeoffset alignment = (
	if (mod relativeoffset alignment) != 0 do (
		align = (alignment - (mod relativeoffset alignment))
		align = fseek fstream align #seek_cur
	)
)  

-- fname = @"D:\dbz nds\ultimate butoden\archiveDBK.dsa\mdl\chr\101300_tien.dse\101300_tien.dse"
-- fname = @"D:\dbz nds\ultimate butoden\archiveDBK.dsa\mdl\chr\101100_goku.dse\101100_goku.dse"
-- fname=@"D:\models\ripped\dbz nds\ultimate butoden\archiveDBK.dsa\mdl\chr\101100_goku.dse\101100_goku.dse"
-- fname=@"D:\models\ripped\dbz nds\ultimate butoden\archiveDBK.dsa\mdl\chr\101103_goku_s3.dse\101103_goku_s3.dse"
-- fname=@"D:\models\ripped\dbz nds\ultimate butoden\archiveDBK.dsa\mdl\chr\102100_bardock.dse\102100_bardock.dse"
-- fname=@"D:\models\ripped\dbz nds\ultimate butoden\archiveDBK.dsa\mdl\chr\44641_recoome_krillin.dse\44641_recoome_krillin.dse"
fname = GetOpenFileName caption:"" types:" (*.dse)|*.dse" historyCategory:""
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

struct data1 (
	m11 = readlong f / 4096.0, m12 = readlong f / 4096.0, m13 = readlong f / 4096.0,
	m21 = readlong f / 4096.0, m22 = readlong f / 4096.0, m23 = readlong f / 4096.0,
	m31 = readlong f / 4096.0, m32 = readlong f / 4096.0, m33 = readlong f / 4096.0,
	m41 = readlong f / 4096.0, m42 = readlong f / 4096.0, m43 = readlong f / 4096.0,
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
)
struct data2 (
	ukw = readshort f,							--0201
	ukw2 = readlong f,						--offset?
	ukw3 = readshort f,						--0001
	boneNameOffset = readlong f,		--geoshape/geol
	boneParentID = readshort f,
	boneSiblingID = readshort f,
	boneOffset = readlong f					--offset to element within data1
)
struct data3 (
	meshNameOffset = readlong f,
	meshOffset = readlong f,
	ukw = readshort f,							--0x60/0x61
	ukw2 = readbyte f,						--null
	ukw3 = readbyte f,
	ukw4 = readshort f,
	meshScale = (2 ^ (readshort f))
)
struct data4 (
	meshNameOffset = readlong f,
	meshBoneId = readlong f,
	meshId = readlong f,
	null = readlong f
)
struct data5 (
	matNameOffset = readlong f,
	skip = fseek f 0x03 #seek_cur,
	ukwId = readbyte f,
	skip2 = fseek f 0x08 #seek_cur,
	ukwId2 = readbyte f,
	skip3 = fseek f 0x13 #seek_cur
)
struct data6 (
	texPathOffset = readlong f,
	ukwOffset2 = readlong f,		--is after ukwOffset
	ukw = readlong f,
	ukwLength2 = readlong f,
	ukwOffset = readlong f,
	ukwLength = readlong f,
	ukw3 = readshort f,				--texWidth?
	ukw4 = readshort f,				--texHeight?
	null = readlong f,
	null2 = readlong f,
	ukw5 = readshort f,				--always 4
	ukw6 = readshort f,
	texNameOffset = readlong f,	--substring of texPath
	ukw7 = readlong f					--length?
)
struct data8 (
	ukw = readlong f,	--longs?
	ukw2 = readlong f,
	ukw3 = readlong f
)

magic = ReadFixedString f 0x04
fseek f 0x1a #seek_cur

ukw = readshort f
ukw2 = readshort f
boneCount = readshort f
meshCount = readshort f
meshCount2 = readshort f
matCount = readshort f
texCount = readshort f

boneDataOffset = readlong f
boneDataOffset2 = readlong f
meshDataOffset = readlong f
meshDataOffset2 = readlong f
matDataOffset = readlong f
texDataOffset = readlong f
stringBufferOffset = readlong f

ukwOffset8 = readlong f				--another baseOffset? / null
stringBufferOffset2 = readlong f	--another baseOffset? / same as stringBufferOffset
stringBufferLength = readlong f
fileNameOffset = readlong f		--rel to stringBufferOffset
dataOffset8 = readlong f
dataOffset9 = readlong f			--texture?
fileEndOffset = readlong f

baseOffset = ftell f
printhex baseOffset

format "boneCount: %	meshCount: %	matCount: %	texCount: %\n" boneCount meshCount matCount texCount

fseek f (boneDataOffset + baseOffset) #seek_set
boneDataArray = for x=1 to boneCount collect (data = data1())

fseek f (boneDataOffset2 + baseOffset) #seek_set
boneDataArray2 = for x=1 to boneCount collect (data = data2())
	
fseek f (meshDataOffset + baseOffset) #seek_set
meshDataArray = for x=1 to meshCount collect (data = data3())
	
fseek f (meshDataOffset2 + baseOffset) #seek_set
meshData2Array = for x=1 to meshCount2 collect (data = data4())
	
fseek f (matDataOffset + baseOffset) #seek_set
matDataArray = for x=1 to matCount collect (ReadFixedByteString f 0x24 1 1 ; data = data5())
	
fseek f (texDataOffset + baseOffset) #seek_set
texDataArray = for x=1 to texCount collect (data = data6())
	
fseek f (dataOffset8) #seek_set
ukwData8 = for x=1 to boneCount collect (data = data8())


multiMat = multimaterial()
multiMat.numSubs = matCount
meditMaterials[1] = multiMat
for x=1 to matCount do (
	mat = matDataArray[x]
	multiMat[x].Diffuse = random black white
	multiMat[x].name = (getName f (mat.matNameOffset + baseOffset + stringBufferOffset))
)	

for x=1 to boneCount do (
	format "% %\n" (x) (getName f (boneDataArray2[x].boneNameOffset + baseOffset + stringBufferOffset))
)


BNArr=#()
for x=1 to boneCount do (
	boneData = boneDataArray[x]
	boneData2 = boneDataArray2[x]
	
	parentID = boneData2.boneParentID + 1
	tfm = boneData.tfm
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = inverse tfm
	newBone.name = (getName f (boneData2.boneNameOffset + baseOffset + stringBufferOffset))
 	
	--newBone.position = -tfm.row4
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if parentID != 0 do newBone.parent = BNArr[parentID]
	
	append BNArr newBone	
)
for b in BNArr where b.parent==undefined do 
	b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])


matID = 0

print meshcount
for x=1 to meshCount do (	--meshCount
	meshData = meshDataArray[x]
	meshData2 = meshData2Array[x]
	fseek f (meshData.meshOffset + baseOffset) #seek_set
	print x
-- 	printhere f
-- 	format "%\n%\n\n" (getName f (meshData.meshNameOffset + baseOffset + stringBufferOffset)) (getName f (meshData2.meshNameOffset + baseOffset + stringBufferOffset))
-- 	format("%\n") (getName f (meshData.meshNameOffset + baseOffset + stringBufferOffset))
-- 	format "started at %\n" (bit.intashex(ftell f as integer))
-- 	print meshData
-- 	print meshData2
	
	vertSum = 0
	
	y = 0
	while true do (	--per sectionType
		Vert_Array=#()
		UV_Array=#()
		Face_Array=#()
		Normal_Array=#()
		MatId_Array=#()
		
		y += 1
		--print y
		ReadFixedByteString f 0x08 1 0
		sectionType = readbyte f
		ukw = readbyte f
		ukw2 = readbyte f
		ukw3 = readbyte f	--if sectionType is 2 then 0x7c for 3 or 4 is weight inflience count
		sectionLength = readlong f
		
		if sectionType == 0x03 or sectionType == 0x04 then (
			ReadFixedByteString f 0x18 1 0
			
			vertexCount = readshort f
			vertexStride = readbyte f
			vertexType = readbyte f
			
			ukw4 = readlong f	--only see it as non null if ukw2 is non null
			boneMap = for y=1 to ukw3 collect readshort f
			
			fseek f (0x10 - (2 * ukw3)) #seek_cur	--array w/ length of ukw2?, byte aligned?
			
			if boneMap.count != 0 do print boneMap #nomap
			
 			format "%%\n" (bit.intashex(vertexStride)) (bit.intashex(vertexType))
			--1 - pos
			--2 - 
			--3 - u1-2h, n1
			--4 - uvs
			--5 - weights
			--6 - u1-4b
			--7 - 
			--8 - 
			print (bit.get vertexType 3)
			for z=1 to vertexCount do (
				fseek f vertexStride #seek_cur
-- 				if (bit.get vertexType 6) == true do (
-- 					ukw1 = readbyte f
-- 					ukw2 = readbyte f
-- 					ukw3 = readbyte f
-- 					ukw4 = readbyte f
-- 				)
-- 				tu = 0
-- 				tv = 0
-- 				if (bit.get vertexType 5) == true do (
-- 					tu = readshort f / 4096.0
-- 					tv = readshort f / 4096.0
-- 					
-- 					append UV_Array([tu,1-tv,0])
-- 				)
-- 				if (bit.get vertexType 3) == true do (
-- 					
-- 				)
				
			)
			AlignOffset f (ftell f) 4
			
		)
		else if sectionType == 0x02 then (
			matID = ukw2
		)
		else if sectionType == 0x01 then (
			exit
		)
		else (
			print ("oops")
			print sectionType
		)
		--format "\n"
	)
)

Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f