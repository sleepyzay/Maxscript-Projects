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
fn printHex num = (
	print (bit.intashex(num as integer))
)
fn printHere bstream = (
	Print ("Here @ "+((bit.intAsHex(ftell bstream as integer))as string))
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
fn signVal x size= (
	if (bit.get x size) do (
		bitMask = 0
		for i=1 to size do bitMask = bit.set bitMask i true
		
		x = bit.xor x bitMask
		x += 1	--because of 2's complement
		x *= -1
	)
	return x
)
fn readbits pos range num = (
	local i = 0, result = 0, c = 1
	local val = num
	for i = pos to ((pos - 1) + range) do (
		result = bit.set result c (bit.get val i);c+=1
	)
	result
)
fn get32bitNormal format divisor val = (
	result = [0,0,0]
	pos = 1
	for x=1 to 3 do (
		result[x] = ((readBits pos format[x] val) / divisor) * 2 - 1
		pos+=format[x]
	)
	result 
)
fn skelPresent = (
	allBones = for o in geometry where classOf o == boneGeometry collect o
	if allBones.count > 0 then (
		return true
	)
	else (
		return false
	)
)

-- fn getBoundBox bstream fscale = (
-- 	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
-- 	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
-- 	currA = currBBMax - currBBMin
-- 	
-- 	return currA
-- )
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

-- fname = GetOpenFileName caption:"" types:" (*.)|*.hkx" historyCategory:""
-- fname=@"D:\models\ripped\project spark\assets\conker_a\clothing\feet\conker_a_feet\conker_a_feet.hkx"
-- fname=@"D:\models\ripped\project spark\assets\conker_a\char_rig_conker_a.hkx"
fname=@"D:\models\ripped\project spark\assets\conker_a\clothing\chest\conker_a_chest\conker_a_chest.hkx"
-- fname = @"D:\models\ripped\project spark\assets\conker_a\heads\conker_a_head\conker_a_head.hkx"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=25
delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)
struct _boundBox (
	boxMin = [(readfloat f),(readfloat f),(readfloat f)],
	boxMax = [(readfloat f),(readfloat f),(readfloat f)]
)

struct weight_data (
	boneids,weights
)

struct subHeader (name = (reverseString (ReadFixedString f 4)), subDataType = (readbyte f))		--0 = data, 1 = int / count?, 3 = 32bit val / count?

