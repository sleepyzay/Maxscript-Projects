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

struct weight_data (
	boneids,weights
)

fname = GetOpenFileName caption:"" types:" (*.pmt)|*.pmt" historyCategory:""
-- fname =@"D:\models\ripped\super dbz\ply\p01\p01act.pmt"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=1
-- delete $*
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

struct _animFile (
	_ = ReadFixedByteString f 0x20 1 0,
	name = ReadFixedString f 0x10,
	offset = readlong f,
	length = readlong f,
	null = readlong f,
	unk = readshort f,					-- 0x06
	unk2 = readshort f					-- 0x01
)

struct _unkTable (
	_ = ReadFixedByteString f 0x0c 1 0,
	null = readlong f,
	boneIdOffset = readlong f,			-- totalBoneIdList?
	unkOffset2 = readlong f
)

RFSML3 = ReadFixedString f 6
animCount = readshort f
dataLength = readlong f
dataLength2 = readlong f			-- length of data right up to mot files

animData = for x=1 to animCount collect (animFile = _animFile())

animCount2 = readshort f 			-- same as animCount
boneCount = readshort f
boneNamesOffset = readlong f
unkOffset2 = readlong f
unkOffset3 = readlong f
	
format "animCount:%	boneCount:%\n" (bit.intashex(animCount)) (bit.intashex(boneCount))

fseek f boneNamesOffset #seek_set
boneNameArray = for x=1 to boneCount collect (ReadFixedString f 0x10)

fseek f unkOffset2 #seek_set
unkTableArray = for x=1 to animCount collect (unkTable = _unkTable())

fseek f unkOffset3 #seek_set
unkArray = for x=1 to boneCount collect (readbyte f)

-- for x=1 to boneCount do (
-- 	format "% %\n" (bit.intashex(unkArray[x])) boneNameArray[x]
-- )
format "\n"
	
