fname = GetOpenFileName caption:"Xenoverse Skeleton" types:"(*.B_PSKL)|*.B_PSKL"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
f = fopen fname "rb"   --open file in read only format
clearlistener()
fscale=50
delete $*


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
fn ReadBElong fstream = (
long = readlong fstream
long = bit.swapBytes long 1 4
long = bit.swapBytes long 2 3
return long
)
fn floatSwap2 f = (
   i = bit.floatAsInt f
   h = bit.intashex i
   while h.count < 8 do h = "0" + h
   
   s = (substring h 7 2) + (substring h 5 2) + (substring h 3 2) + (substring h 1 2)
   bit.intAsFloat (bit.hexasint s)
)  
fn ReadBEfloat fstream = (
return floatSwap2(readfloat fstream)
)
fn ReadFixedString bstream fixedLen = (
   local str = ""
   for i = 1 to fixedLen do
   (
      str += bit.intAsChar (ReadByte bstream #unsigned)
   )
   str
)

BoneNameOffset=#()
BoneNameLength=#()
BoneName=#()
BoneParentID=#()
ukw1=#()
ukw2=#()
ukw3=#()
ukw4=#()

Ukw = readbeshort f
BoneCount = readbeshort f
BoneOffset = readbelong f
null = readbelong f
ParentID_Offset = readbelong f

fseek f ParentID_Offset #seek_set
For x=1 to BoneCount do (
ukw1[x] = readbyte f	
ukw2[x] = readbyte f	
ukw3[x] = readbyte f	
ukw4[x] = readbyte f	
)

fseek f BoneOffset #seek_set
BNArr = #()
for x=1 to BoneCount do (
	
	m11 = ReadBEfloat f; m12 = ReadBEfloat f; m13 = ReadBEfloat f; m14 = ReadBEfloat f
	m21 = ReadBEfloat f; m22 = ReadBEfloat f; m23 = ReadBEfloat f; m24 = ReadBEfloat f
	m31 = ReadBEfloat f; m32 = ReadBEfloat f; m33 = ReadBEfloat f; m34 = ReadBEfloat f
	m41 = ReadBEfloat f; m42 = ReadBEfloat f; m43 = ReadBEfloat f; m44 = ReadBEfloat f
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = yellow
	newbone.showlinks = true
	newBone.transform = inverse tfm
-- 	newBone.name = BoneName[x]

	
	pos = [m41,m42,m43]
	pos = pos * tfm

	newBone.pos.x += ((fscale)*pos.x)
	newBone.pos.y += (-1*(fscale)*pos.z)
	newBone.pos.z += (-1*(fscale)*pos.y)	

	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
	
	if (ukw1[x] != 0) then (
	newBone.parent = BNArr[ukw1[x]]
   )

	append BNArr newBone
)
Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)

gc()
fclose f