struct _COOK	(ASNM,PHYS,ANIM,MDAT,MAPR,HIDE)
	struct _ASNM	(NMSZ,NMDT)
		struct _NMSZ	(header = subHeader(), stringLength = (readlong f))
		struct _NMDT	(header = subHeader(), stringLength = (readlong f), nameData = (ReadFixedString f stringLength))
	struct _PHYS	(PSTP,PSZE,HKPD,PSLY,PHUL,PSHR)
		struct _PSTP		(header = subHeader(), ukw = (readlong f))
		struct _PSZE	(header = subHeader(), ukwDataLength = (readlong f))
		struct _HKPD	(header = subHeader(), ukwDataLength = (readlong f), ukwDataOffset = (ftell f), ukwData = (fseek f ukwDataLength #seek_cur))
		struct _PSLY		(header = subHeader(), ukw2 = (readlong f))
		struct _PHUL		(PHSZ,PHSH)
			struct _PHSZ	(header = subHeader(), ukwDataLength = (readlong f))
			struct _PHSH	(header = subHeader(), ukwDataLength = (readlong f), ukwDataOffset = (ftell f), ukwData = (fseek f ukwDataLength #seek_cur))
		struct _PSHR	(PSSZ,PSSH)
			struct _PSSZ	(header = subHeader(), ukwDataLength = (readlong f))
			struct _PSSH	(header = subHeader(), ukwDataLength = (readlong f), ukwDataOffset = (ftell f), ukwData = (fseek f ukwDataLength #seek_cur))
	struct _ANIM	(ACSZ,ACOH,ATCH)
		struct _ACSZ	(header = subHeader(), hkxDataLength = (readlong f))
		struct _ACOH	(header = subHeader(), hkxDataLength = (readlong f), hkxDataOffset = (ftell f), hkxData = (fseek f hkxDataLength #seek_cur))
		struct _ATCH	(ATSZ,ATDT)
			struct _ATSZ	(header = subHeader(), attatchCount = (readlong f))
			struct _ATDT	(header = subHeader(), attatchTableLength = (readlong f), attatchTableOffset = (ftell f), attatchTable = (fseek f attatchTableLength #seek_cur))
	struct _MDAT	(HEAD,MESH,GEOM,VERT,INDE,SK2M)
		struct _HEAD	(header = subHeader(), dataLength = (readlong f), dataOffset = (ftell f), matCount = (readlong f), meshCount = (readlong f), vertBufferLength = (readlong f), faceBufferLength = (readlong f), boneCount = (readlong f), boundBox = _boundBox())
		struct _MESH	(header = subHeader(), ukwDataLength = (readlong f), ukwDataOffset = (ftell f), ukwData = (fseek f ukwDataLength #seek_cur))
		struct _GEOM	(header = subHeader(), geomDataLength = (readlong f), geomDataOffset = (ftell f), geomData = (fseek f geomDataLength #seek_cur))
			struct geomData (null = readlong f, vertCount = readlong f, vertStride = readlong f, faceCount = readlong f, primType = readlong f)
		struct _VERT	(header = subHeader(), vertBufferLength = (readlong f), vertBufferOffset = (ftell f), vertBuffer = (fseek f vertBufferLength #seek_cur))
		struct _INDE	(header = subHeader(), faceBufferLength = (readlong f), faceBufferOffset = (ftell f), faceBuffer = (fseek f faceBufferLength #seek_cur))
		struct _SK2M	(header = subHeader(), skelBufferLength = (readlong f), skelBufferOffset = (ftell f), skelBuffer = (fseek f skelBufferLength #seek_cur))
	struct _MAPR	(MPSZ,MPDT,MPKI,MPRI)
		struct _MPSZ	(header = subHeader(), hkxDataLength = (readlong f))
		struct _MPDT	(header = subHeader(), hkxDataLength = readlong f, hkxDataOffset = (ftell f), hkxData = (fseek f hkxDataLength #seek_cur))
		struct _MPKI		(header = subHeader(), ukw2 = (readlong f))
		struct _MPRI		(header = subHeader(), ukw2 = (readlong f))
	struct _HIDE	(BBOX)
		struct _BBOX (BMIN,BMAX,NUMF,FLTS)
			struct _BMIN(header = subHeader(), bbMinLength = readlong f, bbMin = [readfloat f, readfloat f , readfloat f] * fscale)
			struct _BMAX(header = subHeader(), bbMaxLength = readlong f, bbMax = [readfloat f, readfloat f , readfloat f] * fscale)
			struct _NUMF(header = subHeader(), floatCount = readlong f)
			struct _FLTS(header = subHeader(), floatDataLength = readlong f, floatDataOffset = (ftell f), floatData = (fseek f floatDataLength #seek_cur))
	
fn readChunkInit f = (
	chunkInit = readbyte f #unsigned
	AlignOffset f (ftell f) 4
	return chunkInit
)

fn readModel f parent val = (
	chunkOffset = ftell f
	chunkInit = readChunkInit f								--0x0c
	chunkTag = readlong f #unsigned						--0x00B0FFB0
	chunkName = reverseString (ReadFixedString f 4)
	chunkSize = readlong f #unsigned
	chunkEnd = ((ftell f) - 0x0c) + chunkSize + 1	-- + 1 because of chunkFooter
	
	if val == 1 do (
		format "%	%	%\n" chunkName (bit.intashex(chunkOffset as integer)) (bit.intashex(chunkSize as integer))
	)
	
	case chunkName of (
		"COOK":(
			COOK = _COOK()
			while (ftell f) < chunkEnd - 1 do readModel f COOK 1
			return COOK
		)
		"ASNM":(
			parent.ASNM = _ASNM()
			parent.ASNM.NMSZ = _NMSZ()
			parent.ASNM.NMDT = _NMDT()
		)
		"PHYS":(
			parent.PHYS = _PHYS()
			parent.PHYS.PSTP = _PSTP()
			parent.PHYS.PSZE = _PSZE()
			parent.PHYS.HKPD = _HKPD()
			parent.PHYS.PSLY = _PSLY()
			
			readModel f parent.PHYS 0	--PHUL
			readModel f parent.PHYS 0	--PSHR
		)
		"PHUL":(
			parent.PHUL = _PHUL()
			parent.PHUL.PHSZ = _PHSZ()
			parent.PHUL.PHSH = _PHSH()
		)
		"PSHR":(
			parent.PSHR = _PSHR()
			parent.PSHR.PSSZ = _PSSZ()
			parent.PSHR.PSSH = _PSSH()
		)
		"ANIM":(
			parent.ANIM = _ANIM()
			parent.ANIM.ACSZ = _ACSZ()
			parent.ANIM.ACOH = _ACOH()
			
			readModel f parent.ANIM 0	--ATCH
		)
		"ATCH":(
			parent.ATCH = _ATCH()
			parent.ATCH.ATSZ = _ATSZ()
			parent.ATCH.ATDT = _ATDT()
		)
		"MDAT":(
			parent.MDAT = _MDAT()
			parent.MDAT.HEAD =	_HEAD()
			parent.MDAT.MESH =	_MESH()
 			parent.MDAT.GEOM =	_GEOM()
			parent.MDAT.VERT =	_VERT()
			parent.MDAT.INDE =	_INDE()
			parent.MDAT.SK2M =	_SK2M()
		)
		"MAPR":(
			parent.MAPR = _MAPR()
			parent.MAPR.MPSZ =	_MPSZ()
			parent.MAPR.MPDT =	_MPDT()
			parent.MAPR.MPKI =	_MPKI()
			parent.MAPR.MPRI =	_MPRI()
		)
		"HIDE":(
			parent.HIDE = _HIDE()
			while (ftell f) < chunkEnd - 1 do readModel f parent.HIDE 0
		)
		"BBOX":(
			BBOX = _BBOX()
			BBOX.BMIN = _BMIN()
			BBOX.BMAX = _BMAX()
			BBOX.NUMF = _NUMF()
			BBOX.FLTS = _FLTS()
			
			if parent.BBOX == undefined do parent.BBOX = #()
			append parent.BBOX BBOX
		)
 		
		default:(
			format "unknown chunk: % @ %\n" chunkName (bit.intashex (ftell f as integer))
			fseek f (chunkEnd - 1) #seek_set
		)
	)
	endByte = readbyte f
)

magic = readlong f
fileSize = readlong f
ukw = readlong f
COOK = readModel f null 0

--hard encoded bc I can't find them in file
parentIDArr = #(-1,0,1,2,3,4,5,6,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,23,23,23,23,27,7,29,7,31,7,7,7,7,7,7,7,39,7,41,7,7,7,7,7,7,7,7,7,7,7,7,5,55,56,57,58,59,59,61,62,59,64,65,59,67,68,59,70,71,57,5,74,75,76,77,78,78,80,81,78,83,84,78,86,87,78,89,90,76,5,1,94,95,96,1,98,99,100,1,102,103,104,105,106,107,108,109)
boneNameArr = #("char_rig_conker:master","char_rig_conker:Root_M","char_rig_conker:Back_0_M","char_rig_conker:Back_1_M","char_rig_conker:BackA_M","char_rig_conker:Chest_M","char_rig_conker:Neck_M","char_rig_conker:Head_M","char_rig_conker:Brow_Inner_L","char_rig_conker:Brow_Inner_R","char_rig_conker:Brow_M","char_rig_conker:Brow_Outer_L","char_rig_conker:Brow_Outer_R","char_rig_conker:Cheek_L","char_rig_conker:Cheek_R","char_rig_conker:Ear_Back_L","char_rig_conker:Ear_Back_R","char_rig_conker:Ear_Front_L","char_rig_conker:Ear_Front_R","char_rig_conker:Ear_Top_L","char_rig_conker:Ear_Top_R","char_rig_conker:Eye_L","char_rig_conker:Eye_R","char_rig_conker:Jaw_M","char_rig_conker:Mouth_Bottom_Mid_L","char_rig_conker:Mouth_Bottom_Mid_R","char_rig_conker:Mouth_Lower_M","char_rig_conker:Tongue1_M","char_rig_conker:Tongue2_M","char_rig_conker:Lid_Lower1_L","char_rig_conker:Lid_Lower2_L","char_rig_conker:Lid_Lower1_R","char_rig_conker:Lid_Lower2_R","char_rig_conker:Lid_Lower_Inner_L","char_rig_conker:Lid_Lower_Inner_R","char_rig_conker:Lid_Lower_Middle_L","char_rig_conker:Lid_Lower_Middle_R","char_rig_conker:Lid_Lower_Outer_L","char_rig_conker:Lid_Lower_Outer_R","char_rig_conker:Lid_Upper1_L","char_rig_conker:Lid_Upper2_L","char_rig_conker:Lid_Upper1_R","char_rig_conker:Lid_Upper2_R","char_rig_conker:Lid_Upper_Inner_L","char_rig_conker:Lid_Upper_Inner_R","char_rig_conker:Lid_Upper_Middle_L","char_rig_conker:Lid_Upper_Middle_R","char_rig_conker:Lid_Upper_Outer_L","char_rig_conker:Lid_Upper_Outer_R","char_rig_conker:Mouth_L","char_rig_conker:Mouth_R","char_rig_conker:Mouth_Top_M","char_rig_conker:Mouth_Top_Mid_L","char_rig_conker:Mouth_Top_Mid_R","char_rig_conker:Nose_M","char_rig_conker:Scapula_L","char_rig_conker:Shoulder_L","char_rig_conker:Elbow_L","char_rig_conker:ElbowPart1_L","char_rig_conker:Wrist_L","char_rig_conker:Hand_PROP_L","char_rig_conker:IndexFinger1_L","char_rig_conker:IndexFinger2_L","char_rig_conker:IndexFinger3_L","char_rig_conker:MiddleFinger1_L","char_rig_conker:MiddleFinger2_L","char_rig_conker:MiddleFinger3_L","char_rig_conker:RingFinger1_L","char_rig_conker:RingFinger2_L","char_rig_conker:RingFinger3_L","char_rig_conker:ThumbFinger1_L","char_rig_conker:ThumbFinger2_L","char_rig_conker:ThumbFinger3_L","char_rig_conker:Shield_L","char_rig_conker:Scapula_R","char_rig_conker:Shoulder_R","char_rig_conker:Elbow_R","char_rig_conker:ElbowPart1_R","char_rig_conker:Wrist_R","char_rig_conker:Hand_PROP_R","char_rig_conker:IndexFinger1_R","char_rig_conker:IndexFinger2_R","char_rig_conker:IndexFinger3_R","char_rig_conker:MiddleFinger1_R","char_rig_conker:MiddleFinger2_R","char_rig_conker:MiddleFinger3_R","char_rig_conker:RingFinger1_R","char_rig_conker:RingFinger2_R","char_rig_conker:RingFinger3_R","char_rig_conker:ThumbFinger1_R","char_rig_conker:ThumbFinger2_R","char_rig_conker:ThumbFinger3_R","char_rig_conker:Shield_R","char_rig_conker:Zipper_M","char_rig_conker:Hip_L","char_rig_conker:Knee_L","char_rig_conker:Ankle_L","char_rig_conker:MiddleToe1_L","char_rig_conker:Hip_R","char_rig_conker:Knee_R","char_rig_conker:Ankle_R","char_rig_conker:MiddleToe1_R","char_rig_conker:Tail1_M","char_rig_conker:Tail2_M","char_rig_conker:Tail3_M","char_rig_conker:Tail4_M","char_rig_conker:Tail5_M","char_rig_conker:Tail6_M","char_rig_conker:Tail7_M","char_rig_conker:Tail8_M","char_rig_conker:Tail9_M")

print parentIDArr.count
print COOK.MDAT.HEAD.boneCount
print boneNameArr.count

BNArr=#()
if skelPresent() == false then (
	fseek f COOK.MDAT.SK2M.skelBufferOffset #seek_set
	
-- 	fseek f (0x40 * 111) #seek_cur	--conker head has 3 skeletons
-- 	fseek f (0x40 * 111) #seek_cur
	
	for x=1 to 111 do (
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
		newbone.showlinks = true
		newBone.transform = tfm
		newBone.name = boneNameArr[x]
			
		pos = [m41,m42,m43]
		pos *= tfm
		newBone.pos += (fscale*-pos)
		
		newBone.setBoneEnable false 0
		newBone.pos.controller = TCB_position ()
		newBone.rotation.controller = TCB_rotation ()
		if parentIDArr[x] != -1 do (
			newBone.parent = BNArr[parentIDArr[x] + 1]
		)	
		append BNArr newBone
	)
-- 	for b in BNArr where b.parent==undefined do b.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
	for b in BNArr do b.setskinpose()

)
else (
	BNArr = for o in geometry where classof o == bonegeometry collect o
)
for b in BNArr do b.setskinpose()

attatchArr=#()
fseek f COOK.ANIM.ATCH.ATDT.attatchTableOffset #seek_set
for x=1 to COOK.ANIM.ATCH.ATSZ.attatchCount do (
	attatchName = ReadFixedString f 0x40	
	m11 = readfloat f; m12 = readfloat f; m13 = readfloat f; m14 = readfloat f
	m21 = readfloat f; m22 = readfloat f; m23 = readfloat f; m24 = readfloat f
	m31 = readfloat f; m32 = readfloat f; m33 = readfloat f; m34 = readfloat f
	m41 = readfloat f; m42 = readfloat f; m43 = readfloat f; m44 = readfloat f
	tfm = matrix3 [m11,m21,m31] [m12,m22,m32] [m13,m23,m33] [m14,m24,m34]	
	attatchBoneID = readlong f #unsigned
	fseek f 0x0c #seek_cur	--null
	
	attatchObject = dummy name:attatchName boxsize:[2.5,2.5,2.5] transform:tfm
	attatchObject.pos += [m41,m42,m43] * tfm * -fscale
	
	if attatchBoneID != -1 do (
		attatchObject.parent = BNArr[attatchBoneID + 1]
		attatchObject.transform *= attatchObject.parent.transform
	)	
	append attatchArr attatchObject
)

-- print COOK.PHYS
boundBox = COOK.MDAT.HEAD.boundBox
currBBMax = boundBox.boxMax * fscale
currBBMin = boundBox.boxMin * fscale
currA = currBBMax - currBBMin

-- bb = box()
-- print currBBMax
-- print currBBMin
-- print currA

-- bb.pos.x = (currBBMax[1] + currBBMin[1])
-- bb.pos.y = ((currA[2] / 2) + currBBMin[2])
-- bb.pos.z = currBBMin[3]

-- bb.width = abs(currA[1])
-- bb.length = abs(currA[2])
-- bb.height = abs(currA[3])

-- bb.xray = true

for bb in COOK.HIDE.BBOX do (
	print bb.BMAX
	print bb.BMIN
	
	/*
	fseek f bb.FLTS.floatDataOffset #seek_set
-- 	printHex bb.FLTS.floatDataOffset
	printHex (bb.FLTS.floatDataLength / 0x18)
	for x=1 to (bb.FLTS.floatDataLength / 0x18) do (
		ReadFixedByteString f 0x18 1 1
		
		bbMin = [readfloat f,readfloat f,readfloat f] * fscale
		bbMax = [readfloat f,readfloat f,readfloat f] * fscale
		currA = bbMax + bbMin
		
		--l w h
		--y x z
		
-- 		c = sphere()
-- 		c.pos = bbMin
-- 		c.radius = 1
-- 		
		print bbMin
		print bbMax

		d = box()
		
		d.width = abs(currA[1])
		d.length = abs(currA[2])
		d.height = abs(currA[3])
		d.pos = bbMin
		
	)
	*/
-- 	print ukwFloats
)



/*
bb = box()
currA = boundBox.boxMax - boundBox.boxMin
bb.length = abs(currA[1])
bb.width = abs(currA[2])
bb.height = abs(currA[3])
print (boundBox.boxMin * fscale)
-- bb.pos = boundBox.boxMin * fscale
-- bb.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
bb.scale *= fscale
bb.xray = true
*/


fseek f COOK.MDAT.GEOM.geomDataOffset #seek_set
COOK.MDAT.GEOM.geomData = for x=1 to COOK.MDAT.HEAD.meshCount collect (data = geomData())

vertOffset = COOK.MDAT.VERT.vertBufferOffset
faceOffset = COOK.MDAT.INDE.faceBufferOffset
for x=1 to COOK.MDAT.HEAD.meshCount do (
	Vert_Array=#()
	UV_Array=#()
	Face_Array=#()
	Normal_Array=#()
	Weight_Array=#()
	
	fseek f vertOffset #seek_set		
	for y=1 to COOK.MDAT.GEOM.geomData[x].vertCount do (
		if COOK.MDAT.GEOM.geomData[x].vertStride == 0x14 do (
			w = (weight_data boneids:#() weights:#())
			
			vx = ReadHalfFloat f
			vy = ReadHalfFloat f
			vz = ReadHalfFloat f
			vw = ReadHalfFloat f
			normals = (get32bitNormal [10,10,10] 1024.0 (readlong f #unsigned))
			binormals = (get32bitNormal [10,10,10] 1024.0 (readlong f #unsigned))
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			
			append Vert_Array ([vx,vy,vz]*fscale)
			append Normal_Array (normals)
			append UV_Array([tu,1-tv,0])
			append Weight_Array w
		)
		if COOK.MDAT.GEOM.geomData[x].vertStride == 0x1c do (
			w = (weight_data boneids:#() weights:#())
			
			vx = ReadHalfFloat f
			vy = ReadHalfFloat f
			vz = ReadHalfFloat f
			vw = ReadHalfFloat f
			normals = (get32bitNormal [10,10,10] 1024.0 (readlong f #unsigned))
			binormals = (get32bitNormal [10,10,10] 1024.0 (readlong f #unsigned))
			tu = ReadHalfFloat f
			tv = ReadHalfFloat f
			weight1 = readbyte f #unsigned
			weight2 = readbyte f #unsigned
			weight3 = readbyte f #unsigned
			weight4 = readbyte f #unsigned
			bone1 = readbyte f #unsigned
			bone2 = readbyte f #unsigned
			bone3 = readbyte f #unsigned
			bone4 = readbyte f #unsigned
			
-- 			format "%	%	%	%\n" bone1 bone2 bone3 bone4
-- 			format "%	%	%	%\n\n" weight1 weight2 weight3 weight4
			mxw = 255.0
			append w.boneids (bone1 + 1)
			append w.weights (weight1 / mxw)
			append w.boneids (bone2 + 1)
			append w.weights (weight2 / mxw)
			append w.boneids (bone3 + 1)
			append w.weights (weight3 / mxw)
			append w.boneids (bone4 + 1)
			append w.weights (weight4 / mxw)
			
			
			
			append Vert_Array ([vx,vy,vz]*fscale)
			append Normal_Array (normals)
			append UV_Array([tu,1-tv,0])
			append Weight_Array w
		)
	)
	vertOffset = ftell f
 	
	fseek f faceOffset #seek_set
	for y=1 to COOK.MDAT.GEOM.geomData[x].faceCount / 3 do(
		fa=ReadShort f #unsigned +1
		fb=ReadShort f #unsigned +1
		fc=ReadShort f #unsigned +1
		append Face_Array[fa,fb,fc]
	)
	faceOffset = ftell f
	
	msh = mesh vertices:Vert_Array faces:Face_Array
	msh.numTVerts = UV_Array.count
	msh.wirecolor = random black white
	msh.name = FileName
	buildTVFaces msh
	for j = 1 to UV_Array.count Do setTVert msh j UV_Array[j]
 	for j = 1 to Face_Array.count Do setTVFace msh j Face_Array[j]
	for j = 1 to Normal_array.count Do setNormal msh j Normal_array[j]
-- 	msh.transform = (matrix3 [1,0,0] [0,0,1] [0,1,0] [0,0,0])
	
	--hide msh
	
-- 	allBones = for o in helpers where classOf o == dummy collect o	
	allBones = for o in geometry where classOf o == bonegeometry collect o
	
-- 	-- Applying Skinning --
-- 	max modify mode
-- 	select msh
-- 	skinMod = skin ()
-- 	addModifier msh skinMod
-- 	for i = 1 to allBones.count do (
-- 		maxbone = getnodebyname allBones[i].name
-- 		if i != allBones.count then
-- 			skinOps.addBone skinMod maxbone 0
-- 		else
-- 			skinOps.addBone skinMod maxbone 1
-- 	)
-- 	
-- 	-- Applying Weights --
-- 	modPanel.setCurrentObject skinMod
-- 	for i = 1 to Weight_array.count do (
-- 		w = Weight_array[i]
-- 		bi = #() --bone index array
-- 		wv = #() --weight value array
-- 		
-- 		for j = 1 to w.boneids.count do (
-- 			boneid = w.boneids[j]
-- 			weight = w.weights[j]
-- 			append bi boneid
-- 			append wv weight
-- 		)	
-- 		
-- 		skinOps.ReplaceVertexWeights skinMod i bi wv
-- 	)
)

Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f