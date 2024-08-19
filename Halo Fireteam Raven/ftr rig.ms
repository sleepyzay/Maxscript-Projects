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

-- fname=@"D:\g7\master chief\masterchief.rig"
fname = GetOpenFileName caption:"" types:" (*.)|*.rig" historyCategory:""
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=10
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

null = readshort f
boneCount = readshort f
rigName = readstring f

BNArr=#()
fseek f 0x50 #seek_set
for x=1 to boneCount do (
	fseek f 0x3c #seek_cur
	
-- 	q1 = readfloat f
-- 	q2 = readfloat f
-- 	q3 = readfloat f
-- 	q4 = readfloat f
-- 	
-- 	print (q1 * q1 + q2 * q2 + q3 * q3 + q4 * q4)
	
	px = readfloat f
	py = readfloat f
	pz = readfloat f
	
-- 	b = sphere()
-- 	b.pos = [px,py,pz] * fscale
-- 	b.radius = 1
	
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f;
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f;
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f;
	--tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [px,py,pz]
	tfm = matrix3 [m11,m12,m13] [m21,m22,m23] [m31,m32,m33] [px,py,pz]
	
-- 	fseek f 0x24 #seek_cur
	boneNameOffset = ftell f
	boneName = readstring f
	fseek f (boneNameOffset + 0x10) #seek_set
-- 	print boneName
	fseek f 0x30 #seek_cur
	
	boneParentNameOffset = ftell f
	boneParentName = readstring f
	fseek f (boneParentNameOffset + 0x10) #seek_set
	
--	format "% %\n" boneName boneParentName
	
	fseek f 0x30 #seek_cur
	parentId = readlong f #unsigned + 1
	
	--format "% % %\n" x parentID boneName
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = tfm
	newBone.pos *= fscale
	newBone.name = boneName
	
-- 	if boneName != undefined do newBone.name = boneName
-- 	newBone.name = (x as string) + "_" + newBone.name	--hack to refer to bone by id in foreign script, after parenting original order is lost
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if (parentID != 0) then (
		newBone.parent = BNArr[parentID]
	)
	append BNArr newBone
)
-- for b in BNArr do b.setskinpose()
for b in BNArr where b.parent == undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,-1,0] [0,0,0])

Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f