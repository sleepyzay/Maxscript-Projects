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
fn printMatrix bstream = (
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	ReadFixedByteString bstream 0x10 0 1
	fseek f -0x40 #seek_cur
	format "\n"
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

-- fname = GetOpenFileName caption:"" types:" (*.skel)|*.skel" historyCategory:""
fname = @"C:\Users\Xavier\Downloads\JPKGReader-0.1.0\JPKGReader-0.1.0\JPKGReader\bin\Debug\net7.0\output\download\00000153.skel"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=50
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

skel = ReadFixedString f 4
fileSize = readlong f
unk = readlong f
null = readlong f

tableCount = readshort f
--these three almost add up to tableCount
unkCount = readshort f		--nodes in scene related
unkCount2 = readshort f	--bone count?
unkCount3 = readshort f	--root related?
tableOffset = readlong f
boneIdOffset = readlong f
boneNameBufferOffset = readlong f
unk8 = readshort f				--count?/index?/same as unkCount
unk9 = readshort f				--count?/index?/same as unkCount
unk10 = readshort f			--2/rootCount?/there are two roots, maybe has something to do w/ the two counts
skelIndex = readshort f		--count?/index?/is sum of unk9 and unk10
boneCount = readlong f		--short?/count?/index?/same as unkCount

fseek f boneIdOffset #seek_set
boneIdArray = for x=1 to unkCount2 collect (readshort f #unsigned)

/*
BNArr = #()
parentIdArray = #()
fseek f tableOffset #seek_set
for x=1 to boneCount do (
-- 	fseek f (tableOffset + 0x64 * (x-1)) #seek_set
	fseek f (tableOffset + 0x64 * (boneIdArray[x])) #seek_set
	
	
	ReadFixedByteString f 0x10 1 0
	boneNameHash = readlong f	--crc32
	unk2 = readlong f	--may be 4 bytes
	parentId = readlong f - skelIndex
	boneNameOffset = readlong f
	
	if x==1 do parentId = -1
	append parentIdArray parentId
	
	format "% %\n" (bit.intashex(x-1 as integer)) (bit.intashex(parentId))
	
	fseek f 0x24 #seek_cur	--matrix
	m11 = readfloat f ; m21 = readfloat f ; m31 = readfloat f ; m41 = readfloat f
	m12 = readfloat f ; m22 = readfloat f ; m32 = readfloat f ; m42 = readfloat f
	m13 = readfloat f ; m23 = readfloat f ; m33 = readfloat f ; m43 = readfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	
	boneName = getName f (boneNameOffset + boneNameBufferOffset)
	if boneName == undefined do boneName = x as string	--end of files are sometimes corrupted, breaking the last string since it's at the end of the file
	boneName = ((bit.intashex(x-1 as integer)) as string) + "_" + boneName
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newbone.showlinks = true
	newBone.transform = tfm
	newBone.name = boneName
	newBone.pos *= fscale

	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	append BNArr newBone
)
printhex BNArr.count

for x=1 to boneCount do (
	if parentIdArray[x] != -1 do (
		BNArr[x].parent = BNArr[parentIdArray[x]+1]
	)
)

for b in BNArr where b.parent == undefined do b.transform *= (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])
*/

BNArr = #()
parentIdArray = #()
fseek f tableOffset #seek_set
for x=1 to tableCount do (
	fseek f (tableOffset + 0x64 * (x-1)) #seek_set
	
	ReadFixedByteString f 0x10 1 0
	boneNameHash = readlong f	--crc32
	unk2 = readlong f	--may be 4 bytes
	parentId = readlong f
	boneNameOffset = readlong f
	
-- 	if x==1 do parentId = -1
	append parentIdArray parentId
	
	format "% %\n" (bit.intashex(x-1 as integer)) (bit.intashex(parentId))
	
	fseek f 0x24 #seek_cur	--matrix
	m11 = readfloat f ; m21 = readfloat f ; m31 = readfloat f ; m41 = readfloat f
	m12 = readfloat f ; m22 = readfloat f ; m32 = readfloat f ; m42 = readfloat f
	m13 = readfloat f ; m23 = readfloat f ; m33 = readfloat f ; m43 = readfloat f
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [m41,m42,m43]
	
	boneName = getName f (boneNameOffset + boneNameBufferOffset)
	if boneName == undefined do boneName = x as string	--end of files are sometimes corrupted, breaking the last string since it's at the end of the file
	boneName = ((bit.intashex(x-1 as integer)) as string) + "_" + boneName
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newbone.showlinks = true
	newBone.transform = tfm
	newBone.name = boneName
	newBone.pos *= fscale

	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	append BNArr newBone
)
printhex BNArr.count

for x=1 to tableCount do (
	if parentIdArray[x] != -1 do (
		BNArr[x].parent = BNArr[parentIdArray[x]+1]
	)
)

for b in BNArr where b.parent == undefined do b.transform *= (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])



Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f