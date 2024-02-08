--sleepyzay--

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
	print (bit.intashex(num))
)
fn printHere bstream = (
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn FindNumofOcurrences narray num = (
	j=0
	for i in narray do (
		if i == num do j+=1
	)
	return j
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
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn getName bstream offset = (
	name = ReadFixedString f (offset-(ftell bstream))
	return Name
)
fn skipNull bstream = (
	do (
		null = readbyte bstream
		if null != 0 do fseek f -1 #seek_cur
	)
	while (null == 0)
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

fname = GetOpenFileName caption:"" types:" (*.)|*.anim" historyCategory:""
-- fname=@"C:\Users\Xavier\Documents\stuff\projects\models\total warhammer 2\humanoid07b.anim"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
FileFolder = getFileNamePath fname

gname = FileFolder + FileName + ".bone_inv_trans_mats"
g = fopen gname "rb"   --open file in read only format

clearlistener()
Global fscale=75
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

ukw = readlong f	--always 7
ukw2 = readlong f	--always 1
null = readshort f
ukw3 = readshort f
nameLength = readshort f
skelName = ReadFixedString f nameLength
null = readlong f
ukw4 = readfloat f
boneCount = readlong f

boneName=#()
parentID=#()
for x=1 to boneCount do (
	nameLength = readshort f
	boneName[x] = ReadFixedString f nameLength
	parentID[x] = readlong f + 1
)

boneIDArr=#()
for x=1 to 2 do boneIDArr[x] = for y=1 to boneCount collect readlong f + 1
	
null = readlonglong f
boneCount2 = readlong f	--this and next are same as first boneCount
boneCount3 = readlong f
ukw = readlong f

bonePos=#()
for x=1 to boneCount do (
	px = readfloat f
	py = readfloat f
	pz = readfloat f
	
	bonePos[x] = ([px,py,pz]*fscale)
)

boneRot=#()
for x=1 to boneCount do (
	rx = readshort f
	ry = readshort f
	rz = readshort f
	rw = readshort f
	
	boneRot[x] = (quat rx ry rz rw) as matrix3
)


BNArr=#()
for x=1 to boneCount do (

	tfm = inverse boneRot[x]
	tfm.row4 = bonePos[x]
	
	if (parentID[x] != 0) then(
		tfm *= BNArr[(parentID[x])].objecttransform	
	)

-- 	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width  = 0.01
	newBone.height = 0.01
	newBone.transform = tfm
	newBone.setBoneEnable false 0
	newBone.wirecolor = orange
	newbone.name = (boneName[x])
-- 	newbone.name = boneName[x]
	newbone.showlinks = true
	newBone.pos.controller      = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()

	if (parentID[x] != 0) then(
		
		newBone.parent = BNArr[(parentID[x])]
	)
-- 	
	append BNArr newBone
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [-1,0,0] [0,0,1] [0,-1,0] [0,0,0])
for b in BNArr where b.children.count == 0 do b.wirecolor = green
for b in BNArr do b.setskinpose()
	

Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f
fclose g