animSelect = 0x01
for x=animSelect to animSelect do (	--animCount
	anim = animData[x]
	unkAnimTable = unkTableArray[x]
	
	print anim.name
	
	fseek f anim.offset #seek_set
	mot2 = ReadFixedString f 4
	mot2Length = readlong f
	frameRate = readfloat f
	
	
-- 	ReadFixedByteString f 0x34 1 1
-- 	
-- 	ReadFixedByteString f 0x04 0 1
-- 	ReadFixedByteString f 0x0c 0 1
-- 	ReadFixedByteString f 0x0c 0 1
-- 	ReadFixedByteString f 0x0c 0 1
-- 	ReadFixedByteString f 0x0c 0 1
-- 	fseek f -0x34 #seek_cur
-- 	format "\n"
	

	numFrames = readshort f
	unkCount10 = readshort f
	
	unkCount1 = readshort f
	unkCount2 = readshort f						-- totalUsedBones? / same as posBoneCount + rotBoneCount
	unkOffset1 = readlong f + anim.offset		-- data count is unkCount10
	unkOffset2 = readlong f + anim.offset		-- data count is unkCount1 / first n entries is unkCount2 / rest count not defined and implied by difference between unkCount1 and unkCount2?
	
	posBoneCount = readshort f
	posFrameCount = readshort f
	posDataOffset = readlong f + anim.offset
	posTimeOffset = readlong f + anim.offset
	
	rotBoneCount = readshort f
	rotframeCount = readshort f
	rotDataOffset = readlong f + anim.offset
	rotTimeOffset = readlong f + anim.offset	
	
	unkCount7 = readshort f						-- null?
	unkCount8 = readshort f						-- null?
	unkOffset7 = readlong f + anim.offset
	unkOffset8 = readlong f + anim.offset		-- end of file?
	
	fseek f unkAnimTable.boneIdOffset #seek_set
	posBoneIds = for y=1 to posBoneCount collect (readshort f #unsigned)
	rotBoneIds = for y=1 to rotBoneCount collect (readshort f #unsigned)
	
	fseek f unkAnimTable.unkOffset2 #seek_set
	posBoneIds2 = for y=1 to posBoneCount collect (readshort f #unsigned)
	rotBoneIds2 = for y=1 to rotBoneCount collect (readshort f #unsigned)
	
-- 	for y = 1 to posBoneCount do (
-- 		format "% % %\n" \
-- 			(formattedPrint posBoneIds[y] format:"04X") \
-- 			(formattedPrint posBoneIds2[y] format:"04X") \
-- 			boneNameArray[posBoneIds[y] + 1]
-- 	)

-- 	format "\n"

-- 	for y = 1 to rotBoneCount do (
-- 		format "% % %\n" \
-- 			(formattedPrint rotBoneIds[y] format:"04X") \
-- 			(formattedPrint rotBoneIds2[y] format:"04X") \
-- 			boneNameArray[rotBoneIds[y] + 1]
-- 	)
	
-- 	format "% %\n"(bit.intashex(posBoneCount)) (bit.intashex(rotBoneCount))
-- 	fseek f unkAnimTable.unkOffset2 #seek_set
-- 	ReadFixedByteString f 0x52 0 1
-- 	format "\n"
	
	fseek f unkOffset1 #seek_set
	for y=1 to unkCount10 do (
-- 		ReadFixedByteString f 0x08 1 1
		unk1 = readshort f								-- 0-3
		unk2 = readshort f								-- 
		unk3 = readshort f
		unk4 = readshort f								-- always 1 less than unkCount1
	)
	
	fseek f unkOffset2 #seek_set
	for y=1 to unkCount1 do (
-- 		ReadFixedByteString f 0x10 1 1
		unk1 = readfloat f
		unk2 = readfloat f
		unk3 = readfloat f
		unk4 = readfloat f								-- always 1 in first unkCount2 entries
		
-- 		format "% % % %\n" \
-- 		(formattedPrint unk1 format:"10f") \
-- 		(formattedPrint unk2 format:"10f") \
-- 		(formattedPrint unk3 format:"10f") \
-- 		(formattedPrint unk4 format:"10f")
-- 		
-- 		format "% % % %\n" unk1 unk2 unk3 unk4
	)
	
	fseek f posDataOffset #seek_set
	posData=#()
	for y=1 to posBoneCount do (
		posArray = #()
		for z=1 to posFrameCount do (
			px = readfloat f
			py = readfloat f
			pz = readfloat f
			pw = readfloat f
			
			append posArray [px,py,pz]
		)
		append posData posArray
	)
	fseek f posTimeOffset #seek_set
	posTime = for y=1 to posFrameCount collect (t = readfloat f)
	
	fseek f rotDataOffset #seek_set
	rotData=#()
	for y=1 to rotBoneCount do (
		rotData[y] = for z=1 to rotFrameCount collect (q = quat (readfloat f) (readfloat f) (readfloat f) (readfloat f))
	)
	fseek f rotTimeOffset #seek_set
	rotTime = for y=1 to rotFrameCount collect (t = readfloat f)
	
	with animate on (
		sliderTime = 0
		animationRange = interval 0 numFrames
		for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
		deleteKeys objects #allKeys
		stopanimation()
		
		for y=1 to posData.count do (			-- per bone
			for z=1 to posData[y].count do (	-- per frame
				b = getnodebyname boneNameArray[posBoneIds[y] + 1]				
				t = ceil(posTime[z] * framerate)
				p = posData[y][z]
				
				if (b!=undefined) then (
					at time t
						b.Controller.Position = p * fscale
				)
			)
		)
		
		for y=1 to rotData.count do (			-- per bone
			for z=1 to rotData[y].count do (	-- per frame
				b = getnodebyname boneNameArray[rotBoneIds[y] + 1]
				t = ceil(rotTime[z] * framerate)
				q = rotData[y][z]
				
				if (b!=undefined) then (
					
					at time t
						b.Controller.Rotation = inverse q
				)
			)
		)
	)
	
	
-- 	format "\n"
)


Print ("Last Read @ "+((bit.intAsHex(ftell f as integer))as string))
)
gc()
fclose f