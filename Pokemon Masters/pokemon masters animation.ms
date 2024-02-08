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
	Print ("Here @ 0x"+((bit.intAsHex(ftell bstream))as string))
)
fn getBoundBox bstream fscale = (
	currBBMax = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currBBMin = ([(readfloat bstream),(readfloat bstream),(readfloat bstream)]*fscale)
	currA = currBBMax - currBBMin
	
	return currA
)
fn getString bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	strLength = readlong bstream
	str = ReadFixedString bstream strLength
	fseek bstream backJump #seek_set
	return str
)
fn getVal bstream offset = (
	backJump = ftell bstream
	fseek bstream offset #seek_set
	newVal = readlong f
	fseek bstream backJump #seek_set
	return newVal
)
fname = GetOpenFileName caption:"Pokemon Masters Animation" types:" (*.lmd)|*.lmd" historyCategory:""
-- fname=@"C:\Users\Owner\Desktop\New folder (2)\Motions\ch0000_00_red_110_start_battle.lmd"
If (fname!=undefined) and ((DoesFileExist fname)==true) then (
f = fopen fname "rb"   --open file in read only format
-- actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
FileExtension = getFileNameType  fname
FileName = getFileNameFile fname
clearlistener()
Global fscale=100
Print "===================================="
print (FileName + FileExtension) as string
Print "===================================="
--)

fseek f 0x64 #seek_set
animLength = readfloat f
animName = (getString f (readlong f + (ftell f - 4)))
frameRate = readfloat f
animOffset = (readlong f + (ftell f - 4))	--4

fseek f animOffset #seek_set
boneCount = readlong f
boneOffset = for x=1 to boneCount collect (readlong f + (ftell f - 4))
	
sliderTime = 0
allBones = for o in geometry where classof o == bonegeometry collect o
for o in geometry where classOf o == boneGeometry do o.assumeskinpose()
deleteKeys objects #allKeys
stopanimation()

print animLength

numFrames = 0
for x=1 to boneCount do (
	fseek f boneOffset[x] #seek_set
	
	ukw = readlong f	--hash? / e0 4f 55 40
	boneName = (getString f (readlong f + (ftell f - 4)))
	ukw2 = readlong f	--hash?
	ukw3 = readlong f	--1
	ukw4 = readlong f	--7
	ukw5 = readlong f
	fseek f ukw5 #seek_cur	--lets hope this isn't a coincidence
	
	ReadFixedByteString f 0x10 1 0
	ukwOffset = (readlong f + (ftell f - 4))	--faceAnim? / visAnim?
	sclDataOffset = (readlong f + (ftell f - 4))	--scale?
	rotDataOffset = (readlong f + (ftell f - 4))
	posDataOffset = (readlong f + (ftell f - 4))
	
	--Unknown--
	fseek f ukwOffset #seek_set
	ukw = readlong f
	ukwSubOffset = (readlong f + (ftell f - 4))
	ukwSubOffset2 = (readlong f + (ftell f - 4))
	
	fseek f ukwSubOffset2 #seek_set
	ukwSubDataTimeCount = readlong f
	ukwSubDataTime = for y=1 to ukwSubDataTimeCount collect (readfloat f)
	
	fseek f ukwSubOffset2 #seek_set
	ukwSubDataCount  = readlong f
	ukwSubArr = for y=1 to ukwSubDataCount collect (readlong f)
	
	--Scale--
	fseek f sclDataOffset #seek_set
	ukw = readlong f
	sclTimeOffset = (readlong f + (ftell f - 4))
	sclOffset = (readlong f + (ftell f - 4))
	
	fseek f sclTimeOffset #seek_set
	sclTimeCount = readlong f
	sclTime = for y=1 to sclTimeCount collect (readfloat f * (frameRate * animLength))
	
	fseek f sclOffset #seek_set
	sclCount = readlong f
	sclArr = for y=1 to sclTimeCount collect (readfloat f)
	
	--Rotations--
	fseek f rotDataOffset #seek_set
	ukw = readlong f
	rotTimeOffset = (readlong f + (ftell f - 4))
	rotOffset = (readlong f + (ftell f - 4))
	
	fseek f rotTimeOffset #seek_set
	rotTimeCount = readlong f
	rotTime = for y=1 to rotTimeCount collect (readfloat f * (frameRate * animLength))
	
	rotArr=#()
	fseek f rotOffset #seek_set
	rotCount = readlong f
	for y=1 to (rotCount / 4) do (
		qx = readfloat f
		qy = readfloat f
		qz = readfloat f
		qw = readfloat f
		
 		append rotArr (quat qx qy qz qw)
	)
	
	--Translations --
	fseek f posDataOffset #seek_set
	ReadFixedByteString f 0x10 1 0
	ukw = readlong f
	posTimeOffset = (readlong f + (ftell f - 4))
	posOffset = (readlong f + (ftell f - 4))
	
	fseek f posTimeOffset #seek_set
	posTimeCount = readlong f
	posTime = for y=1 to posTimeCount collect (readfloat f * (frameRate * animLength))
	
	posArr=#()
	fseek f posOffset #seek_set
	posCount = readlong f
	for y=1 to (posCount / 3) do (append posArr (point3 (readFloat f) (readFloat f) (readFloat f)))
	
	if (frameRate * animLength) > numFrames do numFrames = (frameRate * animLength)
	with animate on(
-- 		for y=1 to sclTimeCount do (
-- 			b = getnodebyname boneName
-- 			t = sclTime[y]
-- 			s = sclArr[y]
-- 			
-- 			if (b!=undefined) then (
-- 				at time t
-- 					b.Controller.Scale = [1,1,1] * s
-- 			)
-- 			
-- 		)
		for y=1 to rotTimeCount do (
			b = getnodebyname boneName
			t = rotTime[y]
			q = rotArr[y]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Rotation = inverse q
			)
			
		)
		for y=1 to posTimeCount do (
			b = getnodebyname boneName
			t = posTime[y]
			p = posArr[y]
			
			if (b!=undefined) then (
				at time t
					b.Controller.Position = p * fscale
			)
		)
	)
)
animationRange = interval 0 numFrames


Print ("Last Read @ 0x"+((bit.intAsHex(ftell f))as string))
)
gc()
fclose f