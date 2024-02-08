fname = GetOpenFileName caption:"Freedom Wars Skeleton" types:"(*.nsk)|*.nsk"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (--)
g = fopen fname "rb"   --open file in read only format
clearlistener()
fscale=50

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

Print "Skeleton Loaded"
BoneNameOffset=#()
BoneNameLength=#()
BoneName=#()
BoneParentID=#()

FileType = ReadFixedString g 4
fseek g 0x20 #seek_set
BoneCount = ReadShort g
print BoneCount
fseek g 0x6 #seek_cur -- looks the ame for all file but only checked 3
NameOffsetTable = Readlong g + 0x20
ukwOffset = Readlong g + 0x20
BoneStart = Readlong g + 0x20
ukwOffset2 = Readlong g + 0x20
ukwOffset3 = Readlong g + 0x20
fseek g 0x8 #seek_cur
For x=1 to BoneCount do (
	BoneParentID[x] = ReadShort g + 1
	fseek g 0x6 #seek_cur -- Stuff probs important but too lazy
)

fseek g NameOffsetTable #seek_set
For x=1 to BoneCount do (
	BoneNameOffset[x] = Readlong g + 0x20
)

For x=1 to BoneCount do (
	fseek g BoneNameOffset[x] #seek_set
	BoneName[x] = readstring g
-- 	Print BoneName[x] as string
)
	
fseek g bonestart #seek_set
	
BNArr = #()
for x=1 to BoneCount do (
	
	m11 = Readfloat g; m12 = Readfloat g; m13 = Readfloat g; m14 = Readfloat g
	m21 = Readfloat g; m22 = Readfloat g; m23 = Readfloat g; m24 = Readfloat g
	m31 = Readfloat g; m32 = Readfloat g; m33 = Readfloat g; m34 = Readfloat g
	m41 = Readfloat g; m42 = Readfloat g; m43 = Readfloat g; m44 = Readfloat g
	tfm = matrix3 [m11,m21,m31,m41] [m12,m22,m32,m42] [m13,m23,m33,m43] [m14,m24,m34,m44]	
	
	newBone = bonesys.createbone	\
	tfm.row4	\
	(tfm.row4 + 0.01 * (normalize tfm.row1)) \
	(normalize tfm.row3)
	newBone.width = 0.1
	newBone.height = 0.1
	newBone.wirecolor = white
	newbone.showlinks = false
	newBone.transform = inverse tfm
	newBone.name = BoneName[x]
	
	
	pos = [m41,m42,m43]
	pos = pos * tfm
	pos *= -1
	
	newBone.pos.x += ((fscale)*pos.x)
	newBone.pos.y += ((fscale)*pos.y)
	newBone.pos.z += ((fscale)*pos.z)	
	
	newBone.setBoneEnable false 0
	newBone.pos.controller = TCB_position ()
	newBone.rotation.controller = TCB_rotation ()
		
	if (BoneParentID[x] != 0) then (
	newBone.parent = BNArr[BoneParentID[x]]
   )
	
	append BNArr newBone
)
rootRT = dummy name:"Main_Root" boxsize:[.1,.1,.1]
for b in BNArr where b.parent==undefined do b.parent = rootRT
rootRT.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
for b in BNArr do b.setskinpose()

Print ("Last Read @ 0x"+((bit.intAsHex(ftell g))as string))
)

gc()
fclose g